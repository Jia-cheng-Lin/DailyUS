//
//  ⑪ HeartTapView.swift
//  DailyUS
//
//  Created by 陳芸萱 on 2025/12/2.
//

import SwiftUI

struct HeartTapView: View {
    // Persist total taps across launches
    @AppStorage("heartTapTotalCount") private var totalCount: Int = 0

    // Local animation states
    @State private var tapScale: CGFloat = 1.0
    @State private var pulse: Bool = false
    @State private var burstHearts: [BurstItem] = []

    // Increment selection
    @State private var selectedIncrement: Int = 1

    // Celebration overlay state
    @State private var celebration: Celebration?

    // Customize appearance if needed
    var heartColor: Color = .red
    var heartSize: CGFloat = 80

    var body: some View {
        ZStack {
            // 背景圖層
            Background(image: Image("Back_5"))
                .opacity(0.5)

            // 內容圖層
            VStack(spacing: 20) {
                // Display total count
                VStack(spacing: 40) {
                    Text("今日愛心累積")
                        .font(.headline)
                    Text("\(totalCount)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                }
                .padding(.top, 50) // 往下移一點（調整這個數值控制距離）

                // Increment selector row
                HStack(spacing: 12) {
                    incrementButton(1)
                    incrementButton(10)
                    incrementButton(100)
                    incrementButton(1000)
                }
                .padding(.horizontal)

                ZStack {
                    // Soft pulsing background
                    Circle()
                        .fill(heartColor.opacity(0.12))
                        .frame(width: heartSize * 2.0, height: heartSize * 2.0)
                        .scaleEffect(pulse ? 1.06 : 0.94)

                    // Main heart
                    Image(systemName: "heart.fill")
                        .foregroundStyle(heartColor)
                        .font(.system(size: heartSize))
                        .scaleEffect(tapScale)
                        .shadow(color: heartColor.opacity(0.3), radius: 8, x: 0, y: 6)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            performTap(amount: selectedIncrement)
                        }

                    // Small burst hearts on tap
                    ForEach(burstHearts, id: \.id) { item in
                        BurstHeart(sizeMultiplier: item.sizeMultiplier)
                            .foregroundStyle(heartColor)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: heartSize * 2.6)

                // Action row
                HStack(spacing: 50) {
                    Button {
                        performTap(amount: selectedIncrement)
                    } label: {
                        Label("再點一下 (+\(selectedIncrement))", systemImage: "hand.point.up.left.fill")
                            .font(.headline)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(heartColor.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    Button(role: .destructive) {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
                            totalCount = 0
                        }
                    } label: {
                        Label("清除", systemImage: "trash")
                    }
                }
                .padding(.top, 8)

                Spacer()
            }
            .padding()

            // Full-screen celebration overlay
            if let celebration {
                CelebrationOverlay(celebration: celebration)
                    .transition(.opacity)
                    .onAppear {
                        // Auto dismiss after a moment
                        DispatchQueue.main.asyncAfter(deadline: .now() + celebration.duration) {
                            withAnimation(.easeOut(duration: 0.35)) {
                                self.celebration = nil
                            }
                        }
                    }
                    .onTapGesture {
                        withAnimation(.easeOut(duration: 0.3)) {
                            self.celebration = nil
                        }
                    }
            }
        }
        .navigationTitle("Heart Tap")
        .onAppear { pulse = true }
    }

    private func incrementButton(_ value: Int) -> some View {
        let isSelected = selectedIncrement == value
        return Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                selectedIncrement = value
            }
        } label: {
            Text("+\(value)")
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? heartColor.opacity(0.25) : heartColor.opacity(0.12))
                .foregroundStyle(.primary)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(isSelected ? heartColor.opacity(0.6) : heartColor.opacity(0.2), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func performTap(amount: Int) {
        // Haptics (light)
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif

        // Remember previous total for milestone detection
        let previous = totalCount

        // Increase counter
        totalCount += amount

        // Compute scaling based on amount (log keeps it reasonable)
        // amount: 1 -> ~1.18, 10 -> ~1.26, 100 -> ~1.34, 1000 -> ~1.42 (before spring settles back)
        let basePop: CGFloat = 1.88
        let scaleBoostPerDecade: CGFloat = 0.80
        let decades = CGFloat(max(0, Int(log10(Double(max(1, amount)))))) // 1->0,10->1,100->2,1000->3
        let targetScale = basePop + scaleBoostPerDecade * decades

        // Scale pop animation
        withAnimation(.spring(response: 0.25, dampingFraction: 0.55)) {
            tapScale = targetScale
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7).delay(0.04)) {
            tapScale = 1.0
        }

        // Burst hearts: count and size scale with amount
        // Spawn more hearts for larger amounts, but cap to avoid overload
        let baseCount = 3
        let extraPerDecade = 3
        let spawnCount = min(18, baseCount + Int(decades) * extraPerDecade)

        // Size multiplier for burst hearts: grow slightly with amount
        let baseSizeMul: CGFloat = 1.0
        let sizeMul = baseSizeMul + 0.25 * decades

        // Emit burst hearts
        var newItems: [BurstItem] = []
        for _ in 0..<spawnCount {
            newItems.append(BurstItem(sizeMultiplier: sizeMul))
        }
        burstHearts.append(contentsOf: newItems)

        // Remove them after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            let ids = Set(newItems.map { $0.id })
            burstHearts.removeAll { ids.contains($0.id) }
        }

        // Check for milestone celebration
        checkMilestoneTrigger(previous: previous, current: totalCount)
    }

    private func checkMilestoneTrigger(previous: Int, current: Int) {
        // Trigger only if we just reached or crossed a milestone (not re-trigger on every tap)
        let milestones: [Int] = [100, 520, 1118, 1314] // include all you want
        guard let reached = milestones.first(where: { previous < $0 && current >= $0 }) else { return }

        let mode: Celebration.Mode
        switch reached {
        case 100:
            mode = .confetti(message: "100！好棒！", accent: .mint)
        case 520:
            mode = .hearts(message: "520 我愛你 ❤️", accent: .pink)
        case 1118:
            mode = .hearts(message: "1118 紀念日快樂 ✨", accent: .yellow)
        case 1314:
            mode = .hearts(message: "1314 一生一世 💖", accent: .red)
        default:
            mode = .confetti(message: "恭喜達成 \(reached)！", accent: .blue)
        }

        withAnimation(.easeIn(duration: 0.25)) {
            celebration = Celebration(mode: mode)
        }
    }

    private struct BurstItem: Identifiable {
        let id = UUID()
        let sizeMultiplier: CGFloat
    }
}

// A small heart that flies outward and fades, used for burst effect
private struct BurstHeart: View {
    @State private var offset: CGSize = .zero
    @State private var scale: CGFloat = 0.2
    @State private var opacity: Double = 1.0

