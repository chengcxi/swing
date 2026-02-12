import SwiftUI

// CourseRow is now replaced by CourseListCard in CourseSearchView.swift
// Keeping this file for any legacy references

struct CourseRow: View {
    let course: Course

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(GolfrColors.primaryMedium.opacity(0.1))
                    .frame(width: 60, height: 60)
                Image(systemName: "figure.golf")
                    .font(.system(size: 22))
                    .foregroundColor(GolfrColors.primaryMedium.opacity(0.5))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(course.name)
                    .font(GolfrFonts.headline())
                    .foregroundColor(GolfrColors.textPrimary)

                HStack(spacing: 4) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 10))
                    Text(course.location)
                        .font(GolfrFonts.caption())
                }
                .foregroundColor(GolfrColors.textSecondary)

                HStack(spacing: 8) {
                    Text("\(course.holes) Holes")
                        .golfrChip(color: GolfrColors.primary)

                    if course.hasDrivingRange {
                        Text("Range")
                            .golfrChip(color: GolfrColors.primaryMedium)
                    }

                    if course.hasPuttingGreen {
                        Text("Putting")
                            .golfrChip(color: GolfrColors.primaryMedium)
                    }
                }
            }

            Spacer()
        }
        .padding(12)
        .golfrCard(cornerRadius: 14)
    }
}
