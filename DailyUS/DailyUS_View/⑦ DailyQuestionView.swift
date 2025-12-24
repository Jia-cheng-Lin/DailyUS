//
//  ⑦ DailyQuestionView.swift
//  DailyUS
//
//  Created by 陳芸萱 on 2025/12/2.
//

import SwiftUI

// MARK: - Cloud sync abstraction (scaffold)
protocol DailyQuestionSyncing {
    func fetchTodayQuestion() async throws -> DailyQuestion
    func submitMyAnswer(_ answer: String) async throws
    func fetchPartnerAnswer() async throws -> String?
}

// Simple mock implementation. Replace with CloudKit/Firebase later.
struct MockDailyQuestionSync: DailyQuestionSyncing {
    private let sampleQuestions: [DailyQuestion] = [
        .init(id: "q1", title: "今天最想感謝對方的一件事是什麼？", kind: .text),
        .init(id: "q2", title: "今晚想一起做什麼？", kind: .choice(["看電影", "散步", "煮晚餐", "早睡"]))
    ]

    func fetchTodayQuestion() async throws -> DailyQuestion {
        try await Task.sleep(nanoseconds: 250_000_000)
        // Choose one deterministically by day
        let day = Calendar.current.component(.day, from: Date())
        return sampleQuestions[day % sampleQuestions.count]
    }

    func submitMyAnswer(_ answer: String) async throws {
        try await Task.sleep(nanoseconds: 350_000_000)
        // No-op for mock
    }

    func fetchPartnerAnswer() async throws -> String? {
        try await Task.sleep(nanoseconds: 300_000_000)
        // Randomly return an answer to simulate partner sync
        let candidates = ["看電影", "散步", "煮晚餐", "早睡", nil]
        return candidates.randomElement() ?? nil
    }
}

// MARK: - Model
struct DailyQuestion: Equatable {
    enum Kind: Equatable {
        case text
        case choice([String])
    }
    let id: String
    let title: String
    let kind: Kind
}

// MARK: - View
struct DailyQuestionView: View {
    // Persist my answer locally for the day (keyed by date string)
    @AppStorage("dq_myAnswer_dateKey") private var storedDateKey: String = ""
    @AppStorage("dq_myAnswer_value") private var storedMyAnswer: String = ""

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // UI state
    @State private var isLoading: Bool = true
    @State private var isSubmitting: Bool = false
    @State private var loadError: String?
    @State private var submitError: String?

    @State private var question: DailyQuestion?
    @State private var myTextAnswer: String = ""
    @State private var myChoiceIndex: Int = 0

    @State private var partnerAnswer: String?
    @State private var isRefreshingPartner: Bool = false

    // Animation
    @State private var pulse: Bool = false

    // Inject sync service
    private var sync: DailyQuestionSyncing

    init(sync: DailyQuestionSyncing = MockDailyQuestionSync()) {
        self.sync = sync
    }

