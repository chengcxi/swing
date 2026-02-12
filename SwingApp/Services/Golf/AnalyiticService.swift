import Foundation

@MainActor
class AnalyticsService: ObservableObject {
    static let shared = AnalyticsService()
    
    @Published var overallAnalytics: OverallAnalytics?
    @Published var courseAnalytics: [UUID: CourseAnalytics] = [:]
    // @Published var clubDistances: [ClubDistance] = []
    @Published var isLoading = false
    
    // MARK: - Overall Analytics
    
    func fetchOverallAnalytics(userId: UUID) async throws -> OverallAnalytics {
        isLoading = true
        defer { isLoading = false }
        
        // Fetch all rounds with hole scores
        let rounds: [Round] = try await supabase
            .from("rounds")
            .select("*, course:golf_courses(*), hole_scores(*)")
            .eq("user_id", value: userId.uuidString)
            .order("date_played", ascending: false)
            .execute()
            .value
        
        guard !rounds.isEmpty else {
            throw AnalyticsError.noData
        }
        
        // Calculate stats
        let scores = rounds.map { $0.score }
        let avgScore = Double(scores.reduce(0, +)) / Double(scores.count)
        let bestScore = scores.min()
        
        // TODO: Scoring breakdown from hole scores
        // var eagles = 0, birdies = 0, pars = 0, bogeys = 0, doubleBogeys = 0, other = 0
        // var totalPutts = 0, puttCount = 0
        // var onePutts = 0, threePutts = 0
        // var fairwaysHit = 0, fairwaysTotal = 0
        // var gir = 0, girTotal = 0
        
        // for round in rounds {
        //     if let holeScores = round.holeScores {
        //         for hole in holeScores {
        //             let diff = hole.score - hole.par
        //             switch diff {
        //             case ...(-2): eagles += 1
        //             case -1: birdies += 1
        //             case 0: pars += 1
        //             case 1: bogeys += 1
        //             case 2: doubleBogeys += 1
        //             default: other += 1
        //             }
                    
        //             if let putts = hole.putts {
        //                 totalPutts += putts
        //                 puttCount += 1
        //                 if putts == 1 { onePutts += 1 }
        //                 if putts >= 3 { threePutts += 1 }
        //             }
                    
        //             if hole.fairwayHit != nil {
        //                 fairwaysTotal += 1
        //                 if hole.fairwayHit == true { fairwaysHit += 1 }
        //             }
                    
        //             if hole.greenInRegulation != nil {
        //                 girTotal += 1
        //                 if hole.greenInRegulation == true { gir += 1 }
        //             }
        //         }
        //     }
        // }
        
        // Build score trend
        let scoreTrend = rounds.map { round in
            ScoreTrend(
                id: round.id,
                roundId: round.id,
                datePlayed: round.datePlayed,
                score: round.score,
                handicapDifferential: round.handicapDifferential,
                courseName: round.course?.name
            )
        }
        
        let analytics = OverallAnalytics(
            totalRounds: rounds.count,
            averageScore: avgScore,
            bestScore: bestScore,
            handicap: AuthService.shared.currentProfile?.handicap,
            handicapTrend: nil, // Calculate separately if needed
            scoreTrend: scoreTrend,
            // scoringBreakdown: OverallAnalytics.ScoringBreakdown(
            //     eagles: eagles,
            //     birdies: birdies,
            //     pars: pars,
            //     bogeys: bogeys,
            //     doubleBogeys: doubleBogeys,
            //     other: other
            // ),
            // puttingStats: puttCount > 0 ? OverallAnalytics.PuttingStats(
            //     averagePutts: Double(totalPutts) / Double(puttCount),
            //     onePuttPercentage: Double(onePutts) / Double(puttCount) * 100,
            //     threePuttPercentage: Double(threePutts) / Double(puttCount) * 100
            // ) : nil,
            // drivingStats: fairwaysTotal > 0 ? OverallAnalytics.DrivingStats(
            //     fairwayPercentage: Double(fairwaysHit) / Double(fairwaysTotal) * 100,
            //     averageDistance: nil
            // ) : nil,
            // approachStats: girTotal > 0 ? OverallAnalytics.ApproachStats(
            //     girPercentage: Double(gir) / Double(girTotal) * 100,
            //     scramblePercentage: nil
            // ) : nil
        )
        
        overallAnalytics = analytics
        return analytics
    }
    
    // MARK: - Course-Specific Analytics
    
