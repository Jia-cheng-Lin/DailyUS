//
//  ④ MainTabView.swift
//  DailyUS
//
//  Created by 林嘉誠 on 2025/12/2.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        
        TabView {
            NavigationStack {
                DailyDashboardView()
            }
            .tabItem {
                Label("Daily", systemImage: "sun.max")
            }

            NavigationStack {
                InteractDashboardView()
            }
            .tabItem {
                Label("Interact", systemImage: "heart")
            }

            NavigationStack {
                MemoryDashboardView()
            }
            .tabItem {
                Label("Memory", systemImage: "clock.arrow.circlepath")
            }

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
        }
    }
}

#Preview {
    MainTabView()
}

