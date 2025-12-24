//
//  SecondBackground.swift
//  Acknowledger
//
//  Created by 林嘉誠 on 2025/11/5.
//

import SwiftUI

struct SecondBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Group {
            if colorScheme == .dark {
                Image("dark")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.8)
            } else {
                Image("background")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.4)
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
    SecondBackground()
}