    var body: some View {
        ZStack {
            // 背景圖層
            Background(image: Image("Back_1"))
                .opacity(0.5)

            // 內容圖層
            VStack(spacing: 18) {
                header

                content

                Spacer(minLength: 0)

                footer
            }
            .padding(20)
        }
        .navigationTitle("今日共通問題")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await load()
        }
        .onAppear {
            if !reduceMotion { pulse = true }
        }
    }

    // MARK: - Sections
    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 46, height: 46)
                    .scaleEffect(reduceMotion ? 1.0 : (pulse ? 1.05 : 0.95))
                    .animation(reduceMotion ? nil : .easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
                Image(systemName: "text.bubble")
                    .foregroundStyle(.blue)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("今日共通問題")
                    .font(.headline)
                if let question {
                    Text(question.title)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            VStack(spacing: 8) {
                ProgressView("載入中…")
                if let loadError {
                    Text(loadError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 160)
        } else if let q = question {
            VStack(alignment: .leading, spacing: 14) {
                Text(q.title)
                    .font(.title3.bold())

                switch q.kind {
                case .text:
                    TextField("輸入你的回答", text: $myTextAnswer, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3, reservesSpace: true)

                case .choice(let options):
                    VStack(alignment: .leading, spacing: 8) {
                        Picker("選擇你的回答", selection: $myChoiceIndex) {
                            ForEach(options.indices, id: \.self) { i in
                                Text(options[i]).tag(i)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onAppear {
                            if myChoiceIndex >= options.count { myChoiceIndex = 0 }
                        }
                    }
                }

                partnerSection
            }
        } else {
            Text("尚未取得題目，稍後再試。")
                .foregroundStyle(.secondary)
        }
    }

    private var partnerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("對方的回答", systemImage: "person.2.fill")
                    .foregroundStyle(.secondary)
                Spacer()
                if isRefreshingPartner {
                    ProgressView().scaleEffect(0.9)
                }
                Button {
                    Task { await refreshPartner() }
                } label: {
                    Label("同步", systemImage: "arrow.clockwise")
                }
                .disabled(isRefreshingPartner)
            }
            Group {
                if let partnerAnswer {
                    Text(partnerAnswer)
                        .font(.body)
                } else {
                    Text("尚未取得對方回答")
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 4)
        }
        .padding(.top, 6)
    }

    private var footer: some View {
        VStack(spacing: 8) {
            if let submitError {
                Text(submitError)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
            Button {
                Task { await submit() }
            } label: {
                HStack(spacing: 8) {
                    if isSubmitting {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "icloud.and.arrow.up.fill")
                    }
                    Text(isSubmitting ? "送出中…" : "送出我的回答")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .foregroundStyle(.white)
                .background(isSubmitting ? Color.gray : Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(isSubmitting || !canSubmit)
        }
    }

    // MARK: - Logic
    private var todayKey: String {
        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: Date())
    }

    private var canSubmit: Bool {
        guard let q = question else { return false }
        switch q.kind {
        case .text:
            return !myTextAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .choice(let options):
            return options.indices.contains(myChoiceIndex)
        }
    }

    @MainActor
    private func load() async {
        isLoading = true
        loadError = nil
        do {
            let q = try await sync.fetchTodayQuestion()
            self.question = q

            // Restore my local answer if the date matches
            if storedDateKey == todayKey, !storedMyAnswer.isEmpty {
                if case .text = q.kind {
                    myTextAnswer = storedMyAnswer
                } else if case .choice(let options) = q.kind {
                    if let idx = options.firstIndex(of: storedMyAnswer) {
                        myChoiceIndex = idx
                    }
                }
            }

            // Try to fetch partner answer
            partnerAnswer = try await sync.fetchPartnerAnswer()
            isLoading = false
        } catch {
            loadError = "載入失敗，請稍後再試"
            isLoading = false
        }
    }

    @MainActor
    private func submit() async {
        guard let q = question else { return }
        submitError = nil
        isSubmitting = true
        do {
            let answer: String
            switch q.kind {
            case .text:
                answer = myTextAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
            case .choice(let options):
                guard options.indices.contains(myChoiceIndex) else { throw SubmitError.invalid }
                answer = options[myChoiceIndex]
            }

            try await sync.submitMyAnswer(answer)

            // Persist locally for the day
            storedDateKey = todayKey
            storedMyAnswer = answer

            // Refresh partner’s answer after submit
            partnerAnswer = try await sync.fetchPartnerAnswer()

            isSubmitting = false
        } catch {
            isSubmitting = false
            submitError = "提交失敗，請稍後重試"
        }
    }

    @MainActor
    private func refreshPartner() async {
        isRefreshingPartner = true
        do {
            partnerAnswer = try await sync.fetchPartnerAnswer()
            isRefreshingPartner = false
        } catch {
            isRefreshingPartner = false
        }
    }

    enum SubmitError: Error { case invalid }
}

#Preview {
    NavigationStack {
        DailyQuestionView()
    }
}

