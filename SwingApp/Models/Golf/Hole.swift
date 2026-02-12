// NOT USED YET
// TODO: Implement once backend ready

import Foundation

struct HoleScore: Codable, Identifiable, Hashable {
    let id: UUID
    let roundId: UUID
    var holeNumber: Int
    var par: Int
    var score: Int
    var putts: Int?
    var fairwayHit: Bool?
    var greenInRegulation: Bool?
    var penalties: Int?
    var clubUsedOffTee: String?
    var notes: String?
    
    // Computed
    var scoreToPar: Int { score - par }
    
    var scoreType: ScoreType {
        let diff = scoreToPar
        switch diff {
        case ...(-3): return .albatross
        case -2: return .eagle
        case -1: return .birdie
        case 0: return .par
        case 1: return .bogey
        case 2: return .doubleBogey
        default: return .other
        }
    }
    
    enum ScoreType: String, Codable {
        case albatross, eagle, birdie, par, bogey, doubleBogey, other
        
        var displayName: String {
            switch self {
            case .albatross: return "Albatross"
            case .eagle: return "Eagle"
            case .birdie: return "Birdie"
            case .par: return "Par"
            case .bogey: return "Bogey"
            case .doubleBogey: return "Double Bogey"
            case .other: return "Other"
            }
        }
        
        var color: String {
            switch self {
            case .albatross, .eagle: return "gold"
            case .birdie: return "red"
            case .par: return "green"
            case .bogey: return "blue"
            case .doubleBogey, .other: return "gray"
            }
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, par, score, putts, penalties, notes
        case roundId = "round_id"
        case holeNumber = "hole_number"
        case fairwayHit = "fairway_hit"
        case greenInRegulation = "green_in_regulation"
        case clubUsedOffTee = "club_used_off_tee"
    }
}

struct HoleScoreInsert: Codable {
    let roundId: UUID
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
        case par, score, putts, penalties, notes
        case roundId = "round_id"
        case holeNumber = "hole_number"
        case fairwayHit = "fairway_hit"
        case greenInRegulation = "green_in_regulation"
        case clubUsedOffTee = "club_used_off_tee"
    }
}