//
//  ⑯ TimelineView.swift
//  DailyUS
//
//  Created by 陳芸萱 on 2025/12/2.
//

import SwiftUI

// MARK: - Timeline Entry Model

enum TimelineEntryKind: String, Codable, CaseIterable {
    case mood      // 心情
    case dailyQA   // 今日共通問題回答
    case message   // 給對方訊息 / 日記
}

struct TimelineEntry: Identifiable, Hashable, Codable {
    let id: UUID
    let kind: TimelineEntryKind
    let date: Date
    let author: String?      // optional: who wrote this (you/partner)
    let title: String?       // for daily question title, optional
    let content: String?     // text content or note
    let moodScore: Int?      // 0~10 if kind == .mood

    init(
        id: UUID = UUID(),
        kind: TimelineEntryKind,
        date: Date,
        author: String? = nil,
        title: String? = nil,
        content: String? = nil,
        moodScore: Int? = nil
    ) {
        self.id = id
        self.kind = kind
        self.date = date
        self.author = author
        self.title = title
        self.content = content
        self.moodScore = moodScore
    }
}

// MARK: - View

struct TimelineView: View {
    // In a real app, inject entries from your data layer (CloudKit/Firebase/local).
    // Here we provide sample data for preview/testing.
    @State private var entries: [TimelineEntry] = TimelineView.sampleEntries()

    var body: some View {
        ZStack {
            // 背景圖層（如需別張圖，改這裡）
            Background(image: Image("Back_3"))
                .opacity(0.5)

            // 內容圖層
            List {
                // Group entries by day
                ForEach(groupedByDay(entriesSortedDesc)) { section in
                    Section(section.headerTitle) {
                        ForEach(section.items) { item in
                            TimelineRow(entry: item)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden) // 讓 List 背景透明
            .background(Color.clear)          // 顯示底層背景圖
            .navigationTitle("Timeline")
            .toolbar {
                // Example refresh or filter buttons
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("只看心情") { filter(kind: .mood) }
                        Button("只看回答") { filter(kind: .dailyQA) }
                        Button("只看訊息") { filter(kind: .message) }
                        Divider()
                        Button("顯示全部") { resetFilter() }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var entriesSortedDesc: [TimelineEntry] {
        entries.sorted(by: { $0.date > $1.date })
    }

    private func filter(kind: TimelineEntryKind) {
        withAnimation {
            entries = TimelineView.sampleEntries().filter { $0.kind == kind }
        }
    }

    private func resetFilter() {
        withAnimation {
            entries = TimelineView.sampleEntries()
        }
    }

    // Grouping by calendar day
    private func groupedByDay(_ items: [TimelineEntry]) -> [TimelineSection] {
        let cal = Calendar.current
        let groups = Dictionary(grouping: items) { (entry) -> Date in
            cal.startOfDay(for: entry.date)
        }
        .map { (key, value) -> TimelineSection in
            TimelineSection(day: key, items: value.sorted(by: { $0.date > $1.date }))
        }
        .sorted(by: { $0.day > $1.day })

        return groups
    }
}

// MARK: - Timeline Section

private struct TimelineSection: Identifiable {
    let id = UUID()
    let day: Date
    let items: [TimelineEntry]

    var headerTitle: String {
        let today = Date().startOfDay
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!.startOfDay
        if day == today { return "今天" }
        if day == yesterday { return "昨天" }
        return day.formatted(date: .abbreviated, time: .omitted)
    }
}

// MARK: - Row

private struct TimelineRow: View {
    let entry: TimelineEntry

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            icon
                .font(.system(size: 22))
                .frame(width: 28, height: 28)
                .padding(6)
                .background(iconBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(primaryTitle)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer()
                    Text(entry.date.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let subtitle = secondarySubtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                if entry.kind == .mood, let score = entry.moodScore {
                    MoodBar(score: score)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private var primaryTitle: String {
        switch entry.kind {
        case .mood:
            let scoreText = entry.moodScore.map { "\($0)/10" } ?? "-"
            return "心情 \(scoreText)"
        case .dailyQA:
            return entry.title ?? "今日回答"
        case .message:
            return "訊息"
        }
    }

    private var secondarySubtitle: String? {
        var parts: [String] = []
        if let author = entry.author, !author.isEmpty {
            parts.append("by \(author)")
        }
        if let content = entry.content, !content.isEmpty {
            parts.append(content)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private var icon: Image {
        switch entry.kind {
        case .mood: return Image(systemName: "face.smiling")
        case .dailyQA: return Image(systemName: "text.bubble.fill")
        case .message: return Image(systemName: "heart.text.square.fill")
        }
    }

    private var iconBackground: Color {
        switch entry.kind {
        case .mood: return .blue.opacity(0.15)
        case .dailyQA: return .orange.opacity(0.15)
        case .message: return .pink.opacity(0.15)
        }
    }
}

// MARK: - Mood Bar

private struct MoodBar: View {
    let score: Int // 0...10

    var body: some View {
        HStack(spacing: 8) {
            Text("心情")
                .font(.caption)
                .foregroundStyle(.secondary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.15))
                    RoundedRectangle(cornerRadius: 6)
                        .fill(gradientForScore(score))
                        .frame(width: geo.size.width * CGFloat(max(0, min(10, score))) / 10.0)
                        .animation(.easeOut(duration: 0.35), value: score)
                }
            }
            .frame(height: 10)
            Text("\(score)/10")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func gradientForScore(_ s: Int) -> LinearGradient {
        if s >= 8 { return LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing) }
        if s >= 5 { return LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing) }
        return LinearGradient(colors: [.pink, .red], startPoint: .leading, endPoint: .trailing)
    }
}

// MARK: - Utilities & Samples

private extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }
    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
}

extension TimelineView {
    static func sampleEntries() -> [TimelineEntry] {
        let now = Date()
        let you = "You"
        let partner = "Partner"

        return [
            // Today
            TimelineEntry(kind: .mood, date: now.addingTimeInterval(-60*10), author: you, moodScore: 8),
            TimelineEntry(kind: .dailyQA, date: now.addingTimeInterval(-60*30), author: you, title: "今天最想感謝對方的一件事？", content: "幫我泡咖啡，讓我精神滿滿開始一天。"),
            TimelineEntry(kind: .message, date: now.addingTimeInterval(-60*50), author: partner, content: "今晚一起看電影嗎？"),

            // Yesterday
            TimelineEntry(kind: .mood, date: now.adding(days: -1).addingTimeInterval(-60*20), author: partner, moodScore: 6),
            TimelineEntry(kind: .message, date: now.adding(days: -1).addingTimeInterval(-60*40), author: you, content: "今天辛苦了，晚安。"),

            // Two days ago
            TimelineEntry(kind: .dailyQA, date: now.adding(days: -2).addingTimeInterval(-60*15), author: partner, title: "今天最想感謝對方的一件事？", content: "包容我的小脾氣"),
        ]
    }
}

#Preview {
    NavigationStack {
        TimelineView()
    }
}

