import SwiftUI

struct RankingsView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var isEditing = false
    @State private var rankingList: [Course] = []
    @State private var isLoading = false
    @State private var showAddSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Course Rankings")
                    .font(GolfrFonts.headline())
                    .foregroundColor(GolfrColors.textPrimary)
                Spacer()
                if !rankingList.isEmpty {
                    Button(action: {
                        if isEditing {
                            // Persist on Done
                            Task { await appViewModel.saveFavoriteCoursesOrder(rankingList) }
                        }
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isEditing.toggle()
                        }
                    }) {
                        Text(isEditing ? "Done" : "Edit")
                            .font(GolfrFonts.caption())
                            .foregroundColor(GolfrColors.primaryLight)
                    }
                }
            }
            .padding(.horizontal)

            if isLoading && rankingList.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else if rankingList.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "trophy")
                        .font(.system(size: 28))
                        .foregroundColor(GolfrColors.textSecondary.opacity(0.4))
                    Text("Rank your favorite courses")
                        .font(GolfrFonts.callout())
                        .foregroundColor(GolfrColors.textSecondary)
                    Button(action: { showAddSheet = true }) {
                        Text("Add a course")
                            .font(GolfrFonts.caption())
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(Capsule().fill(GolfrColors.primary))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
            } else if isEditing {
                VStack(spacing: 8) {
                    ForEach(Array(rankingList.enumerated()), id: \.element.id) { index, course in
                        EditableRankingRow(
                            rank: index + 1,
                            courseName: course.name,
                            location: course.location,
                            onMoveUp: index > 0 ? {
                                withAnimation { rankingList.swapAt(index, index - 1) }
                            } : nil,
                            onMoveDown: index < rankingList.count - 1 ? {
                                withAnimation { rankingList.swapAt(index, index + 1) }
                            } : nil,
                            onDelete: {
                                let id = course.id
                                withAnimation { rankingList.remove(at: index) }
                                Task { await appViewModel.removeFavoriteCourse(courseId: id) }
                            }
                        )
                        .padding(.horizontal)
                    }
                    Button(action: { showAddSheet = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add a course")
                                .font(GolfrFonts.callout())
                        }
                        .foregroundColor(GolfrColors.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                }
            } else {
                if rankingList.count >= 3 {
                    PodiumView(rankings: rankingList.prefix(3).map { ($0.name, $0.location) })
                        .padding(.horizontal)
                }
                VStack(spacing: 8) {
                    ForEach(Array(rankingList.enumerated()), id: \.element.id) { index, course in
                        if index >= 3 {
                            RankingRow(rank: index + 1, courseName: course.name, location: course.location)
                                .padding(.horizontal)
                        }
                    }
                }
            }
        }
        .task(id: appViewModel.currentUser?.id) { await load() }
        .sheet(isPresented: $showAddSheet) {
            AddRankingSheet { course in
                Task {
                    await appViewModel.addFavoriteCourse(course)
                    await load()
                }
            }
        }
    }

    private func load() async {
        isLoading = true
        rankingList = await appViewModel.fetchFavoriteCourses()
        isLoading = false
    }
}

// MARK: - Editable Ranking Row

struct EditableRankingRow: View {
    let rank: Int
    let courseName: String
    let location: String
    var onMoveUp: (() -> Void)?
    var onMoveDown: (() -> Void)?
    var onDelete: (() -> Void)?

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

            if let onDelete {
                Button(action: onDelete) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(GolfrColors.error)
                }
            }

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

// MARK: - Add Ranking Sheet

struct AddRankingSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var query = ""
    @State private var results: [Course] = []
    @State private var isLoading = false
    @State private var searchTask: Task<Void, Never>?
    var onPick: (Course) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                GolfrColors.backgroundPrimary.ignoresSafeArea()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(GolfrColors.textSecondary)
                            TextField("Search courses…", text: $query)
                                .font(GolfrFonts.body())
                                .autocapitalization(.none)
                                .autocorrectionDisabled(true)
                                .onChange(of: query) { newValue in
                                    scheduleSearch(newValue)
                                }
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(GolfrColors.backgroundCard)
                        )
                        .padding(.horizontal)
                        .padding(.top, 8)

                        if isLoading {
                            ProgressView().padding(.top, 16)
                        } else if results.isEmpty {
                            Text(query.isEmpty ? "Type to search courses" : "No courses found")
                                .font(GolfrFonts.callout())
                                .foregroundColor(GolfrColors.textSecondary)
                                .padding(.top, 24)
                        } else {
                            ForEach(results) { course in
                                Button(action: {
                                    onPick(course)
                                    dismiss()
                                }) {
                                    HStack(spacing: 12) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(GolfrColors.primary.opacity(0.08))
                                                .frame(width: 44, height: 44)
                                            Image(systemName: "figure.golf")
                                                .foregroundColor(GolfrColors.primary)
                                        }
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(course.name)
                                                .font(GolfrFonts.headline())
                                                .foregroundColor(GolfrColors.textPrimary)
                                            Text(course.location)
                                                .font(GolfrFonts.caption())
                                                .foregroundColor(GolfrColors.textSecondary)
                                                .lineLimit(1)
                                        }
                                        Spacer()
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(GolfrColors.primaryLight)
                                    }
                                    .padding(12)
                                    .golfrCard(cornerRadius: 14)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add to rankings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(GolfrColors.primary)
                }
            }
        }
    }

    private func scheduleSearch(_ text: String) {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            if Task.isCancelled { return }
            await runSearch(text)
        }
    }

    @MainActor
    private func runSearch(_ text: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let hits = try await GooglePlacesService.shared.searchGolfCourses(query: text)
            if !hits.isEmpty {
                results = hits
                return
            }
        } catch {
            print("AddRankingSheet Places failed: \(error)")
        }
        // Supabase fallback
        do {
            let pattern = "%\(text)%"
            let dbCourses: [DBGolfCourse] = try await supabase.from("golf_courses")
                .select()
                .or("name.ilike.\(pattern),city.ilike.\(pattern)")
                .limit(20)
                .execute()
                .value
            results = dbCourses.map { db in
                let loc = [db.city, db.state].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: ", ")
                return Course(
                    id: db.id,
                    name: db.name,
                    location: loc.isEmpty ? db.address : loc,
                    holes: db.holes ?? 18,
                    par: db.par ?? 72,
                    difficulty: db.courseRating ?? 0,
                    hasDrivingRange: false,
                    hasPuttingGreen: false,
                    latitude: db.latitude,
                    longitude: db.longitude,
                    googlePlaceId: db.googlePlaceId,
                    city: db.city,
                    state: db.state
                )
            }
        } catch {
            results = []
        }
    }
}

// MARK: - Podium View

struct PodiumView: View {
    let rankings: [(course: String, location: String)]

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if rankings.count > 1 {
                PodiumItem(
                    rank: 2,
                    name: rankings[1].course,
                    height: 80,
                    color: GolfrColors.textSecondary
                )
            }

            PodiumItem(
                rank: 1,
                name: rankings[0].course,
                height: 110,
                color: GolfrColors.gold
            )

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
        }
        .padding(12)
        .golfrCard(cornerRadius: 12)
    }
}
