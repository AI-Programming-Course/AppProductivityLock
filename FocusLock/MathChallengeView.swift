import SwiftUI

/// Friction before loosening the limit: two-digit addition or subtraction
/// questions, all of which must be answered correctly.
struct MathChallengeView: View {
    let questionCount: Int
    /// Label of the confirm button, e.g. "Turn off limit".
    let actionTitle: String
    let onSuccess: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var questions: [Question]
    @State private var answers: [String]
    @State private var gotOneWrong = false
    @FocusState private var focusedIndex: Int?

    init(questionCount: Int, actionTitle: String, onSuccess: @escaping () -> Void) {
        self.questionCount = questionCount
        self.actionTitle = actionTitle
        self.onSuccess = onSuccess
        _questions = State(initialValue: Question.makeSet(count: questionCount))
        _answers = State(initialValue: Array(repeating: "", count: questionCount))
    }

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
                        Text("Answer all \(questionCount) correctly to continue.")
                    }
                }

                Section {
                    Button(actionTitle, role: .destructive) {
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
            onSuccess()
        } else {
            // A wrong answer means starting over with fresh questions.
            questions = Question.makeSet(count: questionCount)
            answers = Array(repeating: "", count: questionCount)
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

    static func makeSet(count: Int) -> [Question] {
        (0..<count).map { _ in random() }
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
