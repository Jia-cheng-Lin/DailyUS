//
//  ⑬ MemoryDashboardView.swift
//  DailyUS
//
//  Created by 陳芸萱 on 2025/12/2
//

import SwiftUI

struct MemoryDashboardView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("紀念日 / 在一起天數") {
                    NavigationLink("Anniversary") { AnniversaryView() }
                    NavigationLink("Together Days") { DaysCounterView() }
                }
                Section("回憶時間軸") {
                    // Use the production timeline view from ⑯ TimelineView.swift
                    NavigationLink("Diary Timeline") { TimelineView() }
                }
//                Section("繳費與記帳") {
//                    NavigationLink("繳費提醒 / 記帳紀錄") {
//                        PaymentView()
//                    }
//                }
            }
            // 讓大標題「Memory」與第一個 Section 之間有額外間隔
            .safeAreaInset(edge: .top) {
                // 依照你的視覺需求微調高度，20~36 之間都常見
                Color.clear.frame(height: 24)
            }
            // 如果希望 Section 之間再鬆一點，可加上這個（iOS 16+）
            .listSectionSpacing(.custom(12))

            .scrollContentBackground(.hidden) // 隱藏 List 背景
            .background(Color.clear)          // 頁面背景透明
            .navigationTitle("Memory")
        }
        .background(Color.clear)              // NavigationStack 背景透明
    }
}

#Preview {
    MemoryDashboardView()
}

