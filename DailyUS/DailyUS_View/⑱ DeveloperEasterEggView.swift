//
//  ⑱ DeveloperEasterEggView.swift
//  DailyUS
//
//  Created by 陳芸萱 on 2025/12/2.
//

import SwiftUI

struct DeveloperEasterEggView: View {
    @State private var pulse: Bool = false
    @State private var spin: Bool = false
    @State private var showConfetti: Bool = false

    // 導航到 Bill() 的狀態
    @State private var goToBill: Bool = false

    var body: some View {
        ZStack {
            // 背景圖層
            Background(image: Image("Back_6"))
                .opacity(0.5)

            // 內容圖層
            ScrollView {
                VStack(spacing: 24) {

                    // MARK: 彩蛋動畫 Header
                    ZStack {
                        Circle()
                            .fill(.purple.opacity(0.15))
                            .frame(width: 200, height: 200)
                            .scaleEffect(pulse ? 1.08 : 0.92)
                            .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)

                        Image(systemName: "sparkles")
                            .font(.system(size: 64, weight: .semibold))
                            .foregroundStyle(.purple)
                            .rotationEffect(.degrees(spin ? 360 : 0))
                            .animation(.linear(duration: 6).repeatForever(autoreverses: false), value: spin)
                    }
                    .padding(.top, 12)

                    // MARK: 開發者資訊
                    VStack(alignment: .leading, spacing: 8) {
                        Text("開發者資訊")
                            .font(.title3).bold()

                        DeveloperInfoRow(label: "作者", value: "DailyUS Team - 林嘉誠")
                        DeveloperInfoRow(label: "聯絡", value: "bill092804@gmail.com")
                        DeveloperInfoRow(label: "版本", value: appVersionString())
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    // MARK: 展示 App Icon
                    VStack(spacing: 12) {
                        Text("App Icon")
                            .font(.title3).bold()
                        AppIconPreview()
                            .frame(width: 120, height: 120)
                            .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 6)
                        Text("主圖示預覽")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    // MARK: 互動彩蛋
                    VStack(spacing: 12) {
                        Text("小彩蛋")
                            .font(.title3).bold()
                        Text("點擊下方按鈕，灑一點星星 ✨")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Button {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                                showConfetti.toggle()
                            }
                            // Auto hide after a moment
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                                withAnimation(.easeOut(duration: 0.4)) {
                                    showConfetti = false
                                }
                            }
                        } label: {
                            Label("Celebrate", systemImage: "party.popper.fill")
                                .font(.headline)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 10)
                                .background(Color.purple.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)

                        ZStack {
                            if showConfetti {
                                ConfettiOverlay()
                                    .frame(height: 140)
                                    .transition(.opacity)
                            } else {
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.08))
                                    .frame(height: 140)
                                    .overlay(
                                        Text("等待彩蛋中…")
                                            .foregroundStyle(.secondary)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    Spacer(minLength: 24)

                    // 最下方按鈕：前往 Bill()
                    Button {
                        goToBill = true
                    } label: {
                        Label("前往 Bill", systemImage: "person.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Easter Egg")
        .onAppear {
            pulse = true
            spin = true
        }
        // 導航到 Bill()
        .navigationDestination(isPresented: $goToBill) {
            Bill()
        }
    }

    private func appVersionString() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        return "\(version) (\(build))"
    }
}

// MARK: - Rows & Subviews

private struct DeveloperInfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
        .font(.body)
    }
}

// Attempts to show the app’s primary icon. Falls back to an SF Symbol if not available.
private struct AppIconPreview: View {
    var body: some View {
        if let icon = Bundle.main.primaryAppIcon {
            Image(uiImage: icon)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color.primary.opacity(0.08))
                Image(systemName: "app.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// Simple confetti overlay with star particles
private struct ConfettiOverlay: View {
    @State private var particles: [Particle] = (0..<16).map { _ in Particle() }

    var body: some View {
        ZStack {
            ForEach(particles) { p in
                Image(systemName: "star.fill")
                    .foregroundStyle(p.color)
                    .font(.system(size: p.size))
                    .rotationEffect(.degrees(p.rotation))
                    .offset(x: p.offsetX, y: p.offsetY)
                    .opacity(p.opacity)
                    .onAppear {
                        animate(p.id)
                    }
            }
        }
        .frame(maxWidth: .infinity)
        .clipped()
        .onAppear {
            // reset particles
            particles = (0..<16).map { _ in Particle() }
        }
    }

    private func animate(_ id: UUID) {
        let duration = Double.random(in: 0.7...1.2)
        let angle = Double.random(in: 0...(2 * .pi))
        let distance = CGFloat.random(in: 40...140)

        withAnimation(.easeOut(duration: duration)) {
            if let idx = particles.firstIndex(where: { $0.id == id }) {
                particles[idx].offsetX = cos(angle) * distance
                particles[idx].offsetY = sin(angle) * distance
                particles[idx].opacity = 0
                particles[idx].rotation = Double.random(in: -180...180)
            }
        }
    }

    private struct Particle: Identifiable {
        let id = UUID()
        var color: Color = [.pink, .purple, .yellow, .mint, .orange].randomElement() ?? .pink
        var size: CGFloat = CGFloat.random(in: 10...20)
        var offsetX: CGFloat = 0
        var offsetY: CGFloat = 0
        var rotation: Double = 0
        var opacity: Double = 1
    }
}

// MARK: - Bundle App Icon helper

private extension Bundle {
    var primaryAppIcon: UIImage? {
        guard
            let iconsDict = infoDictionary?["CFBundleIcons"] as? [String: Any],
            let primary = iconsDict["CFBundlePrimaryIcon"] as? [String: Any],
            let iconFiles = primary["CFBundleIconFiles"] as? [String],
            let last = iconFiles.last,
            let image = UIImage(named: last)
        else { return nil }
        return image
    }
}

#Preview {
    NavigationStack {
        DeveloperEasterEggView()
    }
}
