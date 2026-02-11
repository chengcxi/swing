import Foundation
import UIKit

@MainActor
class StorageService: ObservableObject {
    static let shared = StorageService()
    
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0
    @Published var error: Error?
    
    private let roundPhotosBucket = "round-photos"
    private let avatarsBucket = "avatars"
    
    // MARK: - Upload Round Photo
    
    func uploadRoundPhoto(_ image: UIImage, roundId: UUID) async throws -> String {
        isUploading = true
        defer { isUploading = false }
        
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw StorageError.invalidImage
        }
        
        let fileName = "\(roundId.uuidString)/\(UUID().uuidString).jpg"
        
        try await supabase.storage
            .from(roundPhotosBucket)
            .upload(
                path: fileName,
                file: imageData,
                options: FileOptions(contentType: "image/jpeg")
            )
        
        let publicURL = try supabase.storage
            .from(roundPhotosBucket)
            .getPublicURL(path: fileName)
        
        return publicURL.absoluteString
    }
    
    // MARK: - Upload Multiple Photos
    
    func uploadRoundPhotos(_ images: [UIImage], roundId: UUID) async throws -> [String] {
        var urls: [String] = []
        
        for (index, image) in images.enumerated() {
            uploadProgress = Double(index) / Double(images.count)
            let url = try await uploadRoundPhoto(image, roundId: roundId)
            urls.append(url)
        }
        
        uploadProgress = 1.0
        return urls
    }
    
    // MARK: - Upload Avatar
    
    func uploadAvatar(_ image: UIImage, userId: UUID) async throws -> String {
        isUploading = true
        defer { isUploading = false }
        
        let resizedImage = resizeImage(image, targetSize: CGSize(width: 400, height: 400))
        
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
            throw StorageError.invalidImage
        }
        
        let fileName = "\(userId.uuidString).jpg"
        
        // Remove existing avatar
        try? await supabase.storage
            .from(avatarsBucket)
            .remove(paths: [fileName])
        
        // Upload new avatar
        try await supabase.storage
            .from(avatarsBucket)
            .upload(
                path: fileName,
                file: imageData,
                options: FileOptions(contentType: "image/jpeg", upsert: true)
            )
        
        let publicURL = try supabase.storage
            .from(avatarsBucket)
            .getPublicURL(path: fileName)
        
        // Update profile
        try await AuthService.shared.updateProfile(
            ProfileUpdate(avatarUrl: publicURL.absoluteString)
        )
        
        return publicURL.absoluteString
    }
    
    // MARK: - Helpers
    
    private func resizeImage(_ image: UIImage, targetSize: CGSize) -> UIImage {
        let size = image.size
        let widthRatio = targetSize.width / size.width
        let heightRatio = targetSize.height / size.height
        let ratio = min(widthRatio, heightRatio)
        
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)
        let rect = CGRect(origin: .zero, size: newSize)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage ?? image
    }
}

enum StorageError: LocalizedError {
    case invalidImage
    case uploadFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Invalid image data."
        case .uploadFailed:
            return "Failed to upload image."
        }
    }
}
