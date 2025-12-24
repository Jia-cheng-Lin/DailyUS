//
//  ContentView.swift
//  kyorochan
//
//  Created by 林嘉誠 on 2025/9/14.
//

import SwiftUI

struct Kyrochan: View {
    // Layer toggles（預設全部關閉）
    @State private var showBackground = false
    @State private var showHead = false
    @State private var showBody = false
    @State private var showBodyLines = false
    @State private var showFeet = false
    @State private var showMouth = false
    @State private var showEyes = false
    @State private var showShadows = false

    // 全部顯示/隱藏的總開關
    @State private var isAllShown: Bool = false

    // Text sequence state: 0...4 (how many lines are visible)
    @State private var textStep: Int = 0

    // 文字動畫任務控制
    @State private var textAnimationTask: Task<Void, Never>? = nil

    private let contentScale: CGFloat = 0.8
    private let sidePadding: CGFloat = 16
    private let topSafePadding: CGFloat = 24
    private let buttonHeight: CGFloat = 44

    var body: some View {
        ZStack {
            // 背景（全螢幕忽略安全區域）
            if showBackground {
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.6),
                        Color.blue.opacity(0.4)
                    ]),
                    center: .init(x: 0.5, y: 0.7),
                    startRadius: 40,
                    endRadius: 350
                )
                .opacity(0.6)
                .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                // 可捲動內容
                ScrollView {
                    ZStack {
                        // 只移動「所有圖片」：頭部、身體、線條、雙腳、嘴巴、眼睛、陰影
                        Group {
                            // 頭部
                            if showHead {
                                Capsule()
                                    .trim(from:0.5, to:1)
                                    .fill(Color(red: 232/255, green:34/255, blue:34/255).opacity(0.6))
                                    .overlay(
                                        Capsule()
                                            .trim(from:0.5, to:1)
                                            .stroke(Color.black, lineWidth: 2)
                                    )
                                    .frame(width: 260, height: 380)
                                    .offset(x: 20, y: 20)
                            }

                            // 身體
                            if showBody {
                                Capsule()
                                    .trim(from:0, to:0.5)
                                    .fill(Color(red: 126/255, green:73/255, blue:50/255).opacity(0.6))
                                    .overlay(
                                        Capsule()
                                            .trim(from:0, to:0.5)
                                            .stroke(Color.black, lineWidth: 2)
                                    )
                                    .shadow(color: Color.black.opacity(0.8), radius: 12, x: 4, y: 8)
                                    .frame(width: 260, height: 430)
                                    .offset(x: 20, y: 20)
                            }

                            // 身體線條
                            if showBodyLines {
                                BodyLine()
                                    .fill(Color(red: 243/255, green:219/255, blue:50/255).opacity(0.5))
                                    .overlay(
                                        BodyLine().stroke(Color.black, lineWidth: 2)
                                    )
                                    .frame(width: 490, height: 700)
                                    .offset(x: 0, y: 160)
                            }

                            // 左腳 + 右腳
                            if showFeet {
                                LeftFoot()
                                    .fill(Color(red: 67/255, green:41/255, blue:27/255).opacity(0.5))
                                    .overlay(
                                        LeftFoot().stroke(Color.black, lineWidth: 2)
                                    )
                                    .frame(width: 490, height: 700)
                                    .offset(x: 0, y: 151)
                                    .shadow(color: Color.black.opacity(0.6), radius: 12, x: 4, y: 8)

                                RightFoot()
                                    .fill(Color(red: 67/255, green:41/255, blue:27/255).opacity(0.5))
                                    .overlay(
                                        RightFoot().stroke(Color.black, lineWidth: 2)
                                    )
                                    .frame(width: 490, height: 700)
                                    .offset(x: 0, y: 151)
                                    .shadow(color: Color.black.opacity(0.6), radius: 12, x: 4, y: 8)
                            }

                            // 嘴巴
                            if showMouth {
                                PointedOval(sharpness: 0.75)
                                    .fill(Color(red: 253/255, green: 187/255, blue: 72/255).opacity(0.6))
                                    .overlay(PointedOval(sharpness: 0.75).stroke(.black, lineWidth: 2))
                                    .frame(width: 230, height: 120)
                                    .rotationEffect(.degrees(-15))
                                    .offset(x: -70, y: 20)
                                    .shadow(color: Color.black.opacity(0.6), radius: 12, x: 4, y: 8)
                            }

                            // 雙眼
                            if showEyes {
                                // 左眼睛（白）加邊框
                                Circle()
                                    .fill(Color.white.opacity(0.6))
                                    .overlay(
                                        Circle().stroke(Color.black, lineWidth: 2)
                                    )
                                    .frame(width: 84)
                                    .offset(x: -48, y: -83)

                                // 左眼睛（黑）加邊框
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                                    .overlay(
                                        Circle().stroke(Color.black, lineWidth: 2)
                                    )
                                    .frame(width: 60)
                                    .offset(x: -38, y: -83)

                                // 右眼睛（白）加邊框
                                Circle()
                                    .fill(Color.white.opacity(0.6))
                                    .overlay(
                                        Circle().stroke(Color.black, lineWidth: 2)
                                    )
                                    .frame(width: 110)
                                    .offset(x: 52, y: -75)

                                // 右眼睛（黑）加邊框
                                Circle()
                                    .fill(Color.black.opacity(0.6))
                                    .overlay(
                                        Circle().stroke(Color.black, lineWidth: 2)
                                    )
                                    .frame(width: 80)
                                    .offset(x: 40, y: -75)
                            }

                            // 陰影（身體 + 嘴巴）
                            if showShadows {
                                // 身體加陰影
                                BodyShadow()
                                    .fill(.black.opacity(0.3))
                                    .frame(width: 490, height: 700)
                                    .offset(x: 0, y: 151)

                                // 嘴巴加陰影
                                MouthShadow()
                                    .fill(.black.opacity(0.3))
                                    .frame(width: 490, height: 700)
                                    .offset(x: 0, y: 151)
                            }
                        }
                        .offset(y: 20) // 只移動圖片群，按鈕不受影響

                        // 文字（依序淡化出現）－不位移，保持原來位置與動畫
                        VStack(spacing: 12) {
                            if textStep >= 1 {
                                Text("Do you remember me?")
                                    .font(.largeTitle)
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(.ultraThinMaterial, in: Capsule())
                                    .transition(.opacity)
                                    .opacity(textStep >= 1 ? 1 : 0)
                            }
                            if textStep >= 2 {
                                Text("I'm Kyorochan!")
                                    .font(.largeTitle)
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(.ultraThinMaterial, in: Capsule())
                                    .transition(.opacity)
                                    .opacity(textStep >= 2 ? 1 : 0)
                            }
                            if textStep >= 3 {
                                Text("也有人叫我大嘴鳥")
                                    .font(.title)
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(.ultraThinMaterial, in: Capsule())
                                    .transition(.opacity)
                                    .opacity(textStep >= 3 ? 1 : 0)
                            }
                            if textStep >= 4 {
                                Text("私はキョロちゃんです")
                                    .font(.title)
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(.ultraThinMaterial, in: Capsule())
                                    .transition(.opacity)
                                    .opacity(textStep >= 4 ? 1 : 0)
                            }
                        }
                        .padding(.top, topSafePadding) // 避免文字貼到安全區上緣
                        .offset(x: 0, y: -300)
                        .animation(.easeInOut(duration: 0.35), value: textStep)
                    }
                    .frame(maxWidth: .infinity, minHeight: 700)
                    .padding(.horizontal, sidePadding) // 左右留白避免貼邊
                    .padding(.top, topSafePadding)
                    .scaleEffect(contentScale, anchor: .top) // 整體縮小（只影響 Scroll 內容）
                }

                // 底部控制列：Show/Hide All + 三排按鈕（按鈕大小固定，不受上方 scale 影響）
                VStack(spacing: 12) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            isAllShown.toggle()
                            let newValue = isAllShown
                            showBackground = newValue
                            showHead = newValue
                            showBody = newValue
                            showBodyLines = newValue
                            showFeet = newValue
                            showMouth = newValue
                            showEyes = newValue
                            showShadows = newValue
                            textStep = newValue ? 4 : 0
                        }
                        if isAllShown {
                            textAnimationTask?.cancel()
                            textAnimationTask = nil
                        }
                    } label: {
                        Label(isAllShown ? "Hide All" : "Show All", systemImage: isAllShown ? "eye.slash" : "eye")
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: buttonHeight)
                            .background(.thinMaterial, in: Capsule())
                    }
                    .buttonStyle(.plain)

                    // 三排切換按鈕
                    VStack(spacing: 10) {
                        HStack(spacing: 10) {
                            ToggleButton(title: "背景", isOn: $showBackground, height: buttonHeight)
                            ToggleButton(title: "頭部", isOn: $showHead, height: buttonHeight)
                            ToggleButton(title: "身體", isOn: $showBody, height: buttonHeight)
                        }
                        HStack(spacing: 10) {
                            ToggleButton(title: "線條", isOn: $showBodyLines, height: buttonHeight)
                            ToggleButton(title: "雙腳", isOn: $showFeet, height: buttonHeight)
                            ToggleButton(title: "嘴巴", isOn: $showMouth, height: buttonHeight)
                        }
                        HStack(spacing: 10) {
                            ToggleButton(title: "雙眼", isOn: $showEyes, height: buttonHeight)
                            ToggleButton(title: "陰影", isOn: $showShadows, height: buttonHeight)
                            Button {
                                if textStep == 0 {
                                    startTextSequence()
                                } else {
                                    cancelTextSequence()
                                }
                            } label: {
                                Label("文字", systemImage: "text.bubble")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, minHeight: buttonHeight)
                                    .background(.ultraThinMaterial, in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(.thinMaterial)
            }
        }
        .onChange(of: showBackground) { updateAllShownFlag() }
        .onChange(of: showHead) { updateAllShownFlag() }
        .onChange(of: showBody) { updateAllShownFlag() }
        .onChange(of: showBodyLines) { updateAllShownFlag() }
        .onChange(of: showFeet) { updateAllShownFlag() }
        .onChange(of: showMouth) { updateAllShownFlag() }
        .onChange(of: showEyes) { updateAllShownFlag() }
        .onChange(of: showShadows) { updateAllShownFlag() }
        .onChange(of: textStep) { _ in updateAllShownFlag() }
        .animation(.easeInOut(duration: 0.25), value: showBackground)
        .animation(.easeInOut(duration: 0.25), value: showHead)
        .animation(.easeInOut(duration: 0.25), value: showBody)
        // 移除對 showBodyLines 的隱式動畫，改為直接出現
        // 移除對 showFeet 的隱式動畫，改為直接出現
        // 移除對 showShadows 的隱式動畫，改為直接出現
        .animation(.easeInOut(duration: 0.25), value: showMouth)
        .animation(.easeInOut(duration: 0.25), value: showEyes)
        .onDisappear {
            // 離開畫面時確保取消動畫
            textAnimationTask?.cancel()
            textAnimationTask = nil
        }
    }

    // 啟動 4 段 0.5 秒間隔的文字淡入序列
    private func startTextSequence() {
        // 若已在跑，先取消
        textAnimationTask?.cancel()
        textAnimationTask = Task {
            // 從 0 開始
            await MainActor.run {
                textStep = 0
            }
            for i in 1...4 {
                try? await Task.sleep(nanoseconds: 1000_000_000) // 0.5 秒
                if Task.isCancelled { return }
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        textStep = i
                    }
                }
            }
        }
    }

    // 取消文字序列並重置
    private func cancelTextSequence() {
        textAnimationTask?.cancel()
        textAnimationTask = nil
        withAnimation(.easeInOut(duration: 0.2)) {
            textStep = 0
        }
    }

    private func updateAllShownFlag() {
        // 當所有圖層皆為 true 時，isAllShown = true；只要有任何一個 false 則為 false
        let all = showBackground && showHead && showBody && showBodyLines && showFeet && showMouth && showEyes && showShadows && textStep == 4
        isAllShown = all
    }
}

