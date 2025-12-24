//
//  AddBackground.swift
//  DailyUS
//
//  Created by 陳芸萱 on 2025/12/15.
//

import SwiftUI

struct AddBackground: View {
    var body: some View {
        
        TabView {
            NavigationStack {
                ZStack {
                    Background(image: Image("Back_1"))
                    DailyDashboardView()
                }
            }
            .tabItem {
                Label("Daily", systemImage: "sun.max")
            }

            NavigationStack {
                ZStack {
                    Background(image: Image("Back_5"))
                    InteractDashboardView()
                }
            }
            .tabItem {
                Label("Interact", systemImage: "heart")
            }

            NavigationStack {
                ZStack {
                    Background(image: Image("Back_3"))
                    MemoryDashboardView()
                }
            }
            .tabItem {
                Label("Memory", systemImage: "clock.arrow.circlepath")
            }

            NavigationStack {
                ZStack {
                    Background(image: Image("Back_4"))
                    ProfileView()
                }
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
        }
    }
}

#Preview {
    AddBackground()
}
