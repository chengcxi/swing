import SwiftUI

struct CourseSearchView: View {
    @StateObject private var viewModel = CourseViewModel()
    @State private var selectedFilter: CourseFilter = .all

    enum CourseFilter: String, CaseIterable {
        case all = "All"
        case nearby = "Nearby"
        case topRated = "Top Rated"
        case practiced = "Practiced"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(GolfrColors.textSecondary)

                    TextField("Search courses, cities...", text: $viewModel.searchText)
                        .font(GolfrFonts.body())

                    if !viewModel.searchText.isEmpty {
                        Button(action: { viewModel.searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(GolfrColors.textSecondary)
                        }
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(GolfrColors.backgroundCard)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(GolfrColors.textSecondary.opacity(0.1), lineWidth: 1)
                )
                .padding(.horizontal)
                .padding(.top, 8)

                // Filter pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(CourseFilter.allCases, id: \.self) { filter in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedFilter = filter
                                }
                            }) {
                                Text(filter.rawValue)
                                    .golfrPillButton(isActive: selectedFilter == filter)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)

                // Featured course header card
                if !viewModel.filteredCourses.isEmpty {
                    FeaturedCourseCard(course: viewModel.filteredCourses[0])
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                }

                // Course List
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.filteredCourses.dropFirst()) { course in
                            CourseListCard(course: course)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
            .background(GolfrColors.backgroundPrimary.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("Discover")
                        .font(GolfrFonts.title())
                        .foregroundColor(GolfrColors.textPrimary)
                        .fixedSize()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 8) {
                        GolfrNavButton(icon: "map") {}
                        GolfrNavButton(icon: "slider.horizontal.3") {}
                    }
                }
            }
        }
    }
}

// MARK: - Featured Course Card (Phantom-style hero)

struct FeaturedCourseCard: View {
    let course: Course

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(GolfrColors.cardGradient)
                    .frame(height: 140)

                // Decorative circles
                GeometryReader { geo in
                    Circle()
                        .fill(Color.white.opacity(0.05))
                        .frame(width: 100, height: 100)
                        .offset(x: geo.size.width - 60, y: -20)

                    Circle()
                        .fill(Color.white.opacity(0.03))
                        .frame(width: 60, height: 60)
                        .offset(x: geo.size.width - 120, y: 80)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Featured")
                            .font(GolfrFonts.caption())
                            .foregroundColor(GolfrColors.gold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(GolfrColors.gold.opacity(0.2))
                            )
                        Spacer()
                    }

                    Spacer()

                    Text(course.name)
                        .font(GolfrFonts.title())
                        .foregroundColor(.white)

                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin")
                                .font(.system(size: 10))
                            Text(course.location)
                                .font(GolfrFonts.caption())
                        }
                        .foregroundColor(GolfrColors.textOnDarkMuted)

                        HStack(spacing: 4) {
                            Image(systemName: "flag")
                                .font(.system(size: 10))
                            Text("\(course.holes) holes")
                                .font(GolfrFonts.caption())
                        }
                        .foregroundColor(GolfrColors.textOnDarkMuted)

                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                            Text(String(format: "%.1f", course.difficulty))
                                .font(GolfrFonts.caption())
                        }
                        .foregroundColor(GolfrColors.gold)
                    }
                }
                .padding(16)
            }
            .frame(height: 140)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .shadow(color: GolfrColors.primary.opacity(0.2), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Course List Card

struct CourseListCard: View {
    let course: Course

    var body: some View {
        HStack(spacing: 14) {
            // Thumbnail placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(GolfrColors.primaryMedium.opacity(0.1))
                    .frame(width: 72, height: 72)

                Image(systemName: "figure.golf")
                    .font(.system(size: 24))
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
                    Text("\(course.holes) holes")
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

            // Difficulty badge
            VStack(spacing: 2) {
                Text(String(format: "%.1f", course.difficulty))
                    .font(GolfrFonts.title3())
                    .foregroundColor(GolfrColors.primary)
                Text("diff")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .foregroundColor(GolfrColors.textSecondary)
            }
        }
        .padding(12)
        .golfrCard(cornerRadius: 16)
    }
}