private struct ControlPanel: View {
    @Binding var showBackground: Bool
    @Binding var showHead: Bool
    @Binding var showBody: Bool
    @Binding var showBodyLines: Bool
    @Binding var showFeet: Bool
    @Binding var showMouth: Bool
    @Binding var showEyes: Bool
    @Binding var showShadows: Bool
    @Binding var textStep: Int

    // 由外部注入的控制動作
    var startTextSequence: () -> Void
    var cancelTextSequence: () -> Void

    var body: some View {
        // 不再在主畫面使用，保留型別以免影響其他檔案引用
        EmptyView()
    }
}

private struct ToggleButton: View {
    let title: String
    @Binding var isOn: Bool
    var height: CGFloat = 44

    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                isOn.toggle()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: isOn ? "eye.fill" : "eye.slash")
                Text(title)
            }
            .font(.headline)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(
                (isOn ? Color.green.opacity(0.25) : Color.gray.opacity(0.18)),
                in: Capsule()
            )
        }
        .buttonStyle(.plain) // 取消按下時的預設縮放/高亮效果，維持尺寸不變
    }
}

#Preview {
    Kyrochan()
}

// MARK: - 正規化工具（基準尺寸 600x800）
private enum DesignSpace {
    static let width: CGFloat = 600
    static let height: CGFloat = 800
    static func sx(in rect: CGRect) -> CGFloat { rect.width / width }
    static func sy(in rect: CGRect) -> CGFloat { rect.height / height }
    static func p(_ x: CGFloat, _ y: CGFloat, in rect: CGRect) -> CGPoint {
        CGPoint(x: x * sx(in: rect), y: y * sy(in: rect))
    }
}

