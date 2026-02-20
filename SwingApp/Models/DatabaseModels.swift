import Foundation

// MARK: - Database DTOs (match Supabase schema exactly)

struct DBProfile: Codable, Identifiable {
    let id: UUID
    var username: String
    var fullName: String?
    var avatarUrl: String?
    var bannerUrl: String?
    var bio: String?
    var handicap: Double?
    var universityId: UUID?
    var universityEmail: String?
    var isUniversityVerified: Bool?
    var createdAt: String?
    var updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, username, bio, handicap
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case bannerUrl = "banner_url"
        case universityId = "university_id"
        case universityEmail = "university_email"
        case isUniversityVerified = "is_university_verified"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct DBUniversity: Codable, Identifiable {
    let id: UUID
    var name: String
    var shortName: String?
    var emailDomain: String
    var logoUrl: String?
    var primaryColor: String?
    var secondaryColor: String?

    enum CodingKeys: String, CodingKey {
        case id, name
        case shortName = "short_name"
        case emailDomain = "email_domain"
        case logoUrl = "logo_url"
        case primaryColor = "primary_color"
        case secondaryColor = "secondary_color"
    }
}

struct DBGolfCourse: Codable, Identifiable {
    let id: UUID
    var name: String
    var address: String
    var city: String
    var state: String?
    var country: String
    var latitude: Double
    var longitude: Double
    var holes: Int?
    var par: Int?
    var courseRating: Double?
    var slope: Int?
    var yardage: Int?
    var phone: String?
    var website: String?
    var description: String?
    var imageUrl: String?
    var googlePlaceId: String?

    enum CodingKeys: String, CodingKey {
        case id, name, address, city, state, country, latitude, longitude
        case holes, par, slope, yardage, phone, website, description
        case courseRating = "course_rating"
        case imageUrl = "image_url"
        case googlePlaceId = "google_place_id"
    }
}

struct DBRound: Codable, Identifiable {
    let id: UUID
    var userId: UUID
    var courseId: UUID?
    var score: Int
    var datePlayed: String
    var teeBox: String?
    var notes: String?
    var weather: String?
    var photos: [String]?
    var totalPutts: Int?
    var fairwaysHit: Int?
    var fairwaysTotal: Int?
    var greensInRegulation: Int?
    var greensTotal: Int?
    var penalties: Int?
    var createdAt: String?

    // Joined data (from select with joins)
    var course: DBGolfCourse?

    enum CodingKeys: String, CodingKey {
        case id, score, notes, weather, photos, penalties, course
        case userId = "user_id"
        case courseId = "course_id"
        case datePlayed = "date_played"
        case teeBox = "tee_box"
        case totalPutts = "total_putts"
        case fairwaysHit = "fairways_hit"
        case fairwaysTotal = "fairways_total"
        case greensInRegulation = "greens_in_regulation"
        case greensTotal = "greens_total"
        case createdAt = "created_at"
    }
}

struct DBHoleScore: Codable, Identifiable {
    let id: UUID
    var roundId: UUID
    var holeNumber: Int
    var par: Int
    var score: Int
    var putts: Int?
    var fairwayHit: Bool?
    var greenInRegulation: Bool?
    var penalties: Int?
    var clubUsedOffTee: String?
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case id, par, score, putts, notes
        case roundId = "round_id"
        case holeNumber = "hole_number"
        case fairwayHit = "fairway_hit"
        case greenInRegulation = "green_in_regulation"
        case penalties
        case clubUsedOffTee = "club_used_off_tee"
    }
}

struct DBFollow: Codable {
    var followerId: UUID
    var followingId: UUID
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case followerId = "follower_id"
        case followingId = "following_id"
        case createdAt = "created_at"
    }
}

struct DBLike: Codable {
    var userId: UUID
    var roundId: UUID
    var createdAt: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case roundId = "round_id"
        case createdAt = "created_at"
    }
}

struct DBComment: Codable, Identifiable {
    let id: UUID
    var userId: UUID
    var roundId: UUID
    var content: String
    var createdAt: String?

    // Joined
    var profile: DBProfile?

    enum CodingKeys: String, CodingKey {
        case id, content, profile
        case userId = "user_id"
        case roundId = "round_id"
        case createdAt = "created_at"
    }
}

struct DBFavoriteCourse: Codable, Identifiable {
    let id: UUID
    var userId: UUID
    var courseId: UUID
    var rank: Int

    var course: DBGolfCourse?

    enum CodingKeys: String, CodingKey {
        case id, rank, course
        case userId = "user_id"
        case courseId = "course_id"
    }
}

// MARK: - Insert DTOs (for creating new records, no id needed)

struct InsertRound: Codable {
    var userId: UUID
    var courseId: UUID?
    var score: Int
    var datePlayed: String
    var teeBox: String?
    var notes: String?
    var totalPutts: Int?
    var fairwaysHit: Int?
    var fairwaysTotal: Int?
    var greensInRegulation: Int?
    var greensTotal: Int?
    var penalties: Int?

    enum CodingKeys: String, CodingKey {
        case score, notes, penalties
        case userId = "user_id"
        case courseId = "course_id"
        case datePlayed = "date_played"
        case teeBox = "tee_box"
        case totalPutts = "total_putts"
        case fairwaysHit = "fairways_hit"
        case fairwaysTotal = "fairways_total"
        case greensInRegulation = "greens_in_regulation"
        case greensTotal = "greens_total"
    }
}

struct InsertHoleScore: Codable {
    var roundId: UUID
    var holeNumber: Int
    var par: Int
    var score: Int
    var putts: Int?
    var fairwayHit: Bool?
    var greenInRegulation: Bool?
    var penalties: Int?

    enum CodingKeys: String, CodingKey {
        case par, score, putts, penalties
        case roundId = "round_id"
        case holeNumber = "hole_number"
        case fairwayHit = "fairway_hit"
        case greenInRegulation = "green_in_regulation"
    }
}

struct UpdateProfile: Codable {
    var username: String?
    var fullName: String?
    var bio: String?
    var avatarUrl: String?
    var handicap: Double?

    enum CodingKeys: String, CodingKey {
        case username, bio, handicap
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
    }
}
