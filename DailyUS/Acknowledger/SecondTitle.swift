//
//  Title.swift
//  Acknowledger
//
//  Created by 林嘉誠 on 2025/11/5.
//

import SwiftUI

struct SecondTitle: View {
    let symbol: String
    let title: String
    let color: Color?
    
    private var effectiveColor: Color {
        color ?? .accentColor
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 學歷標題列
            HStack {
                Image(systemName: symbol)
                    .symbolEffect(.variableColor)
                    .font(.largeTitle)
                    .bold()
                    .padding(.trailing, 4)
                Text(title)
                    .font(.largeTitle)
                    .bold()
                    .padding(10)
                    // 使用通用的毛玻璃背景效果
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    // 加一層可調整透明度的色彩覆蓋
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(effectiveColor.opacity(0.15))
                    )
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    SecondTitle(symbol: "long.text.page.and.pencil.fill", title: "Lecture note", color: .green)
}
