//
//  ②OnboardingView.swift
//  DailyUS
//
//  Created by 林嘉誠 on 2025/12/2.
//

import SwiftUI

struct OnboardingView: View {
    // External state passed in so we can prefill fields and report back
    @State private var name: String
    @State private var role: String
    @State private var selectedRoleIndex: Int = 0

    // Role options shown to the user
    private let roles = ["男友", "女友", "伴侶"]

    // Callback to inform the parent that onboarding is complete
    var onCompleted: (_ name: String, _ role: String) -> Void

    init(currentName: String, currentRole: String, onCompleted: @escaping (_ name: String, _ role: String) -> Void) {
        self._name = State(initialValue: currentName)
        self._role = State(initialValue: currentRole)

        // Map currentRole to our roles array if possible; default to first item otherwise
        if let idx = roles.firstIndex(of: currentRole), !currentRole.isEmpty {
            self._selectedRoleIndex = State(initialValue: idx)
        } else {
            self._selectedRoleIndex = State(initialValue: 0)
        }

        self.onCompleted = onCompleted
    }

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // App 介紹
                VStack(alignment: .leading, spacing: 8) {
                    Text("歡迎使用 DailyUS")
                        .font(.largeTitle).bold()
                    Text("打造屬於你們的每日互動，增進彼此連結。先設定你的角色與暱稱吧！")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // 角色選擇
                VStack(alignment: .leading, spacing: 8) {
                    Text("選擇你的角色")
                        .font(.headline)
                    Picker("角色", selection: $selectedRoleIndex) {
                        ForEach(roles.indices, id: \.self) { i in
                            Text(roles[i]).tag(i)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // 暱稱輸入
                VStack(alignment: .leading, spacing: 8) {
                    Text("設定暱稱")
                        .font(.headline)
                    TextField("輸入你的暱稱", text: $name)
                        .textInputAutocapitalization(.none)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .padding(12)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                Button {
                    guard isFormValid else { return }
                    let chosenRole = roles[selectedRoleIndex]
                    onCompleted(name.trimmingCharacters(in: .whitespacesAndNewlines), chosenRole)
                } label: {
                    Text("繼續")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .foregroundStyle(.white)
                        .background(isFormValid ? Color.accentColor : Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(!isFormValid)
            }
            .padding(24)
            .navigationTitle("開始使用")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    // Preview with local state
    OnboardingView(currentName: "", currentRole: "", onCompleted: { _, _ in })
}