    // Control size and travel distance
    var sizeMultiplier: CGFloat = 1.0

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 18 * sizeMultiplier, weight: .semibold))
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                // Random direction and distance
                let angle = Double.random(in: 0...(2 * .pi))
                let baseDistance = CGFloat.random(in: 40...90)
                let distance = baseDistance * (0.9 + 0.4 * sizeMultiplier) // go farther if bigger
                let dx = cos(angle) * distance
                let dy = sin(angle) * distance * 0.8

                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    scale = 1.0
                }
                withAnimation(.easeOut(duration: 0.6)) {
                    offset = CGSize(width: dx, height: dy)
                    opacity = 0.0
                }
            }
            .offset(offset)
    }
}

// MARK: - Celebration model & overlay

private struct Celebration: Identifiable, Equatable {
    enum Mode: Equatable {
        case hearts(message: String, accent: Color)
        case confetti(message: String, accent: Color)
    }

    let id = UUID()
    var mode: Mode
    var duration: TimeInterval {
        switch mode {
        case .hearts: return 1.8
        case .confetti: return 1.6
        }
    }
}

private struct CelebrationOverlay: View {
    let celebration: Celebration

    @State private var appear = false
    @State private var particles: [Particle] = (0..<28).map { _ in Particle() }

    var body: some View {
        ZStack {
            // Dim background
            Rectangle()
                .fill(.black.opacity(0.35))
                .ignoresSafeArea()
                .opacity(appear ? 1 : 0)

            // Animated particles
            ZStack {
                ForEach(particles) { p in
                    symbol(for: celebration.mode)
                        .foregroundStyle(p.color)
                        .font(.system(size: p.size, weight: .semibold))
                        .rotationEffect(.degrees(p.rotation))
                        .offset(x: p.offsetX, y: p.offsetY)
                        .opacity(p.opacity)
                        .scaleEffect(p.scale)
                        .onAppear { animateParticle(id: p.id) }
                }
            }
            .allowsHitTesting(false)

            // Center message badge
            VStack(spacing: 12) {
                switch celebration.mode {
                case .hearts(let message, let accent),
                     .confetti(let message, let accent):
                    Text(message)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .padding(.horizontal, 22)
                        .padding(.vertical, 12)
                        .background(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(accent.opacity(0.7), lineWidth: 2)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(radius: 10)
                        .scaleEffect(appear ? 1 : 0.85)
                        .opacity(appear ? 1 : 0)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.2)) { appear = true }
            // reset particles each time
            particles = (0..<28).map { _ in Particle(mode: celebration.mode) }
        }
    }

    @ViewBuilder
    private func symbol(for mode: Celebration.Mode) -> some View {
        switch mode {
        case .hearts(_, _):
            Image(systemName: "heart.fill")
        case .confetti(_, _):
            Image(systemName: "star.fill")
        }
    }

    private func animateParticle(id: UUID) {
        let duration = Double.random(in: 0.9...1.6)
        let angle = Double.random(in: 0...(2 * .pi))
        let distance = CGFloat.random(in: 120...260)

        withAnimation(.easeOut(duration: duration)) {
            if let idx = particles.firstIndex(where: { $0.id == id }) {
                particles[idx].offsetX = cos(angle) * distance
                particles[idx].offsetY = sin(angle) * distance
                particles[idx].opacity = 0
                particles[idx].rotation = Double.random(in: -240...240)
                particles[idx].scale = CGFloat.random(in: 1.0...1.4)
            }
        }
    }

    private struct Particle: Identifiable {
        let id = UUID()
        var color: Color
        var size: CGFloat
        var offsetX: CGFloat = 0
        var offsetY: CGFloat = 0
        var rotation: Double = 0
        var opacity: Double = 1
        var scale: CGFloat = 0.9

        init(mode: Celebration.Mode? = nil) {
            // color palette per mode
            let palette: [Color]
            switch mode {
            case .hearts(_, let accent):
                palette = [accent, .red, .pink, .purple, .orange]
            case .confetti(_, let accent):
                palette = [accent, .yellow, .mint, .blue, .orange, .purple]
            case .none:
                palette = [.pink, .red, .yellow, .mint, .orange]
            }
            color = palette.randomElement() ?? .pink
            size = CGFloat.random(in: 16...28)
        }
    }
}

#Preview {
    NavigationStack {
        HeartTapView()
    }
}

