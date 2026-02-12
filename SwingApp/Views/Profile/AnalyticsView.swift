import SwiftUI
import Charts

struct AnalyticsView: View {
    let rounds = Round.mocks

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Score Trends Chart
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Score Trends")
                        .font(GolfrFonts.headline())
                        .foregroundColor(GolfrColors.textPrimary)
                    Spacer()
                    Text("Last \(rounds.count) rounds")
                        .font(GolfrFonts.caption())
                        .foregroundColor(GolfrColors.textSecondary)
                }

                Chart {
                    ForEach(rounds) { round in
                        LineMark(
                            x: .value("Date", round.date),
                            y: .value("Score", round.score)
                        )
                        .foregroundStyle(GolfrColors.primaryLight)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))

                        AreaMark(
                            x: .value("Date", round.date),
                            y: .value("Score", round.score)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [GolfrColors.primaryLight.opacity(0.2), GolfrColors.primaryLight.opacity(0.0)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", round.date),
                            y: .value("Score", round.score)
                        )
                        .foregroundStyle(GolfrColors.primary)
                        .symbolSize(30)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine()
                            .foregroundStyle(Color.gray.opacity(0.1))
                        AxisValueLabel()
                            .font(GolfrFonts.caption())
                            .foregroundStyle(GolfrColors.textSecondary)
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                            .font(GolfrFonts.caption())
                            .foregroundStyle(GolfrColors.textSecondary)
                    }
                }
                .frame(height: 180)
            }
            .padding(16)
            .golfrCard(cornerRadius: 16)
            .padding(.horizontal)

            // Performance breakdown
            VStack(alignment: .leading, spacing: 12) {
                Text("Performance")
                    .font(GolfrFonts.headline())
                    .foregroundColor(GolfrColors.textPrimary)

                PerformanceRow(label: "Fairways Hit", value: 68, color: GolfrColors.primaryLight)
                PerformanceRow(label: "Greens in Regulation", value: 55, color: GolfrColors.primaryMedium)
                PerformanceRow(label: "Putts per Round", value: 72, color: GolfrColors.gold)
                PerformanceRow(label: "Sand Saves", value: 40, color: GolfrColors.warning)
            }
            .padding(16)
            .golfrCard(cornerRadius: 16)
            .padding(.horizontal)

            // Best / Worst
            HStack(spacing: 12) {
                HighlightCard(
                    title: "Best Round",
                    value: "\(rounds.min(by: { $0.score < $1.score })?.score ?? 0)",
                    subtitle: rounds.min(by: { $0.score < $1.score })?.courseName ?? "",
                    icon: "arrow.up.circle.fill",
                    color: GolfrColors.success
                )

                HighlightCard(
                    title: "Worst Round",
                    value: "\(rounds.max(by: { $0.score < $1.score })?.score ?? 0)",
                    subtitle: rounds.max(by: { $0.score < $1.score })?.courseName ?? "",
                    icon: "arrow.down.circle.fill",
                    color: GolfrColors.error
                )
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

// MARK: - Performance Row

struct PerformanceRow: View {
    let label: String
    let value: Int // percentage
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(GolfrFonts.callout())
                    .foregroundColor(GolfrColors.textPrimary)
                Spacer()
                Text("\(value)%")
                    .font(GolfrFonts.callout())
                    .foregroundColor(color)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color.opacity(0.12))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(value) / 100.0, height: 6)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Highlight Card

struct HighlightCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(GolfrFonts.stat())
                .foregroundColor(GolfrColors.textPrimary)

            Text(title)
                .font(GolfrFonts.caption())
                .foregroundColor(GolfrColors.textSecondary)

            Text(subtitle)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(GolfrColors.textSecondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .golfrCard(cornerRadius: 14)
    }
}
