//
//  ⑰ ProfileView.swift
//  DailyUS
//
//  Created by 陳芸萱 on 2025/12/2.
//

import SwiftUI

struct ProfileView: View {
    // Persisted values
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("coupleID") private var coupleID: String = ""
    @AppStorage("userID") private var userID: String = UUID().uuidString

    // Local UI state
    @State private var pushEnabled: Bool = true
    @State private var backupStatus: String = "未備份"
    @State private var versionTapCount: Int = 0
    @State private var showEasterEgg: Bool = false

    // Re-pairing UI states
    @State private var showRePairSheet: Bool = false
    @State private var newPairingCode: String = ""
    @State private var isRePairing: Bool = false
    @State private var rePairError: String?
    @State private var showRePairSuccessAlert: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section("個人資料") {
                    TextField("暱稱", text: $userName)
                        .textInputAutocapitalization(.none)
                        .autocorrectionDisabled()

                    HStack {
                        Text("配對狀態")
                        Spacer()
                        Text(coupleID.isEmpty ? "未配對" : "已配對")
                            .foregroundStyle(coupleID.isEmpty ? .red : .green)
                    }
                    if !coupleID.isEmpty {
                        HStack {
                            Text("Couple ID")
                            Spacer()
                            Text(coupleID)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                }

                Section("設定") {
                    Toggle("推播通知", isOn: $pushEnabled)

                    HStack {
                        Text("備份狀態")
                        Spacer()
                        Text(backupStatus)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        Task {
                            backupStatus = "備份中…"
                            try? await Task.sleep(nanoseconds: 400_000_000)
                            backupStatus = "已備份"
                        }
                    } label: {
                        Label("立即備份（模擬）", systemImage: "arrow.triangle.2.circlepath")
                    }
                }

                Section("配對") {
                    Button {
                        newPairingCode = ""
                        rePairError = nil
                        showRePairSheet = true
                    } label: {
                        Label("重新設定配對碼", systemImage: "link.badge.plus")
                    }
                    .foregroundColor(.blue)

                    if isRePairing {
                        HStack {
                            ProgressView()
                            Text("重新配對中…")
                                .foregroundStyle(.secondary)
                        }
                        Button(role: .cancel) {
                            // 立即讓 UI 脫離「處理中」
                            isRePairing = false
                            rePairError = "已取消"
                        } label: {
                            Text("取消處理")
                        }
                    }
                    if let rePairError {
                        Text(rePairError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

                Section("關於") {
                    Button {
                        versionTapCount += 1
                        if versionTapCount >= 5 {
                            versionTapCount = 0
                            showEasterEgg = true
                        }
                    } label: {
                        HStack {
                            Text("版本")
                            Spacer()
                            Text(appVersionString())
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityLabel("版本 \(appVersionString())。連點五下可開啟隱藏彩蛋")
                }

                // MARK: - 開發工具：寫入一筆測試歌曲到 Firestore
                Section("開發工具") {
                    Button {
                        createSong()
                    } label: {
                        Label("寫入測試歌曲到 Firestore", systemImage: "icloud.and.arrow.up")
                    }
                    .accessibilityLabel("寫入測試歌曲到 Firestore")
                    .foregroundColor(.blue)
                }
            }
            .safeAreaInset(edge: .top) {
                Color.clear.frame(height: 24)
            }
            .listSectionSpacing(.custom(12))
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .navigationTitle("Profile")
            .navigationDestination(isPresented: $showEasterEgg) {
                DeveloperEasterEggView()
            }
            .sheet(isPresented: $showRePairSheet) {
                RePairSheet(
                    pairingCode: $newPairingCode,
                    isProcessing: $isRePairing,
                    errorMessage: $rePairError,
                    onConfirm: { code in
                        Task { await rePair(with: code) }
                    },
                    onCancel: {
                        // 使用者從 sheet 取消時，確保 UI 狀態回復
                        isRePairing = false
                        rePairError = nil
                        showRePairSheet = false
                    }
                )
                .presentationDetents([.medium])
            }
            .alert("重新配對成功！", isPresented: $showRePairSuccessAlert) {
                Button("OK") {}
            } message: {
                Text("已綁定新的配對碼，之後的資料將同步到新的 Couple。")
            }
        }
        .background(Color.clear)
    }

    private func appVersionString() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        return "\(version) (\(build))"
    }

    // MARK: - Re-pairing with Firebase（加入超時、日誌與明確錯誤）
    @MainActor
    private func rePair(with code: String) async {
        rePairError = nil
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            rePairError = "請輸入配對碼"
            return
        }

        isRePairing = true
        let targetCoupleID = "couple_\(trimmed)"
        print("[RePair] start for \(targetCoupleID) userID=\(userID)")

        do {
            try await withTimeout(seconds: 6) {
                try await performRePair(coupleID: targetCoupleID)
            }
            print("[RePair] success for \(targetCoupleID)")
            isRePairing = false
            showRePairSheet = false
            showRePairSuccessAlert = true
        } catch {
            print("[RePair] failed:", error.localizedDescription)
            isRePairing = false
            rePairError = localizedErrorMessage(error)
        }
    }

    // 真正呼叫 Cloud.shared 的流程，加入日誌
    private func performRePair(coupleID targetCoupleID: String) async throws {
        do {
            print("[RePair] fetchCouple \(targetCoupleID)")
            let existing = try await Cloud.shared.fetchCouple(id: targetCoupleID)
            print("[RePair] fetched existing couple")
            var updated = existing
            if !updated.userIDs.contains(userID) {
                updated.userIDs.append(userID)
            }
            updated.updatedAt = Date()
            print("[RePair] updateCouple \(targetCoupleID)")
            _ = try await Cloud.shared.updateCouple(updated)
            self.coupleID = targetCoupleID
        } catch {
            if case CloudSyncError.notFound = error {
                print("[RePair] couple not found, createCouple \(targetCoupleID)")
                var newCouple = Couple(
                    id: targetCoupleID,
                    userIDs: [userID],
                    startedAt: nil,
                    createdAt: Date(),
                    updatedAt: Date()
                )
                newCouple = try await Cloud.shared.createCouple(newCouple)
                self.coupleID = newCouple.id
            } else {
                throw error
            }
        }
    }

    // 包裝一個通用超時工具
    private func withTimeout(seconds: Double, operation: @escaping () async throws -> Void) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { try await operation() }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw CloudSyncError.network // 作為逾時錯誤
            }
            do {
                try await group.next()
                group.cancelAll()
            } catch {
                group.cancelAll()
                throw error
            }
        }
    }

    private func localizedErrorMessage(_ error: Error) -> String {
        let msg = (error as NSError).localizedDescription
        if msg.localizedCaseInsensitiveContains("FAILED_PRECONDITION") ||
            msg.localizedCaseInsensitiveContains("index") {
                return "查詢需要建立索引，請至 Firebase Console 建立索引後再試"
        }
        if msg.localizedCaseInsensitiveContains("PERMISSION_DENIED") {
            return "權限不足，請檢查 Firestore 安全規則"
        }
        if case CloudSyncError.network = error {
            return "連線逾時或網路異常，請稍後再試"
        }
        return msg
    }
}

// MARK: - RePair Sheet UI
private struct RePairSheet: View {
    @Binding var pairingCode: String
    @Binding var isProcessing: Bool
    @Binding var errorMessage: String?

    var onConfirm: (String) -> Void
    var onCancel: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("輸入新的配對碼") {
                    TextField("請輸入配對碼", text: $pairingCode)
                        .textInputAutocapitalization(.none)
                        .autocorrectionDisabled()
                }
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
                Section {
                    Button {
                        onConfirm(pairingCode)
                    } label: {
                        if isProcessing {
                            HStack {
                                ProgressView()
                                Text("處理中…")
                            }
                        } else {
                            Label("確認重新配對", systemImage: "checkmark.seal")
                        }
                    }
                    .disabled(isProcessing || pairingCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("重新設定配對碼")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        onCancel()
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileView()
}

