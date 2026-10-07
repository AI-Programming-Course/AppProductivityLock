import SwiftUI

/// Friction before turning the limit off: three two-digit addition or
/// subtraction questions, all of which must be answered correctly.
struct UnlockChallengeView: View {
    let onUnlock: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var questions = Question.makeSet()
    @State private var answers = ["", "", ""]
    @State private var gotOneWrong = false
    @FocusState private var focusedIndex: Int?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(questions.indices, id: \.self) { index in
                        HStack {
                            Text(questions[index].text)
                                .font(.title3)
                                .monospacedDigit()
                            Spacer()
                            TextField("?", text: $answers[index])
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .font(.title3)
                                .monospacedDigit()
                                .frame(width: 90)
                                .focused($focusedIndex, equals: index)
                        }
                    }
                } footer: {
                    if gotOneWrong {
                        Text("Not quite. Here are new questions.")
                            .foregroundStyle(.red)
                    } else {
                        Text("Answer all three correctly to turn off the limit.")
                    }
                }

                Section {
                    Button("Turn off limit", role: .destructive) {
                        check()
                    }
                    .disabled(answers.contains { $0.isEmpty })
                }
            }
            .navigationTitle("Are you sure?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear { focusedIndex = 0 }
        }
    }

    private func check() {
        let allCorrect = zip(questions, answers).allSatisfy { question, answer in
            Int(answer) == question.answer
        }
        if allCorrect {
            dismiss()
            onUnlock()
        } else {
            // A wrong answer means starting over with fresh questions.
            questions = Question.makeSet()
            answers = ["", "", ""]
            gotOneWrong = true
            focusedIndex = 0
        }
    }
}

private struct Question {
    let left: Int
    let right: Int
    let isAddition: Bool

    var text: String { "\(left) \(isAddition ? "+" : "−") \(right) =" }
    var answer: Int { isAddition ? left + right : left - right }

    static func makeSet() -> [Question] {
        (0..<3).map { _ in random() }
    }

    /// Two-digit operands; subtraction never goes below zero, so the number pad is enough.
    private static func random() -> Question {
        let a = Int.random(in: 10...99)
        let b = Int.random(in: 10...99)
        if Bool.random() {
            return Question(left: a, right: b, isAddition: true)
        }
        return Question(left: max(a, b), right: min(a, b), isAddition: false)
    }
}
