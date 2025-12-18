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

    func updateUIView(_ uiView: UIView, context: Context) {
        // Optionally restart
    }

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

    // Cards
    @State private var current: SoulCard?

    // Replace with your own assets and copy to your Asset catalog
    private let cards: [SoulCard] = [
        .init(title: "勇敢面對", detail: "面對挑戰，給彼此溫柔與力量。", imageName: "soul_brave"),
        .init(title: "溫柔以待", detail: "放慢腳步，先理解再回應。", imageName: "soul_gentle"),
        .init(title: "感恩當下", detail: "珍惜陪伴的每一刻。", imageName: "soul_gratitude"),
        .init(title: "傾聽彼此", detail: "用心傾聽，讓心更靠近。", imageName: "soul_listen"),
        .init(title: "擁抱改變", detail: "改變是成長的一部分。", imageName: "soul_change")
    ]

    // Name of your bundled Lottie JSON (add the .json file to the target)
    private let lottieAnimationName: String = "Sparkles" // change to your file name

    var body: some View {
        ZStack {
            // 背景圖層
            Background(image: Image("Back_1"))
                .opacity(0.5)

            // 內容圖層
            VStack(spacing: 18) {
                header

                cardDisplay
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)

                drawButton
                    .padding(.horizontal, 16)

                Spacer()
            }
            .padding(.top, 16)
        }
        .navigationTitle("心靈小卡")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if current == nil {
                current = cards.randomElement()
            }
        }
    }

    // MARK: - Header with Lottie
    private var header: some View {
        VStack(spacing: 8) {
            ZStack {
                if !reduceMotion {
                    // Recreate Lottie view when key changes to retrigger play
                    LottieView(animationName: lottieAnimationName, loopMode: isAnimating ? .loop : .playOnce, playOnAppear: true, speed: 1.0)
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
        }
    }

    // MARK: - Card UI
    private var cardDisplay: some View {
        Group {
            if let card = current {
                VStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(LinearGradient(colors: [.purple.opacity(0.15), .pink.opacity(0.15)],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)

                        VStack(spacing: 12) {
                            if let imgName = card.imageName, UIImage(named: imgName) != nil {
                                Image(imgName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 140)
                                    .accessibilityHidden(true)
                            } else {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 56))
                                    .foregroundStyle(.purple)
                                    .padding(.top, 12)
                            }

                            Text(card.title)
                                .font(.title3.bold())

                            Text(card.detail)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)

                            Spacer(minLength: 4)
                        }
                        .padding(16)
                    }
                    .frame(height: 260)
                    // 修正 transition：使用 AnyTransition.scale 與 opacity 組合，提升相容性
                    .transition(.asymmetric(insertion: AnyTransition.scale.combined(with: .opacity),
                                            removal: .opacity))
                }
            } else {
                Text("點擊下方按鈕抽卡")
                    .foregroundStyle(.secondary)
                    .frame(height: 200)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: current)
    }

    // MARK: - Draw Button
    private var drawButton: some View {
        Button {
            drawCard()
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
    private func drawCard() {
        // Trigger Lottie replay
        if !reduceMotion {
            isAnimating = true
            lottieKey = UUID() // force recreate to replay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                isAnimating = false
            }
        }

        // Randomize card
        withAnimation {
            current = cards.randomElement()
        }
    }
}

#Preview {
    NavigationStack {
        SoulCardView()
    }
}

