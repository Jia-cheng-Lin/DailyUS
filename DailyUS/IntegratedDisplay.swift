//
//  IntegratedDisplay.swift
//  DailyUS
//
//  Created by 陳芸萱 on 2025/12/5.
//

import SwiftUI

// MARK: - Integrated App Flow Root
// App Launch → Onboarding → Couple Pairing → Main Tabs
struct IntegratedDisplayRoot: View {
    // AppStorage (local cache)
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userRole") private var userRole: String = "" // 例如 "男友" / "女友" / "伴侶"
    @AppStorage("userID") private var userID: String = UUID().uuidString
    @AppStorage("coupleID") private var coupleID: String = ""

    // Launch state
    @State private var isLaunching: Bool = true
    @State private var launchError: String?

    var body: some View {
        Group {
            if isLaunching {
                launchView
            } else {
                flowView
            }
        }
        .task {
            await performLaunch()
        }
    }

    // MARK: Launch
    private var launchView: some View {
        VStack(spacing: 12) {
            ProgressView("啟動中…")
            if let launchError {
                Text(launchError)
                    .foregroundStyle(.red)
                    .font(.footnote)
                Button("重試") {
                    Task { await performLaunch() }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Flow Decision
    @ViewBuilder
    private var flowView: some View {
        if !hasCompletedOnboarding {
            // 使用 ② OnboardingView.swift 的 OnboardingViewTest
            OnboardingView(
                currentName: userName,
                currentRole: userRole,
                onCompleted: { name, role in
                    userName = name
                    userRole = role
                    hasCompletedOnboarding = true
                }
            )
        } else if coupleID.isEmpty {
            // 使用 ③ PairingView.swift
            PairingView()
        } else {
            // 使用 ④ MainTabView.swift（包含 Daily / Interact / Memory / Profile）
            MainTabView()
        }
    }

    // MARK: Simulated launch initialization
    @MainActor
    private func performLaunch() async {
        launchError = nil
        isLaunching = true
        do {
            // 可替換為 CloudKit / Firebase 初始化與本地快取載入
            try await Task.sleep(nanoseconds: 500_000_000)
            isLaunching = false
        } catch {
            launchError = error.localizedDescription
            isLaunching = true
        }
    }
}

// MARK: - Preview
struct IntegratedDisplay_Previews: PreviewProvider {
    static var previews: some View {
        IntegratedDisplayRoot()
    }
}
