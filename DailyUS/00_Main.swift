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
// - Deciding first screen: Onboarding or HomeTabView
struct Main: View {

    // Persist whether onboarding has been completed
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("userRole") private var userRole: String = ""

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
                    // After onboarding completed → show the HomeTabView from 0_Test.swift
                    MainTabView()
                } else {
                    // Use the OnboardingView defined in 0_Test.swift
                    OnboardingView(
                        currentName: userName,
                        currentRole: userRole,
                        onCompleted: { name, role in
                            userName = name
                            userRole = role
                            hasCompletedOnboarding = true
                        }
                    )
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
            try await Task.sleep(nanoseconds: 800_000_000)
            isLoading = false
        } catch {
            loadingError = error.localizedDescription
            isLoading = true
        }
    }
}

#Preview {
    Main()
}
