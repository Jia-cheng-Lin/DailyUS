//
//  ⑥ MoodView.swift
//  DailyUS
//
//  Created by 陳芸萱 on 2025/12/2.
//

import SwiftUI

// MARK: - Cloud saving abstraction (scaffold)
protocol MoodCloudSaving {
    func saveTodayMood(score: Int) async throws
}

// A simple mock saver. Replace with CloudKit/Firebase later.
struct MockMoodCloudSaver: MoodCloudSaving {
    func saveTodayMood(score: Int) async throws {
        // Simulate network delay and success
        try await Task.sleep(nanoseconds: 600_000_000)
    }
}

struct MoodView: View {
    // Shared with dashboard summary
    @AppStorage("todayMood") private var todayMood: Int = 7

    // UI state
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var animPulse: Bool = false
    @State private var isSaving: Bool = false
    @State private var saveMessage: String?
    @State private var saveError: String?

    // Inject cloud saver (swap with real implementation later)
    private var cloudSaver: MoodCloudSaving

    init(cloudSaver: MoodCloudSaving = MockMoodCloudSaver()) {
        self.cloudSaver = cloudSaver
    }

    var body: some View {
        ZStack {
            // 背景圖層
            Background(image: Image("Back_1"))
                .opacity(0.5)

            // 內容圖層
            VStack(spacing: 22) {
                // Header
                VStack(spacing: 6) {
                    Text("今日心情")
                        .font(.title2.bold())
                    Text("拖曳滑桿調整 0–10 分")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                // Emoji + score
                VStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [.yellow.opacity(0.35), .orange.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 140, height: 140)
                            .scaleEffect(reduceMotion ? 1.0 : (animPulse ? 1.06 : 0.94))
                            .animation(reduceMotion ? nil : .easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: animPulse)

                        Text(emoji(for: todayMood))
                            .font(.system(size: 64))
                            .transition(.scale.combined(with: .opacity))
                            .id(todayMood) // trigger transition on change
                    }

                    HStack(spacing: 8) {
                        Text("\(todayMood)")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        Text("/ 10")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    Text(summary(for: todayMood))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)

                // Slider + step controls
                VStack(spacing: 14) {
                    Slider(value: Binding(
                        get: { Double(todayMood) },
                        set: { todayMood = Int($0.rounded()) }
                    ), in: 0...10, step: 1)
                    .tint(.orange)

                    HStack(spacing: 16) {
                        StepButton(symbol: "minus.circle.fill", color: .orange) {
                            todayMood = max(0, todayMood - 1)
                        }
                        .accessibilityLabel("降低心情分數")

                        Spacer()

                        StepButton(symbol: "plus.circle.fill", color: .orange) {
                            todayMood = min(10, todayMood + 1)
                        }
                        .accessibilityLabel("提高心情分數")
                    }
                }
                .padding(.horizontal)

                // Save section
                VStack(spacing: 8) {
                    Button {
                        Task { await saveToCloud() }
                    } label: {
                        HStack(spacing: 8) {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "icloud.and.arrow.up.fill")
                            }
                            Text(isSaving ? "儲存中…" : "儲存到雲端")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundStyle(.white)
                        .background(isSaving ? Color.gray : Color.accentColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .disabled(isSaving)

                    if let saveMessage {
                        Label(saveMessage, systemImage: "checkmark.circle.fill")
                            .font(.footnote)
                            .foregroundStyle(.green)
                            .transition(.opacity)
                    }
                    if let saveError {
                        Label(saveError, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .transition(.opacity)
                    }
                }
                .padding(.top, 4)

                Spacer()
            }
            .padding(20)
        }
        .navigationTitle("Mood")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if !reduceMotion {
                animPulse = true
            }
        }
    }

    // MARK: - Save
    @MainActor
    private func saveToCloud() async {
        saveMessage = nil
        saveError = nil
        isSaving = true
        do {
            try await cloudSaver.saveTodayMood(score: todayMood)
            isSaving = false
            saveMessage = "已同步到雲端"
            // Auto-hide success message
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_400_000_000)
                if saveMessage != nil { withAnimation { saveMessage = nil } }
            }
        } catch {
            isSaving = false
            withAnimation { saveError = "同步失敗，請稍後重試" }
        }
    }

    // MARK: - Helpers
    private func emoji(for score: Int) -> String {
        switch score {
        case 0...1: return "😞"
        case 2...3: return "☹️"
        case 4...5: return "😐"
        case 6...7: return "🙂"
        case 8...9: return "😄"
        default: return "🤩"
        }
    }

    private func summary(for score: Int) -> String {
        switch score {
        case 0...1: return "需要擁抱"
        case 2...3: return "有點低落"
        case 4...5: return "普通的一天"
        case 6...7: return "心情不錯"
        case 8...9: return "超級開心"
        default: return "能量滿滿"
        }
    }
}

// MARK: - Components
private struct StepButton: View {
    let symbol: String
    let color: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(color)
                .clipShape(Circle())
                .shadow(color: color.opacity(0.35), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
    }
}

#Preview {
    NavigationStack {
        MoodView()
    }
}