    func fetchCourseAnalytics(userId: UUID, courseId: UUID) async throws -> CourseAnalytics {
        isLoading = true
        defer { isLoading = false }
        
        let rounds: [Round] = try await supabase
            .from("rounds")
            .select("*, course:golf_courses(*), hole_scores(*)")
            .eq("user_id", value: userId.uuidString)
            .eq("course_id", value: courseId.uuidString)
            .order("date_played", ascending: false)
            .execute()
            .value
        
        guard !rounds.isEmpty, let course = rounds.first?.course else {
            throw AnalyticsError.noData
        }
        
        let scores = rounds.map { $0.score }
        
        // TODO: Calculate hole-by-hole analytics
        // var holeData: [Int: [HoleScore]] = [:]
        // for round in rounds {
        //     if let holeScores = round.holeScores {
        //         for hole in holeScores {
        //             holeData[hole.holeNumber, default: []].append(hole)
        //         }
        //     }
        // }
        
        // let holeAnalytics = holeData.map { holeNumber, scores -> HoleAnalytics in
        //     let avgScore = Double(scores.map { $0.score }.reduce(0, +)) / Double(scores.count)
        //     let par = scores.first?.par ?? 4
            
        //     var birdies = 0, parsCount = 0, bogeys = 0, doublePlus = 0
        //     var puttsSum = 0, puttsCount = 0
        //     var fwHit = 0, fwTotal = 0
        //     var girHit = 0, girTot = 0
            
        //     for score in scores {
        //         let diff = score.score - score.par
        //         switch diff {
        //         case ...(-1): birdies += 1
        //         case 0: parsCount += 1
        //         case 1: bogeys += 1
        //         default: doublePlus += 1
        //         }
                
        //         if let putts = score.putts {
        //             puttsSum += putts
        //             puttsCount += 1
        //         }
        //         if score.fairwayHit != nil {
        //             fwTotal += 1
        //             if score.fairwayHit == true { fwHit += 1 }
        //         }
        //         if score.greenInRegulation != nil {
        //             girTot += 1
        //             if score.greenInRegulation == true { girHit += 1 }
        //         }
        //     }
            
        //     return HoleAnalytics(
        //         holeNumber: holeNumber,
        //         par: par,
        //         averageScore: avgScore,
        //         birdieCount: birdies,
        //         parCount: parsCount,
        //         bogeyCount: bogeys,
        //         doubleBogeyPlusCount: doublePlus,
        //         averagePutts: puttsCount > 0 ? Double(puttsSum) / Double(puttsCount) : nil,
        //         fairwayHitPercentage: fwTotal > 0 ? Double(fwHit) / Double(fwTotal) * 100 : nil,
        //         girPercentage: girTot > 0 ? Double(girHit) / Double(girTot) * 100 : nil
        //     )
        // }.sorted { $0.holeNumber < $1.holeNumber }
        
        let analytics = CourseAnalytics(
            courseId: courseId,
            courseName: course.name,
            roundsPlayed: rounds.count,
            averageScore: Double(scores.reduce(0, +)) / Double(scores.count),
            bestScore: scores.min() ?? 0,
            worstScore: scores.max() ?? 0,
            // averagePutts: rounds.compactMap { $0.totalPutts }.isEmpty ? nil :
            //     Double(rounds.compactMap { $0.totalPutts }.reduce(0, +)) / Double(rounds.compactMap { $0.totalPutts }.count),
            // fairwayPercentage: nil,
            // girPercentage: nil,
            // holeAnalytics: holeAnalytics
        )
        
        courseAnalytics[courseId] = analytics
        return analytics
    }
    
    // MARK: - Club Distances
    
    // func fetchClubDistances(userId: UUID) async throws -> [ClubDistance] {
    //     let distances: [ClubDistance] = try await supabase
    //         .from("club_distances")
    //         .select()
    //         .eq("user_id", value: userId.uuidString)
    //         .execute()
    //         .value
        
    //     clubDistances = distances
    //     return distances
    // }
    
    // func updateClubDistance(_ clubDistance: ClubDistanceInsert) async throws {
    //     // Upsert club distance
    //     try await supabase
    //         .from("club_distances")
    //         .upsert(clubDistance, onConflict: "user_id, club_type")
    //         .execute()
        
    //     if let userId = AuthService.shared.currentUser?.id {
    //         _ = try await fetchClubDistances(userId: userId)
    //     }
    // }
}

enum AnalyticsError: LocalizedError {
    case noData
    
    var errorDescription: String? {
        switch self {
        case .noData: return "No data available."
        }
    }
}