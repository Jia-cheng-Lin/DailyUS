//
//  NameCard.swift
//  AboutMe
//
//  Created by 林嘉誠 on 2025/9/26.
//

import Foundation
import Playgrounds
import SwiftUI

struct NameCard: View {
    var body: some View {
        //姓名圖卡
        VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(.bill)
                        //Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 80, height: 80)
                            .foregroundStyle(.blue)
                            .clipShape(.circle)

                        VStack(alignment: .leading) {
                            Text("Bill Lin")
                                .font(.title)
                            Text("PhD student")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack {
                        Image(systemName: "location.circle.fill")
                            .foregroundStyle(.red)
                        Text("Taipei, Taiwan")
                    }

                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(.green)
                        Text("d12543002@ntu.edu.tw")
                    }

                    HStack {
                        Image(systemName: "phone.fill")
                            .foregroundStyle(.orange)
                        Text("+886 922-653-010")
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
    NameCard()
}
