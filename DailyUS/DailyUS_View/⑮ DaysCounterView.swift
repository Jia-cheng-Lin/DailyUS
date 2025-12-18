//
//  ⑮ DaysCounterView.swift
//  DailyUS
//
//  Created by 陳芸萱 on 2025/12/2.
//

import SwiftUI

struct DaysCounterView: View {
    // Persisted start date (timeInterval) shared with AnniversaryView
    @AppStorage("anniversaryStartDate") private var anniversaryStartDate: Double = Date().timeIntervalSince1970

    // Normalize to start of day to avoid time-of-day drift
    private var rawStartDate: Date { Date(timeIntervalSince1970: anniversaryStartDate) }
    private var startDate: Date { min(rawStartDate.startOfDay, Date().startOfDay) }
    private var today: Date { Date().startOfDay }

    private var days: Int {
        max(0, Calendar.current.dateComponents([.day], from: startDate, to: today).day ?? 0)
    }

    private var ymd: DateComponents {
        Calendar.current.dateComponents([.year, .month, .day], from: startDate, to: today)
    }

    @State private var emphasize: Bool = false

    var body: some View {
        ZStack {
            // 背景圖層（Back_3，半透明）
            Background(image: Image("Back_3"))
                .opacity(0.5)

            // 內容圖層
            VStack(spacing: 16) {
                Text("起始日：\(startDate.formatted(date: .abbreviated, time: .omitted))")
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("起始日 \(startDate.formatted(date: .complete, time: .omitted))")

                Text("在一起第")
                    .font(.headline)

                Text("\(days) 天")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.pink)
                    .scaleEffect(emphasize ? 1.06 : 1.0)
                    .animation(.spring(response: 0.45, dampingFraction: 0.7), value: emphasize)
                    .accessibilityLabel("在一起第 \(days) 天")

                if let y = ymd.year, let m = ymd.month, let d = ymd.day {
                    Text("約 \(y) 年 \(m) 個月 \(d) 天")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("約 \(y) 年 \(m) 個月 \(d) 天")
                }
                

                Spacer()
            }
            .padding(.top, 100)
        }
        .navigationTitle("Together Days")
        .onAppear {
            // Animate the day count once on appear
            emphasize = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                emphasize = false
            }
        }
    }
}

private extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }
}

#Preview {
    DaysCounterView()
}
