import SwiftUI

struct RankingEntry: Identifiable {
    let id = UUID()
    var course: String
    var location: String
}

struct RankingsView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var isEditing = false
    @State private var rankingList: [RankingEntry] = [
        RankingEntry(course: "Sandpiper Golf Club", location: "Goleta, CA"),
        RankingEntry(course: "Riviera Country Club", location: "Pacific Palisades, CA"),
        RankingEntry(course: "Alisal River Course", location: "Solvang, CA"),
        RankingEntry(course: "Rustic Canyon Golf Course", location: "Moorpark, CA"),
        RankingEntry(course: "La Purisima Golf Course", location: "Lompoc, CA")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Your Course Rankings")
                    .font(GolfrFonts.headline())
                    .foregroundColor(GolfrColors.textPrimary)
                Spacer()
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isEditing.toggle()
                    }
                }) {
                    Text(isEditing ? "Done" : "Edit")
                        .font(GolfrFonts.caption())
                        .foregroundColor(GolfrColors.primaryLight)
                }
            }
            .padding(.horizontal)

            if isEditing {
                // Editable reorder list
                VStack(spacing: 8) {
                    ForEach(Array(rankingList.enumerated()), id: \.element.id) { index, ranking in
                        EditableRankingRow(
                            rank: index + 1,
                            courseName: ranking.course,
                            location: ranking.location,
                            onMoveUp: index > 0 ? {
                                withAnimation { rankingList.swapAt(index, index - 1) }
                            } : nil,
                            onMoveDown: index < rankingList.count - 1 ? {
                                withAnimation { rankingList.swapAt(index, index + 1) }
                            } : nil
                        )
                        .padding(.horizontal)
                    }
                }
            } else {
                // Podium top 3 (Duolingo-style)
                if rankingList.count >= 3 {
                    PodiumView(rankings: rankingList.prefix(3).map { ($0.course, $0.location) })
                        .padding(.horizontal)
                }

                // Remaining rankings
                VStack(spacing: 8) {
                    ForEach(Array(rankingList.enumerated()), id: \.element.id) { index, ranking in
                        if index >= 3 {
                            RankingRow(rank: index + 1, courseName: ranking.course, location: ranking.location)
                                .padding(.horizontal)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Editable Ranking Row (Edit mode)

struct EditableRankingRow: View {
    let rank: Int
    let courseName: String
    let location: String
    var onMoveUp: (() -> Void)?
    var onMoveDown: (() -> Void)?

    var body: some View {
        HStack(spacing: 14) {
            Text("\(rank)")
                .font(GolfrFonts.headline())
                .foregroundColor(GolfrColors.textSecondary)
                .frame(width: 28)

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

            // Reorder arrows
            VStack(spacing: 4) {
                Button(action: { onMoveUp?() }) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(onMoveUp != nil ? GolfrColors.textSecondary : GolfrColors.textSecondary.opacity(0.2))
                }
                .disabled(onMoveUp == nil)

                Button(action: { onMoveDown?() }) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(onMoveDown != nil ? GolfrColors.textSecondary : GolfrColors.textSecondary.opacity(0.2))
                }
                .disabled(onMoveDown == nil)
            }
        }
        .padding(12)
        .golfrCard(cornerRadius: 12)
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
