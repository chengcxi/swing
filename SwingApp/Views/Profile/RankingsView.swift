import SwiftUI

struct RankingsView: View {
    @EnvironmentObject var appViewModel: AppViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Your Course Rankings")
                    .font(GolfrFonts.headline())
                    .foregroundColor(GolfrColors.textPrimary)
                Spacer()
                Button(action: {}) {
                    Text("Edit")
                        .font(GolfrFonts.caption())
                        .foregroundColor(GolfrColors.primaryLight)
                }
            }
            .padding(.horizontal)

            // Podium top 3 (Duolingo-style)
            if rankings.count >= 3 {
                PodiumView(rankings: Array(rankings.prefix(3)))
                    .padding(.horizontal)
            }

            // Remaining rankings
            VStack(spacing: 8) {
                ForEach(Array(rankings.enumerated()), id: \.offset) { index, ranking in
                    if index >= 3 {
                        RankingRow(rank: index + 1, courseName: ranking.course, location: ranking.location)
                            .padding(.horizontal)
                    }
                }
            }
        }
        .padding(.vertical)
    }

    var rankings: [(course: String, location: String)] {
        [
            ("Sandpiper Golf Club", "Goleta, CA"),
            ("Riviera Country Club", "Pacific Palisades, CA"),
            ("Alisal River Course", "Solvang, CA"),
            ("Rustic Canyon Golf Course", "Moorpark, CA"),
            ("La Purisima Golf Course", "Lompoc, CA")
        ]
    }
}

// MARK: - Podium View (Duolingo-style top 3)

struct PodiumView: View {
    let rankings: [(course: String, location: String)]

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            // 2nd place
            if rankings.count > 1 {
                PodiumItem(
                    rank: 2,
                    name: rankings[1].course,
                    height: 80,
                    color: GolfrColors.textSecondary
                )
            }

            // 1st place
            PodiumItem(
                rank: 1,
                name: rankings[0].course,
                height: 110,
                color: GolfrColors.gold
            )

            // 3rd place
            if rankings.count > 2 {
                PodiumItem(
                    rank: 3,
                    name: rankings[2].course,
                    height: 60,
                    color: Color(hex: "CD7F32")
                )
            }
        }
    }
}

struct PodiumItem: View {
    let rank: Int
    let name: String
    let height: CGFloat
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            // Medal
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Text("\(rank)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(color)
            }

            Text(name)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(GolfrColors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(height: 28)

            // Podium bar
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.3), color.opacity(0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: height)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Ranking Row

struct RankingRow: View {
    let rank: Int
    let courseName: String
    let location: String

    var body: some View {
        HStack(spacing: 14) {
            // Rank number
            Text("\(rank)")
                .font(GolfrFonts.headline())
                .foregroundColor(GolfrColors.textSecondary)
                .frame(width: 28)

            // Course icon
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(GolfrColors.primary.opacity(0.08))
                    .frame(width: 40, height: 40)
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 14))
                    .foregroundColor(GolfrColors.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(courseName)
                    .font(GolfrFonts.headline())
                    .foregroundColor(GolfrColors.textPrimary)
                Text(location)
                    .font(GolfrFonts.caption())
                    .foregroundColor(GolfrColors.textSecondary)
            }

            Spacer()

            Image(systemName: "line.3.horizontal")
                .font(.system(size: 14))
                .foregroundColor(GolfrColors.textSecondary.opacity(0.4))
        }
        .padding(12)
        .golfrCard(cornerRadius: 12)
    }
}
