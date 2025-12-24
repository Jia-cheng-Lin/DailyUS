//
//  ⑨ SoulCardView.swift
//  DailyUS
//
//  Created by 陳芸萱 on 2025/12/2.
//

import SwiftUI
import Lottie

// MARK: - Model
struct SoulCard: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let detail: String
    // Use asset image name; if nil, we’ll show an SF Symbol
    let imageName: String?
}

// MARK: - Lottie SwiftUI wrapper
struct LottieView: UIViewRepresentable {
    let animationName: String
    var loopMode: LottieLoopMode = .playOnce
    var playOnAppear: Bool = true
    var speed: CGFloat = 1.0

    private let animationView = LottieAnimationView()

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        animationView.translatesAutoresizingMaskIntoConstraints = false
        animationView.contentMode = .scaleAspectFit
        animationView.animation = LottieAnimation.named(animationName)
        animationView.loopMode = loopMode
        animationView.animationSpeed = speed

        view.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            animationView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            animationView.topAnchor.constraint(equalTo: view.topAnchor),
            animationView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        if playOnAppear {
            animationView.play()
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func play() {
        animationView.play()
    }
}

// MARK: - View
struct SoulCardView: View {
    // Accessibility
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Animation control
    @State private var isAnimating: Bool = false
    @State private var lottieKey: UUID = UUID()

    // Flip control（採用範例風格）
    @State private var flipped: Bool = false
    // 動畫結束後只保留正面，避免任何重疊
    @State private var showOnlyFront: Bool = false

    // Cards
    @State private var current: SoulCard?
    @State private var pending: SoulCard? // 翻到背面時預先決定的卡

    // Replace with your own assets and copy to your Asset catalog
    private let cards: [SoulCard] = [
        .init(title: "勇敢面對", detail: "面對挑戰，給彼此溫柔與力量。", imageName: "soul_brave"),
        .init(title: "溫柔以待", detail: "放慢腳步，先理解再回應。", imageName: "soul_gentle"),
        .init(title: "感恩當下", detail: "珍惜陪伴的每一刻。", imageName: "soul_gratitude"),
        .init(title: "傾聽彼此", detail: "用心傾聽，讓心更靠近。", imageName: "soul_listen"),
        .init(title: "擁抱改變", detail: "改變是成長的一部分。", imageName: "soul_change")
    ]

    // Name of your bundled Lottie JSON (add the .json file to the target)
    private let lottieAnimationName: String = "Sparkles"

    // 外觀比例與縮放
    private let cardAspect: CGFloat = 0.75
    private let scaleFactor: CGFloat = 0.7
    private let maxBaseWidth: CGFloat = 420

    var body: some View {
        ZStack {
            // 背景圖層
            Background(image: Image("Back_1"))
                .opacity(0.5)

            // 內容圖層
            VStack(spacing: 20) {
                header
                    .padding(.top, -120)

                cardDisplay
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)

                drawButton
                    .padding(.horizontal, 50)

                Spacer()
            }
            .padding(.top, 50)
        }
        .navigationTitle("心靈小卡")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if current == nil {
                current = cards.randomElement()
            }
            // 進場先顯示背面（Back_2）
            flipped = false
            showOnlyFront = false
        }
    }

    // MARK: - Header with Lottie
    private var header: some View {
        VStack(spacing: 8) {
            ZStack {
                if !reduceMotion {
                    LottieView(animationName: lottieAnimationName,
                               loopMode: isAnimating ? .loop : .playOnce,
                               playOnAppear: true,
                               speed: 1.0)
                    .id(lottieKey)
                    .frame(height: 120)
                    .opacity(0.9)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundStyle(.purple)
                        .frame(height: 80)
                }
            }
            Text("抽一張給今天的自己/你們")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, -40)
        }
    }

    // MARK: - Card UI
    private var cardDisplay: some View {
        GeometryReader { geo in
            let baseWidth = min(geo.size.width, maxBaseWidth)
            let width = baseWidth * scaleFactor
            let height = width / max(0.01, cardAspect)

            ZStack {
                if showOnlyFront {
                    // 動畫結束後：只保留正面，完全無重疊
                    cardFrontImage
                        .frame(width: width, height: height)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
                } else {
                    // 動畫進行中或背面狀態：兩面同時存在做翻面動畫
                    cardBack
                        .frame(width: width, height: height)
                        .opacity(flipped ? 0 : 1)
                        .rotation3DEffect(.degrees(flipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))

                    cardFrontImage
                        .frame(width: width, height: height)
                        .opacity(flipped ? 1 : 0)
                        .rotation3DEffect(.degrees(flipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { toggleFlip() }
            .frame(maxWidth: .infinity, maxHeight: height)
        }
        .frame(height: (maxBaseWidth * scaleFactor) / max(0.01, cardAspect))
    }

    private var cardBack: some View {
        Image("Back_2")
            .resizable()
            .scaledToFill()
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
    }

    @ViewBuilder
    private var cardFrontImage: some View {
        if let imgName = current?.imageName, UIImage(named: imgName) != nil {
            Image(imgName)
                .resizable()
                .scaledToFill()
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    VStack {
                        Spacer()
                        if let title = current?.title {
                            Text(title)
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .background(.black.opacity(0.35))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .padding(8)
                        }
                    }
                )
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        } else {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(LinearGradient(colors: [.purple.opacity(0.15), .pink.opacity(0.15)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    VStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 52))
                            .foregroundStyle(.purple)
                        if let title = current?.title {
                            Text(title)
                                .font(.title3.bold())
                                .multilineTextAlignment(.center)
                        }
                        if let detail = current?.detail {
                            Text(detail)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                )
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        }
    }

    // MARK: - Draw Button
    private var drawButton: some View {
        Button {
            toggleFlip()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "wand.and.stars")
                Text("抽一張")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(.white)
            .background(Color.purple)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: .purple.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("抽一張心靈小卡")
    }

    // MARK: - Actions
    private func toggleFlip() {
        // 播 Lottie
        if !reduceMotion {
            isAnimating = true
            lottieKey = UUID()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isAnimating = false
            }
        }

        let duration = reduceMotion ? 0.18 : 0.5

        // 若目前是正面且只顯示正面，要翻回背面時，先恢復雙面模式
        if flipped && showOnlyFront {
            showOnlyFront = false
        }

        // 在翻面開始時，就先決定好下一張卡（等半程背面可視時替換）
        if !flipped {
            // 正要從背面翻到正面 → 抽一張準備顯示
            pending = cards.randomElement()
        } else {
            // 正要從正面翻回背面 → 可選擇不預抽，或預抽下一輪
            pending = cards.randomElement()
        }

        // 翻面動畫
        withAnimation(.easeInOut(duration: duration)) {
            flipped.toggle()
        }

        // 半程（約背面可視時刻）替換 current，這樣回到正面時已是新卡
        DispatchQueue.main.asyncAfter(deadline: .now() + duration / 2) {
            if let p = pending {
                current = p
                pending = nil
            }
        }

        // 動畫結束後：若停在正面，只顯示正面；若停在背面，維持雙面模式
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            if flipped {
                showOnlyFront = true
            } else {
                showOnlyFront = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        SoulCardView()
    }
}

