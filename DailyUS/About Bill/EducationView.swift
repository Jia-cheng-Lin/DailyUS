//
//  EducationView.swift
//  AboutMe
//
//  Created by 林嘉誠 on 2025/9/26.
//

import Foundation
import Playgrounds
import SwiftUI

struct EducationView: View {
    let collage: String
    let department: String
    let degree: String
    let start: String
    let end: String
    let gpa: Double
    let tgpa: Double
    let medal: String
    // 新增：讓 logo 可由外部指定，預設為 .ntu
    let logo: Image
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                // 使用外部傳入的 logo
                logo
                    .resizable()
                    .frame(width: 40, height: 40)
                    .clipShape(.circle)

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(collage)")
                        .font(.title2)
                        .foregroundStyle(.primary)
                    Text("\(department)")
                        .font(.title3)
                        .foregroundStyle(.primary)

                    // 用 Spacer 把日期推到最右邊
                    HStack {
                        Text("\(degree)")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Text("\(start) - \(end)")
                            .foregroundStyle(.tertiary)
                    }
                }
                // 讓內層內容撐滿，trailing 就是整張卡片的右緣
                .frame(maxWidth: 270, alignment: .leading)
            }

            HStack {
                Image(systemName: "books.vertical.fill")
                    .symbolEffect(.breathe)
                    .foregroundStyle(.red)
                Text("GPA: \(gpa, specifier: "%.2f") / \(tgpa, specifier: "%.2f")")
            }

            HStack {
                Image(systemName: "medal.fill")
                    .symbolEffect(.breathe)
                    .foregroundStyle(.yellow)
                Text("\(medal)")
            }
        }
        .padding()
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
        .shadow(radius: 10)
    }
}

#Preview {
    // 預設 logo（ntu）
    EducationView(
        collage: "National Taiwan University",
        department: "Institute of Applied Mechanics",
        degree: "PhD",
        start: "2023",
        end: "present",
        gpa: 4.25,
        tgpa: 4.30,
        medal: "National Taiwan University Diligence Scholarships for Doctoral Students",
        logo: Image("ntu")
    )
}
