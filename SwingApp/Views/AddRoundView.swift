import SwiftUI

struct AddRoundView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var selectedCourse: Course?
    @State private var holes: Int = 18
    @State private var date = Date()
    @State private var notes = ""
    @State private var currentStep = 0
    @State private var holeScores: [HoleScoreEntry] = []
    @State private var isSaving = false
    @State private var saveError: String?

    var totalScore: Int {
        holeScores.reduce(0) { $0 + $1.score }
    }

    var body: some View {
        NavigationView {
            ZStack {
                GolfrColors.backgroundPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Progress indicator (Duolingo-style)
                        ProgressBar(currentStep: currentStep, totalSteps: 4)
                            .padding(.horizontal)
                            .padding(.top, 8)

                        // Step content
                        VStack(spacing: 20) {
                            switch currentStep {
                            case 0:
                                CourseSelectionStep(selectedCourse: $selectedCourse)
                            case 1:
                                HoleSetupStep(holes: $holes, date: $date, holeScores: $holeScores)
                            case 2:
                                HoleByHoleEntryStep(holeScores: $holeScores)
                            case 3:
                                ReviewStep(
                                    courseName: selectedCourse?.name ?? "Select a course",
                                    score: "\(totalScore)",
                                    holes: holes,
                                    date: date,
                                    notes: $notes,
                                    holeScores: holeScores
                                )
                            default:
                                EmptyView()
                            }
                        }
                        .padding(.horizontal)

                        Spacer().frame(height: 140)
                    }
                }

                // Bottom action bar
                VStack {
                    Spacer()

                    HStack(spacing: 12) {
                        if currentStep > 0 {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    currentStep -= 1
                                }
                            }) {
                                Text("Back")
                                    .font(GolfrFonts.headline())
                                    .foregroundColor(GolfrColors.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        Capsule().fill(GolfrColors.backgroundElevated)
                                    )
                            }
                        }

                        Button(action: handlePrimaryAction) {
                            HStack {
                                if isSaving {
                                    ProgressView().tint(.white)
                                } else {
                                    Text(currentStep == 3 ? "Save Round" : "Continue")
                                        .font(GolfrFonts.headline())
                                    Image(systemName: currentStep == 3 ? "checkmark" : "arrow.right")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Capsule().fill(GolfrColors.heroGradient)
                            )
                            .opacity(canAdvance ? 1.0 : 0.5)
                            .shadow(color: GolfrColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(!canAdvance || isSaving)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                    .background(
                        LinearGradient(
                            colors: [GolfrColors.backgroundPrimary.opacity(0), GolfrColors.backgroundPrimary],
                            startPoint: .top,
                            endPoint: .center
                        )
                        .frame(height: 120)
                        .allowsHitTesting(false)
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(GolfrColors.textPrimary)
                            .padding(8)
                            .background(Circle().fill(GolfrColors.backgroundElevated))
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("New Round")
                        .font(GolfrFonts.headline())
                        .foregroundColor(GolfrColors.textPrimary)
                }
            }
            .alert("Couldn't save round", isPresented: errorBinding) {
                Button("OK") { saveError = nil }
            } message: {
                Text(saveError ?? "")
            }
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )
    }

    private var canAdvance: Bool {
        switch currentStep {
        case 0: return selectedCourse != nil
        case 1: return !holeScores.isEmpty
        case 2: return holeScores.allSatisfy { $0.score > 0 }
        case 3: return totalScore > 0
        default: return false
        }
    }

    private func handlePrimaryAction() {
        if currentStep < 3 {
            withAnimation(.easeInOut(duration: 0.25)) {
                currentStep += 1
            }
            return
        }
        guard let course = selectedCourse else { return }

        isSaving = true
        Task {
            // Resolve to a real Supabase course ID
            let courseId = await appViewModel.findOrCreateCourse(from: course)
            let success = await appViewModel.saveRound(
                course: course,
                courseId: courseId,
                score: totalScore,
                date: date,
                notes: notes.isEmpty ? nil : notes,
                holeScores: holeScores
            )
            isSaving = false
            if success {
                dismiss()
            } else {
                saveError = "Something went wrong saving your round. Please try again."
            }
        }
    }
}

// MARK: - Progress Bar (Duolingo-style)

struct ProgressBar: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<totalSteps, id: \.self) { step in
                RoundedRectangle(cornerRadius: 3)
                    .fill(step <= currentStep ? GolfrColors.primaryLight : GolfrColors.textSecondary.opacity(0.15))
                    .frame(height: 6)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
    }
}

// MARK: - Step 1: Course Selection