struct BodyLine: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        // 使用正規化點，確保不會因外部布局改變而跑位
        p.move(to: DesignSpace.p(167, 321, in: rect))
        p.addLine(to: DesignSpace.p(192, 320, in: rect))
        p.addLine(to: DesignSpace.p(205, 377, in: rect))
        p.addLine(to: DesignSpace.p(245, 377, in: rect))
        p.addLine(to: DesignSpace.p(260, 337, in: rect))
        p.addLine(to: DesignSpace.p(281, 337, in: rect))
        p.addLine(to: DesignSpace.p(300, 409, in: rect))
        p.addLine(to: DesignSpace.p(350, 380, in: rect))
        p.addLine(to: DesignSpace.p(350, 313, in: rect))
        p.addLine(to: DesignSpace.p(372, 301, in: rect))
        p.addLine(to: DesignSpace.p(372, 363, in: rect))
        p.addLine(to: DesignSpace.p(457, 324, in: rect))
        p.addLine(to: DesignSpace.p(457, 302, in: rect))
        p.addLine(to: DesignSpace.p(484, 302, in: rect))
        p.addLine(to: DesignSpace.p(484, 236, in: rect))
        p.addLine(to: DesignSpace.p(167, 236, in: rect))
        p.closeSubpath()
        return p
    }
}

