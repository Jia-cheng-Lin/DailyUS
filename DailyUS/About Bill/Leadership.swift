//
//  Leadership.swift
//  AboutMe
//
//  Created by 林嘉誠 on 2025/9/26.
//

import Foundation
import SwiftUI

struct Leadership: View{
    let logo: Image
    let position: String
    let department: String
    let company: String
    let start: String
    let end: String
    let work1: String
    let work2: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                // 使用外部傳入的 logo
                logo
                    .resizable()
                    .frame(width: 40, height: 40)
                    .clipShape(.circle)

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(position)")
                        .font(.title)
                        .foregroundStyle(.primary)
                    Text("\(department)")
                        .font(.title2)
                        .foregroundStyle(.primary)
                    Text("\(company)")
                        .font(.title2)
                        .foregroundStyle(.secondary)

                    // 用 Spacer 把日期推到最右邊
                    HStack {
                        Spacer()
                        Text("\(start) - \(end)")
                            .foregroundStyle(.tertiary)
                    }
                }
                // 讓內層內容吃滿剩餘寬度，避免被固定寬度壓縮
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "person.text.rectangle.fill")
                    .symbolEffect(.breathe)
                    .foregroundStyle(.green)
                Text("\(work1)")
                    .font(.system(size: 16))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
            }

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "person.crop.rectangle.badge.plus.fill")
                    .symbolEffect(.breathe)
                    .foregroundStyle(.blue)
                Text("\(work2)")
                    .font(.system(size: 16))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
            }
        }
        .padding()
        // 給整張卡片一個固定寬度，讓內文自然換行
        .frame(width: 350, alignment: .leading)
        // 使用較有對比的卡片底色（會隨深淺模式變化）
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        // 加上一圈動態顏色的邊線，深色模式也清楚
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(.separator), lineWidth: 1)
        )
        .clipShape(.rect(cornerRadius: 20))
        .shadow(radius: 10)
          
    }
}
 

#Preview {
    Leadership(
        logo: Image("besa"),
        position: "Minister of Public Relations Department",
        department: "Bio Entrepreneurship Student Association",
        company: "National Taiwan University",
        start: "2020",
        end: "2021",
        work1:"Increased the number of business partners and lecturers to 40+ and 120+ respectively.",
        work2:"Directly trained 10 members to host 20+ Public Relation Events."
    )
}
