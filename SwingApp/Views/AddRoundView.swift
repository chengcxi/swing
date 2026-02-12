import SwiftUI

struct AddRoundView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedCourse = ""
    @State private var score = ""
    @State private var holes: Int = 18
    @State private var date = Date()
    @State private var notes = ""
    @State private var currentStep = 0

    var body: some View {
        NavigationView {
            ZStack {
                GolfrColors.backgroundPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Progress indicator (Duolingo-style)
                        ProgressBar(currentStep: currentStep, totalSteps: 3)
                            .padding(.horizontal)
                            .padding(.top, 8)

                        // Step content
                        VStack(spacing: 20) {
                            switch currentStep {
                            case 0:
                                CourseSelectionStep(selectedCourse: $selectedCourse)
                            case 1:
                                ScoreEntryStep(score: $score, holes: $holes, date: $date)
                            case 2:
                                ReviewStep(
                                    courseName: selectedCourse.isEmpty ? "Select a course" : selectedCourse,
                                    score: score,
                                    holes: holes,
                                    date: date,
                                    notes: $notes
                                )
                            default:
                                EmptyView()
                            }
                        }
                        .padding(.horizontal)

                        Spacer().frame(height: 40)
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

                        Button(action: {
                            if currentStep < 2 {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    currentStep += 1
                                }
                            } else {
                                // Submit round
                                dismiss()
                            }
                        }) {
                            HStack {
                                Text(currentStep == 2 ? "Save Round" : "Continue")
                                    .font(GolfrFonts.headline())
                                if currentStep < 2 {
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14, weight: .semibold))
                                } else {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Capsule().fill(GolfrColors.heroGradient)
                            )
                            .shadow(color: GolfrColors.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
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
    @Binding var selectedCourse: String
    @State private var searchText = ""

    let courses = Course.mocks

    var filteredCourses: [Course] {
        if searchText.isEmpty { return courses }
        return courses.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

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

            // Search
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(GolfrColors.textSecondary)
                TextField("Course name...", text: $searchText)
                    .font(GolfrFonts.body())
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

            // Course options
            ForEach(filteredCourses) { course in
                Button(action: {
                    selectedCourse = course.name
                }) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(selectedCourse == course.name ? GolfrColors.primary.opacity(0.1) : GolfrColors.backgroundElevated)
                                .frame(width: 44, height: 44)
                            Image(systemName: "figure.golf")
                                .font(.system(size: 18))
                                .foregroundColor(selectedCourse == course.name ? GolfrColors.primary : GolfrColors.textSecondary)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(course.name)
                                .font(GolfrFonts.headline())
                                .foregroundColor(GolfrColors.textPrimary)
                            Text(course.location)
                                .font(GolfrFonts.caption())
                                .foregroundColor(GolfrColors.textSecondary)
                        }

                        Spacer()

                        if selectedCourse == course.name {
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
}

// MARK: - Step 2: Score Entry

struct ScoreEntryStep: View {
    @Binding var score: String
    @Binding var holes: Int
    @Binding var date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Text("How'd you play?")
                    .font(GolfrFonts.title())
                    .foregroundColor(GolfrColors.textPrimary)
                Text("Enter your round details")
                    .font(GolfrFonts.body())
                    .foregroundColor(GolfrColors.textSecondary)
            }

            // Score input (big prominent entry)
            VStack(spacing: 8) {
                Text("Total Score")
                    .font(GolfrFonts.caption())
                    .foregroundColor(GolfrColors.textSecondary)

                TextField("72", text: $score)
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(GolfrColors.primary)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .frame(maxWidth: .infinity)
            }
            .padding(24)
            .golfrCard(cornerRadius: 20)

            // Holes toggle
            VStack(alignment: .leading, spacing: 10) {
                Text("Holes Played")
                    .font(GolfrFonts.callout())
                    .foregroundColor(GolfrColors.textSecondary)

                HStack(spacing: 8) {
                    HoleOptionButton(value: 9, selected: holes == 9) {
                        holes = 9
                    }
                    HoleOptionButton(value: 18, selected: holes == 18) {
                        holes = 18
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

// MARK: - Step 3: Review

struct ReviewStep: View {
    let courseName: String
    let score: String
    let holes: Int
    let date: Date
    @Binding var notes: String

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
                        Text(score.isEmpty ? "--" : score)
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

            // Share toggle
            HStack {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 14))
                    .foregroundColor(GolfrColors.primaryLight)
                Text("Share to feed")
                    .font(GolfrFonts.callout())
                    .foregroundColor(GolfrColors.textPrimary)
                Spacer()
                Toggle("", isOn: .constant(true))
                    .tint(GolfrColors.primaryLight)
                    .labelsHidden()
            }
            .padding(14)
            .golfrCard(cornerRadius: 12)
        }
    }

    func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}
