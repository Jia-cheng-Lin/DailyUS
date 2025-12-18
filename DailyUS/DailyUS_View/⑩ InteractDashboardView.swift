//
//  ⑩ InteractDashboardView.swift
//  DailyUS
//
//  Created by 陳芸萱 on 2025/12/2.
//

import SwiftUI

struct InteractDashboardView: View {
    // 動畫與無障礙
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse: Bool = false
    @State private var rotate: Bool = false

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header

                LazyVGrid(columns: columns, spacing: 12) {
                    // 愛心互動 → 使用正式的 HeartTapView（⑪）
                    NavigationLink {
                        HeartTapView()
                    } label: {
                        tile(
                            title: "愛心",
                            subtitle: "傳遞暖心小互動",
                            systemImage: "heart.fill",
                            tint: .pink
                        )
                    }

                    // 默契互動 → 使用正式的 WeeklyQuizView（⑫）
                    NavigationLink {
                        WeeklyQuizView()
                    } label: {
                        tile(
                            title: "默契",
                            subtitle: "小遊戲測默契",
                            systemImage: "hands.clap.fill",
                            tint: .purple
                        )
                    }
                }
                .padding(.top, 4)
            }
            .padding(.horizontal, 16)
            .padding(.top, 50)
            .padding(.bottom, 24)
        }
        .scrollContentBackground(.hidden) // 隱藏滾動內容背景
        .background(Color.clear)          // 頁面背景透明
        .navigationTitle("互動")
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
            withAnimation(.linear(duration: 6.0).repeatForever(autoreverses: false)) {
                rotate = true
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.pink.opacity(0.18))
                    .frame(width: 48, height: 48)
                    .scaleEffect(reduceMotion ? 1.0 : (pulse ? 1.06 : 0.94))
                    .animation(reduceMotion ? nil : .easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
                Image(systemName: "sparkles")
                    .foregroundStyle(.pink)
                    .rotationEffect(.degrees(reduceMotion ? 0 : (rotate ? 360 : 0)))
                    .animation(reduceMotion ? nil : .linear(duration: 6.0).repeatForever(autoreverses: false), value: rotate)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("互動儀表板")
                    .font(.headline)
                Text("用愛心與默契，增進彼此連結")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    // MARK: - Tile
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
}

#Preview {
    NavigationStack {
        InteractDashboardView()
    }
}

