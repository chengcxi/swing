import Foundation
import Combine

enum APIError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
}

class APIService {
    static let shared = APIService()
    private let baseURL = "https://api.swingapp.com/v1" // Placeholder URL
    
    private init() {}
    
    func fetchPosts() -> AnyPublisher<[Post], APIError> {
        // In prod, this would make a network request.
        // For now, simulate a network delay and return mocks.
        
        // Example of real request structure:
        /*
        guard let url = URL(string: "\(baseURL)/posts") else {
            return Fail(error: .invalidURL).eraseToAnyPublisher()
        }
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: [Post].self, decoder: JSONDecoder())
            .mapError { .decodingError($0) }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
        */
        
        return Future<[Post], APIError> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                promise(.success(Post.mocks))
            }
        }
        .eraseToAnyPublisher()
    }
    
    func fetchUser(id: UUID) -> AnyPublisher<User, APIError> {
        return Future<User, APIError> { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                promise(.success(User.mock))
            }
        }
        .eraseToAnyPublisher()
    }
}
