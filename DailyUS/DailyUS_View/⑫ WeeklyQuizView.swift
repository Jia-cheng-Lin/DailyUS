//
//  ⑫ WeeklyQuizView.swift
//  DailyUS
//
//  Created by 陳芸萱 on 2025/12/2.
//

import SwiftUI

struct WeeklyQuizView: View {
    // Weekly question – in a real app this could come from cloud/remote config
    var question: String = "你們理想的假日約會是？"

    // Persist last my answer and last score
    @AppStorage("weeklyQuiz_myAnswer") private var storedMyAnswer: String = ""
    @AppStorage("weeklyQuiz_partnerAnswer") private var storedPartnerAnswer: String = ""
    @AppStorage("weeklyQuiz_lastScore") private var storedLastScore: Int = -1

    // Local UI state
    @State private var myAnswer: String = ""
    @State private var partnerAnswer: String = ""
    @State private var score: Int?
    @State private var simulatePartner: Bool = true
    @State private var isComparing: Bool = false

    // Suggested partner answers for simulation
    private let samples = ["看電影", "野餐", "爬山", "在家煮飯", "逛展覽", "咖啡廳閱讀", "海邊散步"]

    var body: some View {
        ZStack {
            // 背景圖層
            Background(image: Image("Back_5"))
                .opacity(0.5)

            // 內容圖層
            Form {
                Section("本週題目") {
                    Text(question)
                        .font(.headline)
                    if storedLastScore >= 0 {
                        HStack {
                            Label("上次默契分數", systemImage: "clock.arrow.circlepath")
                            Spacer()
                            Text("\(storedLastScore)%")
                                .bold()
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }

                Section("你的回答") {
                    TextField("輸入你的答案", text: $myAnswer)
                        .textInputAutocapitalization(.none)
                        .autocorrectionDisabled()
                }

                Section("對方回答來源") {
                    Toggle("使用模擬回答", isOn: $simulatePartner)
                    if simulatePartner {
                        HStack {
                            Text("模擬回答")
                            Spacer()
                            Text(partnerAnswer.isEmpty ? "尚未產生" : partnerAnswer)
                                .foregroundStyle(.secondary)
                        }
                        Button("產生模擬回答") {
                            partnerAnswer = samples.randomElement() ?? "看電影"
                        }
                    } else {
                        TextField("輸入對方的答案", text: $partnerAnswer)
                            .textInputAutocapitalization(.none)
                            .autocorrectionDisabled()
                    }
                }

                Section {
                    Button {
                        Task { await compareNow() }
                    } label: {
                        if isComparing {
                            ProgressView()
                        } else {
                            Label("提交並比較", systemImage: "checkmark.seal.fill")
                        }
                    }
                    .disabled(myAnswer.trimmed.isEmpty || partnerAnswer.trimmed.isEmpty || isComparing)
                }

                if let s = score {
                    Section("默契結果") {
                        HStack {
                            Text("默契百分比")
                            Spacer()
                            Text("\(s)%")
                                .bold()
                        }
                        Gauge(value: Double(s), in: 0...100) {
                            Text("默契")
                        } currentValueLabel: {
                            Text("\(s)%")
                        }
                        .tint(gradientForScore(s))

                        Text(feedbackText(for: s))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            // 讓表單背景透明，顯示底層背景圖
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            // 在頂部加入安全區域 inset，避免被大標題壓住
            .safeAreaInset(edge: .top) {
                Color.clear.frame(height: 30) // 可調整 12~24
            }
        }
        .navigationTitle("Weekly Quiz")
        .onAppear {
            // Load last session into current editing fields for convenience
            if myAnswer.isEmpty { myAnswer = storedMyAnswer }
            if partnerAnswer.isEmpty { partnerAnswer = storedPartnerAnswer }
        }
    }

    @MainActor
    private func compareNow() async {
        isComparing = true
        // Simulate a short processing delay
        try? await Task.sleep(nanoseconds: 350_000_000)

        let s = similarityPercent(a: myAnswer.trimmed, b: partnerAnswer.trimmed)
        score = s

        // Persist last
        storedMyAnswer = myAnswer
        storedPartnerAnswer = partnerAnswer
        storedLastScore = s

        isComparing = false
    }

    // Simple similarity metric:
    // - If exactly equal → 100
    // - Else compute character overlap ratio as a heuristic
    private func similarityPercent(a: String, b: String) -> Int {
        if a == b { return 100 }
        if a.isEmpty || b.isEmpty { return 0 }

        // Use lowercased to reduce case sensitivity
        let aSet = Set(a.lowercased())
        let bSet = Set(b.lowercased())
        let inter = aSet.intersection(bSet).count
        let union = aSet.union(bSet).count
        guard union > 0 else { return 0 }
        let jaccard = Double(inter) / Double(union)
        // Map to 0...92 baseline, then add small bonus for prefix match
        var base = Int((jaccard * 92.0).rounded())
        if a.lowercased().hasPrefix(b.lowercased()) || b.lowercased().hasPrefix(a.lowercased()) {
            base = min(100, base + 6)
        }
        return max(0, min(100, base))
    }

    private func gradientForScore(_ s: Int) -> Gradient {
        if s >= 80 { return Gradient(colors: [.green, .mint]) }
        if s >= 50 { return Gradient(colors: [.yellow, .orange]) }
        return Gradient(colors: [.pink, .red])
    }

    private func feedbackText(for s: Int) -> String {
        switch s {
        case 90...100: return "心有靈犀一點通！超高默契！"
        case 70..<90:  return "默契不錯，再更了解彼此就更完美了。"
        case 40..<70:  return "有些共鳴，試著多分享彼此的想法。"
        default:       return "先別氣餒！從今天開始慢慢培養默契吧。"
        }
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}

#Preview {
    NavigationStack {
        WeeklyQuizView()
    }
}
