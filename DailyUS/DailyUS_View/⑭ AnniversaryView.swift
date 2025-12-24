//
//  ⑭ AnniversaryView.swift
//  DailyUS
//
//  Created by 陳芸萱 on 2025/12/2.
//

import SwiftUI

struct AnniversaryView: View {
    // 用 TimeInterval 存日期避免 AppStorage 編碼問題
    @AppStorage("anniversaryStartDate") private var anniversaryStartDate: Double = Date().timeIntervalSince1970

    @State private var date: Date = Date()
    @State private var pulse: Bool = false

    // 計算在一起天數（以當地日曆的當天起始為準，避免跨時區/時間誤差）
    private var daysTogether: Int {
        let start = Date(timeIntervalSince1970: anniversaryStartDate).startOfDay
        let today = Date().startOfDay
        return max(0, Calendar.current.dateComponents([.day], from: start, to: today).day ?? 0)
    }

    // 計算下一個週年資訊（標題與倒數天數）
    private var nextAnniversaryInfo: (title: String, daysLeft: Int)? {
        let start = Date(timeIntervalSince1970: anniversaryStartDate)
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: start)
        guard let m = comps.month, let d = comps.day else { return nil }

        let today = Date()
        let thisYear = cal.component(.year, from: today)

        // 本年度的週年日
        let thisYearDate = cal.date(from: DateComponents(year: thisYear, month: m, day: d)) ?? start
        // 若本年度週年已過，則取下一年度
        let target = (thisYearDate >= today.startOfDay)
            ? thisYearDate
            : cal.date(from: DateComponents(year: thisYear + 1, month: m, day: d)) ?? thisYearDate

        let left = max(0, cal.dateComponents([.day], from: today.startOfDay, to: target.startOfDay).day ?? 0)
        let years = max(1, cal.dateComponents([.year], from: start.startOfDay, to: target.startOfDay).year ?? 1)
        return ("第 \(years) 週年", left)
    }

    var body: some View {
        ZStack {
            // 背景圖層（使用 Back_3）
            Background(image: Image("Back_3")).opacity(0.5)

            // 內容圖層（Form）
            Form {
                Section("設定紀念日") {
                    DatePicker("在一起日期", selection: $date, displayedComponents: .date)
                        .onChange(of: date) { _, newValue in
                            anniversaryStartDate = newValue.timeIntervalSince1970
                        }
                        .accessibilityLabel("在一起日期")
                        .accessibilityHint("選擇你們在一起的日期")

                    Text("目前設定：\(Date(timeIntervalSince1970: anniversaryStartDate).formatted(date: .abbreviated, time: .omitted))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("目前設定日期")
                }

                Section("倒數與動畫") {
                    VStack(spacing: 16) {
                        if let next = nextAnniversaryInfo {
                            Text("\(next.title) 倒數 \(next.daysLeft) 天")
                                .font(.headline)
                                .accessibilityLabel("\(next.title) 倒數 \(next.daysLeft) 天")
                        }

                        Text("在一起第 \(daysTogether) 天")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("在一起第 \(daysTogether) 天")

                        // Love 動畫區塊
                        ZStack {
                            Circle()
                                .fill(.pink.opacity(0.25))
                                .frame(width: 120, height: 120)
                                .scaleEffect(pulse ? 1.1 : 0.9)
                                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)

                            Image(systemName: "heart.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.pink)
                                .scaleEffect(pulse ? 1.05 : 0.95)
                                .animation(.spring(response: 0.6, dampingFraction: 0.6).repeatForever(autoreverses: true), value: pulse)
                                .accessibilityHidden(true)
                        }
                        .frame(maxWidth: .infinity)
                        .onAppear { pulse = true }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
                }
            }
            // 讓表單背景透明，顯示底層背景圖
            .scrollContentBackground(.hidden)
            .background(Color.clear)
        }
        .navigationTitle("Anniversary")
        .onAppear {
            // 進入畫面時，將 DatePicker 顯示為目前儲存的日期
            date = Date(timeIntervalSince1970: anniversaryStartDate)
        }
    }
}

private extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }
}

#Preview {
    NavigationStack {
        AnniversaryView()
    }
}