struct CourseSelectionStep: View {
    @Binding var selectedCourse: Course?
    @State private var searchText = ""
    @State private var courses: [Course] = []
    @State private var isLoading = false
    @State private var searchTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Where did you play?")
                    .font(GolfrFonts.title())
                    .foregroundColor(GolfrColors.textPrimary)
                Text("Search for your course")
                    .font(GolfrFonts.body())
                    .foregroundColor(GolfrColors.textSecondary)
            }

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(GolfrColors.textSecondary)
                TextField("Course name...", text: $searchText)
                    .font(GolfrFonts.body())
                    .onChange(of: searchText) { newValue in
                        scheduleSearch(query: newValue)
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

            if isLoading && courses.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
            } else if courses.isEmpty {
                Text(searchText.isEmpty ? "Type to search courses" : "No courses found")
                    .font(GolfrFonts.callout())
                    .foregroundColor(GolfrColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)
            } else {
                ForEach(courses) { course in
                    Button(action: {
                        selectedCourse = course
                    }) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(selectedCourse?.id == course.id ? GolfrColors.primary.opacity(0.1) : GolfrColors.backgroundElevated)
                                    .frame(width: 44, height: 44)
                                Image(systemName: "figure.golf")
                                    .font(.system(size: 18))
                                    .foregroundColor(selectedCourse?.id == course.id ? GolfrColors.primary : GolfrColors.textSecondary)
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

                            if selectedCourse?.id == course.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(GolfrColors.primaryLight)
                            }
                        }
                        .padding(12)
                        .golfrCard(cornerRadius: 14)
                    }
                }
            }
        }
        .onAppear {
            if courses.isEmpty {
                scheduleSearch(query: "")
            }
        }
    }

    private func scheduleSearch(query: String) {
        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            if Task.isCancelled { return }
            await runSearch(query: query)
        }
    }

    @MainActor
    private func runSearch(query: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            courses = try await GooglePlacesService.shared.searchGolfCourses(query: query)
        } catch {
            print("CourseSelectionStep search failed: \(error)")
            courses = []
        }
    }
}

// MARK: - Step 2: Hole Setup

struct HoleSetupStep: View {
    @Binding var holes: Int
    @Binding var date: Date
    @Binding var holeScores: [HoleScoreEntry]

    let defaultPars18 = [4, 4, 3, 5, 4, 3, 4, 5, 4, 4, 3, 5, 4, 4, 3, 4, 5, 4]
    let defaultPars9 = [4, 4, 3, 5, 4, 3, 4, 5, 4]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Round Setup")
                    .font(GolfrFonts.title())
                    .foregroundColor(GolfrColors.textPrimary)
                Text("Choose holes and date")
                    .font(GolfrFonts.body())
                    .foregroundColor(GolfrColors.textSecondary)
            }

            // Holes toggle
            VStack(alignment: .leading, spacing: 10) {
                Text("Holes Played")
                    .font(GolfrFonts.callout())
                    .foregroundColor(GolfrColors.textSecondary)

                HStack(spacing: 8) {
                    HoleOptionButton(value: 9, selected: holes == 9) {
                        holes = 9
                        initializeHoleScores()
                    }
                    HoleOptionButton(value: 18, selected: holes == 18) {
                        holes = 18
                        initializeHoleScores()
                    }
                }
            }

            // Date picker
            VStack(alignment: .leading, spacing: 10) {
                Text("Date Played")
                    .font(GolfrFonts.callout())
                    .foregroundColor(GolfrColors.textSecondary)

                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .tint(GolfrColors.primary)
            }
        }
        .onAppear {
            if holeScores.isEmpty {
                initializeHoleScores()
            }
        }
    }

    func initializeHoleScores() {
        let pars = holes == 9 ? defaultPars9 : defaultPars18
        holeScores = pars.enumerated().map { index, par in
            HoleScoreEntry(holeNumber: index + 1, par: par, score: par)
        }
    }
}

struct HoleOptionButton: View {
    let value: Int
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("\(value) holes")
                .font(GolfrFonts.headline())
                .foregroundColor(selected ? .white : GolfrColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(selected ? GolfrColors.primary : GolfrColors.backgroundCard)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(selected ? Color.clear : GolfrColors.textSecondary.opacity(0.15), lineWidth: 1)
                )
        }
    }
}

// MARK: - Step 3: Hole-by-Hole Entry

struct HoleByHoleEntryStep: View {
    @Binding var holeScores: [HoleScoreEntry]

    var totalScore: Int {
        holeScores.reduce(0) { $0 + $1.score }
    }

    var totalPar: Int {
        holeScores.reduce(0) { $0 + $1.par }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Enter Your Scores")
                    .font(GolfrFonts.title())
                    .foregroundColor(GolfrColors.textPrimary)
                Text("Tap +/\u{2212} to adjust each hole")
                    .font(GolfrFonts.body())
                    .foregroundColor(GolfrColors.textSecondary)
            }

