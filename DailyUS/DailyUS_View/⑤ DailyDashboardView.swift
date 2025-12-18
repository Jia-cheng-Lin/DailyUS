//
//  ⑤ DailyDashboardView.swift
//  DailyUS
//
//  Created by 陳芸萱 on 2025/12/2.
//

import SwiftUI

struct DailyDashboardView: View {
    // Persist a simple mood score locally for summary (0...10)
    @AppStorage("todayMood") private var todayMood: Int = 7

    // Accessibility: respect reduced motion
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Simple pulse animation toggle
    @State private var pulse: Bool = false
    @State private var rotate: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 增加與 large title 的安全間距，避免「Daily」壓到「今日心情」
                    Spacer(minLength: 30)

                    moodSummaryCard

                    // Four daily subpages
                    tilesGrid
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .navigationTitle("Daily")
            .navigationBarTitleDisplayMode(.large) // 保持大標題，如要更緊湊可改 .inline
            .onAppear {
                if !reduceMotion {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        pulse = true
                    }
                    withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                        rotate = true
                    }
                }
            }
        }
        .background(Color.clear)
    }

    // MARK: - Mood Summary
    private var moodSummaryCard: some View {
        Button {
            // Navigate to MoodPage via NavigationStack link
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.yellow.opacity(0.5), .orange], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 58, height: 58)
                        .scaleEffect(reduceMotion ? 1.0 : (pulse ? 1.06 : 0.94))

                    // Animated small icon
                    Image(systemName: "face.smiling")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.white)
                        .rotationEffect(.degrees(reduceMotion ? 0 : (rotate ? 360 : 0)))
                        .animation(reduceMotion ? nil : .linear(duration: 4.0).repeatForever(autoreverses: false), value: rotate)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("今日心情")
                        .font(.headline)
                    HStack(spacing: 8) {
                        Text("\(emoji(for: todayMood))")
                            .font(.title2)
                        Text(summaryText(for: todayMood))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Score bubble
                Text("\(todayMood)/10")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.yellow.opacity(0.2))
                    )
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .buttonStyle(.plain)
        .overlay(
            NavigationLink(destination: MoodView()) {
                EmptyView()
            }
            .opacity(0) // Invisible link to allow the whole card to navigate
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("今日心情 \(todayMood) 分 \(summaryText(for: todayMood))")
    }

    // MARK: - Tiles Grid
    private var tilesGrid: some View {
        let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
        return LazyVGrid(columns: columns, spacing: 12) {
            // Mood
            NavigationLink {
                MoodView()
            } label: {
                tile(
                    title: "心情",
                    subtitle: "紀錄 0-10",
                    systemImage: "face.smiling",
                    tint: .yellow
                )
            }

            // Daily Question
            NavigationLink {
                DailyQuestionView()
            } label: {
                tile(
                    title: "今日問題",
                    subtitle: "回答彼此",
                    systemImage: "text.bubble",
                    tint: .blue
                )
            }

            // Message
            NavigationLink {
                MessageView()
            } label: {
                tile(
                    title: "給對方訊息",
                    subtitle: "傳達心意",
                    systemImage: "paperplane.fill",
                    tint: .green
                )
            }

            // Soul Card
            NavigationLink {
                SoulCardView()
            } label: {
                tile(
                    title: "心靈小卡",
                    subtitle: "抽張卡片",
                    systemImage: "sparkles",
                    tint: .purple
                )
            }
        }
        .padding(.top, 4)
    }

    private func tile(title: String, subtitle: String, systemImage: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(tint.opacity(0.18))
                        .frame(width: 44, height: 44)
                        .scaleEffect(reduceMotion ? 1.0 : (pulse ? 1.05 : 0.95))
                        .animation(reduceMotion ? nil : .easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)

                    Image(systemName: systemImage)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(tint)
                        .rotationEffect(.degrees(reduceMotion ? 0 : (rotate ? 360 : 0)))
                        .animation(reduceMotion ? nil : .linear(duration: 6.0).repeatForever(autoreverses: false), value: rotate)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title)。\(subtitle)")
    }

    // MARK: - Helpers
    private func emoji(for score: Int) -> String {
        switch score {
        case ..<2: return "😞"
        case 2...3: return "☹️"
        case 4...6: return "😐"
        case 7...8: return "🙂"
        default: return "😄"
        }
    }

    private func summaryText(for score: Int) -> String {
        switch score {
        case ..<2: return "需要擁抱"
        case 2...3: return "有點低落"
        case 4...6: return "普通的一天"
        case 7...8: return "心情不錯"
        default: return "超級開心"
        }
    }
}

#Preview {
    DailyDashboardView()
}