struct LeftFoot: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        // 正規化 LeftFoot 的座標
        p.move(to: DesignSpace.p(272, 488, in: rect))
        p.addLine(to: DesignSpace.p(261, 520, in: rect))
        p.addLine(to: DesignSpace.p(176, 516, in: rect))
        p.addLine(to: DesignSpace.p(173, 526, in: rect))
        p.addLine(to: DesignSpace.p(201, 531, in: rect))
        p.addLine(to: DesignSpace.p(240, 525, in: rect))
        p.addLine(to: DesignSpace.p(167, 535, in: rect))
        p.addLine(to: DesignSpace.p(166, 543, in: rect))
        p.addLine(to: DesignSpace.p(192, 545, in: rect))
        p.addLine(to: DesignSpace.p(263, 535, in: rect))
        p.addLine(to: DesignSpace.p(183, 552, in: rect))
        p.addLine(to: DesignSpace.p(182, 563, in: rect))
        p.addLine(to: DesignSpace.p(201, 560, in: rect))
        p.addLine(to: DesignSpace.p(278, 540, in: rect))
        p.addLine(to: DesignSpace.p(301, 542, in: rect))
        p.addLine(to: DesignSpace.p(303, 534, in: rect))
        p.addLine(to: DesignSpace.p(282, 525, in: rect))
        p.addLine(to: DesignSpace.p(286, 490, in: rect))
        p.closeSubpath()
        return p
    }
}