            // Running total banner
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total")
                        .font(GolfrFonts.caption())
                        .foregroundColor(GolfrColors.textOnDarkMuted)
                    Text("\(totalScore)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(GolfrColors.cream)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("To Par")
                        .font(GolfrFonts.caption())
                        .foregroundColor(GolfrColors.textOnDarkMuted)
                    let diff = totalScore - totalPar
                    Text(diff > 0 ? "+\(diff)" : diff == 0 ? "E" : "\(diff)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(diff <= 0 ? GolfrColors.success : GolfrColors.cream)
                }
            }
            .padding(16)
            .golfrDarkCard()

            // Hole-by-hole grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 10) {
                ForEach($holeScores) { $hole in
                    HoleScoreEntryCard(hole: $hole)
                }
            }
        }
    }
}

struct HoleScoreEntryCard: View {
    @Binding var hole: HoleScoreEntry

    var scoreToPar: Int { hole.score - hole.par }

    var scoreColor: Color { GolfrColors.textPrimary }

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text("H\(hole.holeNumber)")
                    .font(GolfrFonts.caption())
                    .foregroundColor(GolfrColors.textSecondary)
                Spacer()
                Text("P\(hole.par)")
                    .font(GolfrFonts.caption())
                    .foregroundColor(GolfrColors.textSecondary)
            }

            HStack(spacing: 10) {
                Button(action: {
                    if hole.score > 1 { hole.score -= 1 }
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(GolfrColors.textSecondary)
                }

                Text("\(hole.score)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(scoreColor)
                    .frame(minWidth: 28)

                Button(action: {
                    hole.score += 1
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(GolfrColors.primaryLight)
                }
            }
        }
        .padding(10)
        .golfrCard(cornerRadius: 12)
    }
}

// MARK: - Step 4: Review

struct ReviewStep: View {
    let courseName: String
    let score: String
    let holes: Int
    let date: Date
    @Binding var notes: String
    var holeScores: [HoleScoreEntry] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Looking good!")
                    .font(GolfrFonts.title())
                    .foregroundColor(GolfrColors.textPrimary)
                Text("Review and save your round")
                    .font(GolfrFonts.body())
                    .foregroundColor(GolfrColors.textSecondary)
            }

            // Summary card (Phantom-style dark)
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(courseName)
                            .font(GolfrFonts.title3())
                            .foregroundColor(GolfrColors.cream)
                        Text("\(holes) holes")
                            .font(GolfrFonts.caption())
                            .foregroundColor(GolfrColors.textOnDarkMuted)
                    }
                    Spacer()
                    Text(dateString(from: date))
                        .font(GolfrFonts.caption())
                        .foregroundColor(GolfrColors.textOnDarkMuted)
                }

                // Big score
                ZStack {
                    Circle()
                        .fill(GolfrColors.cream.opacity(0.1))
                        .frame(width: 100, height: 100)
                    Circle()
                        .stroke(GolfrColors.cream.opacity(0.3), lineWidth: 3)
                        .frame(width: 100, height: 100)
                    VStack(spacing: 0) {
                        Text(score == "0" ? "--" : score)
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundColor(GolfrColors.cream)
                        Text("score")
                            .font(GolfrFonts.caption())
                            .foregroundColor(GolfrColors.textOnDarkMuted)
                    }
                }
            }
            .padding(20)
            .golfrDarkCard()

            // Hole breakdown (compact)
            if !holeScores.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Hole Breakdown")
                        .font(GolfrFonts.callout())
                        .foregroundColor(GolfrColors.textSecondary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 9), spacing: 6) {
                        ForEach(holeScores) { hole in
                            VStack(spacing: 2) {
                                Text("\(hole.holeNumber)")
                                    .font(.system(size: 9, weight: .medium, design: .rounded))
                                    .foregroundColor(GolfrColors.textSecondary)
                                Text("\(hole.score)")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(GolfrColors.textPrimary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(GolfrColors.backgroundElevated)
                            )
                        }
                    }
                }
            }

            // Notes
            VStack(alignment: .leading, spacing: 8) {
                Text("Notes (optional)")
                    .font(GolfrFonts.callout())
                    .foregroundColor(GolfrColors.textSecondary)

                TextEditor(text: $notes)
                    .font(GolfrFonts.body())
                    .frame(height: 80)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(GolfrColors.backgroundCard)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(GolfrColors.textSecondary.opacity(0.1), lineWidth: 1)
                    )
            }

            // Auto-share notice
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 12))
                    .foregroundColor(GolfrColors.textSecondary)
                Text("Saved rounds appear in your feed automatically.")
                    .font(GolfrFonts.caption())
                    .foregroundColor(GolfrColors.textSecondary)
                Spacer()
            }
            .padding(12)
        }
    }

    func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}
