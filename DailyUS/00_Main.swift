//
//  Main.swift
//  DailyUS
//
//  Created by 林嘉誠 on 2025/12/2.
//

import SwiftUI

// Root view responsible for:
// - Starting the app UI
// - Managing AppStorage and (simulated) cloud loading state
// - Deciding first screen: Onboarding or MainTabView
struct Main: View {

    // Persist whether onboarding has been completed
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false

    // Whether initial data is loading (e.g., cloud sync, configuration fetch)
    @State private var isLoading: Bool = true

    // Optional: capture an error from loading
    @State private var loadingError: String?

    var body: some View {
        Group {
            if isLoading {
                // Simple splash/progress UI during initial load
                VStack(spacing: 12) {
                    ProgressView("正在載入…")
                    if let loadingError {
                        Text(loadingError)
                            .foregroundStyle(.red)
                            .font(.footnote)
                        Button("重試") {
                            Task { await performInitialLoad() }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                if hasCompletedOnboarding {
                    // After onboarding completed
                    MainTabView()
                } else {
                    // Show onboarding and handle completion
                    OnboardingView(onCompleted: {
                        hasCompletedOnboarding = true
                    })
                }
            }
        }
        .task {
            // Perform initial loading when the view first appears
            await performInitialLoad()
        }
    }

    // Simulate or perform your real cloud/data initialization here
    @MainActor
    private func performInitialLoad() async {
        loadingError = nil
        isLoading = true
        do {
            // Replace with your real initialization logic:
            // e.g., await CloudManager.shared.initialize()
            try await Task.sleep(nanoseconds: 800_000_000) // ~0.8s simulated delay
            // If you need to read a flag from cloud to override onboarding, do it here.
            // Example:
            // hasCompletedOnboarding = await CloudManager.shared.hasCompletedOnboarding
            isLoading = false
        } catch {
            loadingError = error.localizedDescription
            isLoading = true
        }
    }
}

// Placeholder for OnboardingView; implement this in your own file.
// The onCompleted closure should be called when onboarding finishes.
private struct OnboardingView: View {
    var onCompleted: () -> Void
    var body: some View {
        VStack(spacing: 16) {
            Text("Onboarding")
                .font(.title)
            Text("這裡是新手引導頁面。")
            Button("完成") {
                onCompleted()
            }
        }
        .padding()
    }
}

// Placeholder for MainTabView; implement your real tab structure elsewhere.
private struct MainTabView: View {
    var body: some View {
        TabView {
            TemplateUS()
                .tabItem {
                    Label("首頁", systemImage: "house")
                }
            User()
                .tabItem {
                    Label("使用者", systemImage: "person")
                }
        }
    }
}

#Preview {
    Main()
}
