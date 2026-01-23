import SwiftUI

struct PostRow: View {
    @State var post: Post
    @ObservedObject var viewModel: FeedViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.3)) // Avatar placeholder
                    .frame(width: 40, height: 40)
                    .overlay(Text(post.user.username.prefix(1).uppercased()))
                
                VStack(alignment: .leading) {
                    HStack {
                        Text(post.user.fullName)
                            .font(.headline)
                        if post.user.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    }
                    Text(post.user.username)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Text(timeString(from: post.timestamp))
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // Content
            if let round = post.round {
                VStack(alignment: .leading) {
                    Text(round.courseName)
                        .font(.headline)
                    Text("\(round.location) • \(round.holes) Holes")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    HStack {
                        VStack(alignment: .center) {
                            Text("\(round.score)")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(Color(hex: "0A4A35"))
                            Text("Score")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(width: 80, height: 80)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        
                        // Placeholder for more round details or a map image
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 80)
                            .cornerRadius(12)
                    }
                }
                .padding(.vertical, 4)
            }
            
            Text(post.caption)
                .font(.body)
            
            // Actions
            HStack(spacing: 20) {
                Button(action: {
                    viewModel.likePost(postId: post.id)
                    // update for UI interaction (local state needs sync if VM updates published prop)
                    // In prod the VM would update the array and View would redraw.
                    // For now, toggle visual state locally or rely on VM.
                }) {
                    HStack {
                        Image(systemName: post.isLiked ? "heart.fill" : "heart")
                            .foregroundColor(post.isLiked ? .red : .gray)
                        Text("\(post.likes)")
                    }
                }
                .foregroundColor(.primary)
                
                Button(action: {
                    // Comment action
                }) {
                    HStack {
                        Image(systemName: "bubble.right")
                        Text("\(post.comments)")
                    }
                }
                .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
    
    func timeString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
