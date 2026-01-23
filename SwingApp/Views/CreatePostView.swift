import SwiftUI

struct CreatePostView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var feedViewModel: FeedViewModel
    @State private var content = ""
    @State private var attachRound = false
    
    // Manual Round Input State
    @State private var courseName = ""
    @State private var totalScore = 72
    @State private var inputMode: InputMode = .total
    @State private var holeScores: [Int] = Array(repeating: 4, count: 18)
    
    enum InputMode: String, CaseIterable {
        case total = "Total Score"
        case holes = "Hole by Hole"
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Post") {
                    TextEditor(text: $content)
                        .frame(height: 100)
                }
                
                Section {
                    Toggle("Attach Round", isOn: $attachRound)
                }
                
                if attachRound {
                    Section("Round Details") {
                        TextField("Course Name", text: $courseName)
                        
                        Picker("Input Mode", selection: $inputMode) {
                            ForEach(InputMode.allCases, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        
                        if inputMode == .total {
                            Stepper("Score: \(totalScore)", value: $totalScore)
                        } else {
                            ScrollView(.horizontal) {
                                HStack {
                                    ForEach(0..<18) { i in
                                        VStack {
                                            Text("\(i+1)")
                                                .font(.caption)
                                            TextField("", value: $holeScores[i], formatter: NumberFormatter())
                                                .keyboardType(.numberPad)
                                                .frame(width: 30)
                                                .multilineTextAlignment(.center)
                                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Post")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") {
                        var round: GolfRound? = nil
                        if attachRound {
                            round = GolfRound(
                                courseName: courseName,
                                location: "Unknown",
                                holes: 18,
                                date: Date().description,
                                score: inputMode == .total ? totalScore : holeScores.reduce(0, +),
                                holeScores: inputMode == .holes ? holeScores : nil
                            )
                        }
                        
                        feedViewModel.addPost(content: content, round: round)
                        dismiss()
                    }
                    .disabled(content.isEmpty)
                }
            }
        }
    }
}
