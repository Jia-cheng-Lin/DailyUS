//
//  Work.swift
//  AboutMe
//
//  Created by 林嘉誠 on 2025/9/26.
//

import Foundation
import SwiftUI

struct Work: View{
    
    let logo: Image
    let position: String
    let department: String
    let company: String
    let start: String
    let end: String
    let work1: String
    let work2: String
    // 新增：讓 logo 可由外部指定，預設為 .ntu
    
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
                Image(systemName: "bag.fill")
                    .symbolEffect(.breathe)
                    .foregroundStyle(.brown)
                Text("\(work1)")
                    .font(.system(size: 16))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
            }

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "handbag.fill")
                    .symbolEffect(.breathe)
                    .foregroundStyle(.orange)
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
    Work(
        logo: Image("brain"),
        position: "Research Assistant",
        department: "Taiwan Brain Disease Foundation",
        company: "Shuang Ho Hospital",
        start: "2022",
        end: "2023",
        work1:"Registered an oral presentation at an international conference, Biosensors 2023.",
        work2:"Collaborate with neurosurgeons about the anticoagulant dosage in cardiovascular stents."
    )
}
