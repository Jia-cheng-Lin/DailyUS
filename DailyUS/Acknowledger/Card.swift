//
//  Card.swift
//  Acknowledger
//
//  Created by 林嘉誠 on 2025/11/5.
//

import Foundation
import Playgrounds
import SwiftUI

struct Card: View {
    
    let note : Note
    
    var body: some View {
        //姓名圖卡
        VStack(alignment: .leading, spacing: 10) {
            note.image
                .resizable()
                .frame(width: 200, height: 200)
                .foregroundStyle(.blue)
                .clipShape(.rect)

            HStack{
                Image(systemName: "list.bullet.clipboard.fill")
                    .foregroundStyle(.brown)
                Text(note.subtitle)
//                    .font(.headline)
                    .frame(width: 150, height: 50, alignment: .leading)
                    .multilineTextAlignment(.leading)
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


#Preview (traits: .sizeThatFitsLayout) {
    NavigationStack {
        Card(
            note: Note(
                image: Image("E1"),
                title: "專業人才溝通術",
                subtitle:" Course 1: Course Introduction",
                speaker: "Lily",
                content: """
            not important
            """
            )
        )
    }
}
