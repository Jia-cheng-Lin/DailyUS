//
//  ContentView.swift
//  Game
//
//  Created by 陳芸萱 on 2025/11/20.
//

import SwiftUI

struct Bill: View {
    var body: some View {
        TabView {
            // 第一個分頁：Bill（AboutBill + Acknowledger 合併成一個 Section）
            NavigationStack {
                ZStack {
                    Background(image: Image("Back_7"))
                        .opacity(0.5)

                    List {
                        Section("嘉誠的一些紀錄") {
                            // About Bill
                            NavigationLink {
                                AboutBill()
                            } label: {
                                HStack(spacing: 12) {
                                    Image("Bill")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 56, height: 56)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
                                        )
                                        .accessibilityHidden(true)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("About Bill")
                                            .font(.headline)
                                        Text("個人介紹")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer(minLength: 0)
                                }
                                .padding(.vertical, 4)
                            }

                            // Acknowledger
                            NavigationLink {
                                Acknowledger()
                            } label: {
                                HStack(spacing: 12) {
                                    // 若有專屬圖示可改為 Image("acknowledgerIcon")
                                    Image("Logo")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 56, height: 56)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
                                        )
                                        .accessibilityHidden(true)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Acknowledger")
                                            .font(.headline)
                                        Text("上課筆記/演講心得")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer(minLength: 0)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)   // 讓 List 背景透明
                    .background(Color.clear)            // 保險起見
                    .navigationTitle("Information")
                    .padding(.top, 60)
                }
            }
            .tabItem {
                Label("Information", systemImage: "person.text.rectangle.fill")
            }

            // 第二個分頁：Game
            NavigationStack {
                ZStack {
                    Background(image: Image("Back_7"))
                        .opacity(0.5)

                    List {
                        Section("已上線遊戲") {
                            NavigationLink {
                                Hangman()
                            } label: {
                                HStack(spacing: 12) {
                                    Image("Hangman")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 56, height: 56)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
                                        )
                                        .accessibilityHidden(true)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Hangman")
                                            .font(.headline)
                                        Text("猜字遊戲")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer(minLength: 0)
                                }
                                .padding(.vertical, 4)
                            }

                            NavigationLink {
                                PigDice()
                            } label: {
                                HStack(spacing: 12) {
                                    Image("PigDice")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 56, height: 56)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
                                        )
                                        .accessibilityHidden(true)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Pig Dice")
                                            .font(.headline)
                                        Text("骰子遊戲")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer(minLength: 0)
                                }
                                .padding(.vertical, 4)
                            }

                            NavigationLink {
                                Kyrochan()
                            } label: {
                                HStack(spacing: 12) {
                                    Image("kyorochan")
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 56, height: 56)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(Color.secondary.opacity(0.2), lineWidth: 0.5)
                                        )
                                        .accessibilityHidden(true)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Kyorochan")
                                            .font(.headline)
                                        Text("圖形設計")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer(minLength: 0)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)   // 讓 List 背景透明
                    .background(Color.clear)            // 保險起見
                    .navigationTitle("Game")
                    .padding(.top, 60)
                }
            }
            .tabItem {
                Label("Game", systemImage: "gamecontroller")
            }
        }
    }
}

#Preview {
    Bill()
}
