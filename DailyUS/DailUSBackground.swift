//
//  DailUSBackground.swift
//  DailyUS
//
//  Created by You on 2025/12/12.
//

import SwiftUI

// MARK: - Reusable background container view
public struct DailUSBackground<Content: View>: View {
    private let content: Content
    private let horizontalPadding: CGFloat
    private let verticalPadding: CGFloat

    // Replace "DailyUS_background" below if your asset name is different.
    private let imageName: String = "DailyUS_background"

    public init(horizontalPadding: CGFloat = 0,
                verticalPadding: CGFloat = 0,
                @ViewBuilder content: () -> Content) {
        self.content = content()
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
    }

    public var body: some View {
        ZStack {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // Keep content within safe area and provide default padding knobs
            VStack {
                content
                    .padding(.horizontal, horizontalPadding)
                    .padding(.vertical, verticalPadding)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

// MARK: - ViewModifier + View extension
public struct DailUSBackgroundModifier: ViewModifier {
    // Replace "DailyUS_background" if needed.
    private let imageName: String = "DailyUS_background"

    public func body(content: Content) -> some View {
        ZStack {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            content
        }
    }
}

public extension View {
    /// Apply DailyUS background image behind this view.
    func dailUSBackground() -> some View {
        modifier(DailUSBackgroundModifier())
    }
}

#Preview {
    DailUSBackground(horizontalPadding: 16, verticalPadding: 16) {
        VStack(alignment: .leading, spacing: 12) {
            Text("這是示範內容")
                .font(.title2.bold())
            Text("背景使用 DailyUS_background，內容保留安全邊界與內距，避免文字凸出去。")
                .font(.body)
                .foregroundStyle(.secondary)

            Button("示範按鈕") {}
                .buttonStyle(.borderedProminent)

            Spacer()
        }
    }
}
