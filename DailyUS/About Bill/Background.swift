//
//  template.swift
//  AboutMe
//
//  Created by 林嘉誠 on 2025/9/26.
//

import Foundation
import SwiftUI

struct Background: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if colorScheme == .dark {
                Image(.lake)
//                    // 先在 Image 階段設定 template 渲染
//                    .renderingMode(Image.TemplateRenderingMode.template)
//                    .resizable()
//                    .scaledToFill()
//                    // 明確指定 Color.white，避免無法推斷
//                    .foregroundStyle(Color.white.opacity(0.18))
//                    // 明確指定 BlendMode.screen，避免無法推斷
//                    .blendMode(BlendMode.screen)
                    .resizable()
                    .scaledToFill()
                    .opacity(0.4)
            } else {
                Image(.fire)
                    .resizable()
                    .scaledToFill()
                    .opacity(0.1)
            }
        }
        .frame(
            minWidth: 0,
            maxWidth: .infinity,
            minHeight: 0,
            maxHeight: .infinity
        )
        .ignoresSafeArea()
    }
}

#Preview {
    Background()
}