struct RightFoot: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        // 正規化 RightFoot 的座標
        p.move(to: DesignSpace.p(349, 494, in: rect))
        p.addLine(to: DesignSpace.p(355, 531, in: rect))
        p.addLine(to: DesignSpace.p(332, 541, in: rect))
        p.addLine(to: DesignSpace.p(337, 547, in: rect))
        p.addLine(to: DesignSpace.p(360, 547, in: rect))
        p.addLine(to: DesignSpace.p(455, 570, in: rect))
        p.addLine(to: DesignSpace.p(455, 559, in: rect))
        p.addLine(to: DesignSpace.p(401, 547, in: rect))
        p.addLine(to: DesignSpace.p(468, 554, in: rect))
        p.addLine(to: DesignSpace.p(469, 542, in: rect))
        p.addLine(to: DesignSpace.p(454, 541, in: rect))
        p.addLine(to: DesignSpace.p(403, 533, in: rect))
        p.addLine(to: DesignSpace.p(460, 537, in: rect))
        p.addLine(to: DesignSpace.p(466, 531, in: rect))
        p.addLine(to: DesignSpace.p(455, 525, in: rect))
        p.addLine(to: DesignSpace.p(375, 524, in: rect))
        p.addLine(to: DesignSpace.p(366, 491, in: rect))
        p.closeSubpath()
        return p
    }
}

struct PointedOval: Shape {
    // 0...1，越大越尖（建議 0.0 ~ 0.6 之間）
    var sharpness: CGFloat = 0.4

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width
        let h = rect.height

        let left  = CGPoint(x: 0, y: h/2)
        let right = CGPoint(x: w, y: h/2)
        let top   = CGPoint(x: w/2, y: 0)
        let bottom = CGPoint(x: w/2, y: h)

        // 控制點距離中心的比例，sharpness 越大，左右端越尖
        let kx = (w/2) * (1 - sharpness)
        let ky = (h/2) * (1 - sharpness/2)

        // 使用四段三次貝茲，確保平滑閉合
        p.move(to: left)
        // 左 -> 上
        p.addCurve(to: top,
                   control1: CGPoint(x: 0, y: h/2 - ky),
                   control2: CGPoint(x: w/2 - kx, y: 0))
        // 上 -> 右
        p.addCurve(to: right,
                   control1: CGPoint(x: w/2 + kx, y: 0),
                   control2: CGPoint(x: w, y: h/2 - ky))
        // 右 -> 下
        p.addCurve(to: bottom,
                   control1: CGPoint(x: w, y: h/2 + ky),
                   control2: CGPoint(x: w/2 + kx, y: h))
        // 下 -> 左
        p.addCurve(to: left,
                   control1: CGPoint(x: w/2 - kx, y: h),
                   control2: CGPoint(x: 0, y: h/2 + ky))

        p.closeSubpath()
        return p
    }
}

struct BodyShadow: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: DesignSpace.p(424, 65, in: rect))
        p.addQuadCurve(to: DesignSpace.p(405, 244, in: rect), control: CGPoint(x: 400, y: 200))
        p.addQuadCurve(to: DesignSpace.p(200, 446, in: rect), control: CGPoint(x: 350, y: 420))
        p.addQuadCurve(to: DesignSpace.p(364, 491, in: rect), control: CGPoint(x: 230, y: 450))
        p.addQuadCurve(to: DesignSpace.p(478, 350, in: rect), control: CGPoint(x: 405, y: 390))
        p.addQuadCurve(to: DesignSpace.p(483, 235, in: rect), control: CGPoint(x: 400, y: 235))
        p.addQuadCurve(to: DesignSpace.p(424, 65, in: rect), control: CGPoint(x: 395, y: 80))
        p.closeSubpath()
        return p
    }
}

struct MouthShadow: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: DesignSpace.p(295, 180, in: rect))
        p.addQuadCurve(to: DesignSpace.p(126, 315, in: rect), control: CGPoint(x: 250, y: 261))
        p.addQuadCurve(to: DesignSpace.p(354, 240, in: rect), control: CGPoint(x: 200, y: 310))
        p.addQuadCurve(to: DesignSpace.p(295, 180, in: rect), control: CGPoint(x: 290, y: 170))
        p.closeSubpath()
        return p
    }
}
