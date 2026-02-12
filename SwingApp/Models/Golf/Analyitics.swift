import Foundation

// MARK: - Score Trend
struct ScoreTrend: Codable, Identifiable {
    let id: UUID
    let roundId: UUID
    let datePlayed: Date
    let score: Int
    let handicapDifferential: Double?
    let courseName: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case roundId = "round_id"
        case datePlayed = "date_played"
        case score
        case handicapDifferential = "handicap_differential"
        case courseName = "course_name"
    }
}

// MARK: - Hole Analytics
// struct HoleAnalytics: Codable {
//     let holeNumber: Int
//     let par: Int
//     let averageScore: Double
//     let birdieCount: Int
//     let parCount: Int
//     let bogeyCount: Int
//     let doubleBogeyPlusCount: Int
//     let averagePutts: Double?
//     let fairwayHitPercentage: Double?
//     let girPercentage: Double?
    
//     var scoringDistribution: [String: Int] {
//         [
//             "Birdie or Better": birdieCount,
//             "Par": parCount,
//             "Bogey": bogeyCount,
//             "Double+": doubleBogeyPlusCount
//         ]
//     }
    
//     enum CodingKeys: String, CodingKey {
//         case holeNumber = "hole_number"
//         case par
//         case averageScore = "average_score"
//         case birdieCount = "birdie_count"
//         case parCount = "par_count"
//         case bogeyCount = "bogey_count"
//         case doubleBogeyPlusCount = "double_bogey_plus_count"
//         case averagePutts = "average_putts"
//         case fairwayHitPercentage = "fairway_hit_percentage"
//         case girPercentage = "gir_percentage"
//     }
// }

// MARK: - Course Analytics
struct CourseAnalytics: Codable {
    let courseId: UUID
    let courseName: String
    let roundsPlayed: Int
    let averageScore: Double
    let bestScore: Int
    let worstScore: Int
    // let averagePutts: Double?
    // let fairwayPercentage: Double?
    // let girPercentage: Double?
    // let holeAnalytics: [HoleAnalytics]?
    
    enum CodingKeys: String, CodingKey {
        case courseId = "course_id"
        case courseName = "course_name"
        case roundsPlayed = "rounds_played"
        case averageScore = "average_score"
        case bestScore = "best_score"
        case worstScore = "worst_score"
        // case averagePutts = "average_putts"
        // case fairwayPercentage = "fairway_percentage"
        // case girPercentage = "gir_percentage"
        // case holeAnalytics = "hole_analytics"
    }
}

// MARK: - Overall Analytics
struct OverallAnalytics: Codable {
    let totalRounds: Int
    let averageScore: Double?
    let bestScore: Int?
    let handicap: Double?
    let handicapTrend: [HandicapTrendPoint]?
    let scoreTrend: [ScoreTrend]?
    let scoringBreakdown: ScoringBreakdown?
    // let puttingStats: PuttingStats?
    // let drivingStats: DrivingStats?
    // let approachStats: ApproachStats?
    
    // struct ScoringBreakdown: Codable {
    //     let eagles: Int
    //     let birdies: Int
    //     let pars: Int
    //     let bogeys: Int
    //     let doubleBogeys: Int
    //     let other: Int
        
    //     var total: Int { eagles + birdies + pars + bogeys + doubleBogeys + other }
        
    //     enum CodingKeys: String, CodingKey {
    //         case eagles, birdies, pars, bogeys
    //         case doubleBogeys = "double_bogeys"
    //         case other
    //     }
    // }
    
    // struct PuttingStats: Codable {
    //     let averagePutts: Double
    //     let onePuttPercentage: Double
    //     let threePuttPercentage: Double
        
    //     enum CodingKeys: String, CodingKey {
    //         case averagePutts = "average_putts"
    //         case onePuttPercentage = "one_putt_percentage"
    //         case threePuttPercentage = "three_putt_percentage"
    //     }
    // }
    
    // struct DrivingStats: Codable {
    //     let fairwayPercentage: Double
    //     let averageDistance: Int?
        
    //     enum CodingKeys: String, CodingKey {
    //         case fairwayPercentage = "fairway_percentage"
    //         case averageDistance = "average_distance"
    //     }
    // }
    
    // struct ApproachStats: Codable {
    //     let girPercentage: Double
    //     let scramblePercentage: Double?
        
    //     enum CodingKeys: String, CodingKey {
    //         case girPercentage = "gir_percentage"
    //         case scramblePercentage = "scramble_percentage"
    //     }
    // }
    
    struct HandicapTrendPoint: Codable, Identifiable {
        var id: Date { date }
        let date: Date
        let handicap: Double
    }
    
    enum CodingKeys: String, CodingKey {
        case totalRounds = "total_rounds"
        case averageScore = "average_score"
        case bestScore = "best_score"
        case handicap
        case handicapTrend = "handicap_trend"
        case scoreTrend = "score_trend"
        case scoringBreakdown = "scoring_breakdown"
        // case puttingStats = "putting_stats"
        // case drivingStats = "driving_stats"
        // case approachStats = "approach_stats"
    }
}