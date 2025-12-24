//
//  ③ PairingView.swift
//  DailyUS
//
//  Created by 林嘉誠 on 2025/12/2.
//

import SwiftUI

struct PairingView: View {
    // Persisted coupleID after successful pairing
    @AppStorage("coupleID") private var coupleID: String = ""
    // 必須宣告 userID，避免 Cannot find 'userID' in scope
    @AppStorage("userID") private var userID: String = UUID().uuidString

    // Local UI states
    @State private var pairingCode: String = ""
    @State private var isPairing: Bool = false
    @State private var showSuccessAlert: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("輸入配對碼") {
                    TextField("請輸入配對碼", text: $pairingCode)
                        .textInputAutocapitalization(.none)
                        .autocorrectionDisabled()

                    if isPairing {
                        ProgressView("配對中…")
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }

                    Button {
                        Task { await startPairing() }
                    } label: {
                        Text("開始配對")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(pairingCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isPairing)
                }

                if !coupleID.isEmpty {
                    Section("配對狀態") {
                        HStack {
                            Label("已配對", systemImage: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                            Spacer()
                            Text(coupleID)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                }

                Section("說明") {
                    Text("配對成功後會將 coupleID 儲存在本機（AppStorage），後續可用於雲端同步與共享資料。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("配對")
            .alert("配對成功！", isPresented: $showSuccessAlert) {
                Button("OK") {}
            } message: {
                Text("已成功綁定另一半，開始使用 DailyUS 吧！")
            }
        }
    }

    // MARK: - Pairing Logic (Firestore)
    @MainActor
    private func startPairing() async {
        errorMessage = nil
        isPairing = true
        do {
            let code = pairingCode.trimmingCharacters(in: .whitespacesAndNewlines)
            let targetCoupleID = "couple_\(code)" // 先以配對碼生成 ID；未來可改為由後端產生/驗證

            // 嘗試抓取現有 couple
            if let existing = try? await Cloud.shared.fetchCouple(id: targetCoupleID) {
                var updated = existing
                if !updated.userIDs.contains(userID) {
                    updated.userIDs.append(userID)
                }
                updated.updatedAt = Date()
                let _ = try await Cloud.shared.updateCouple(updated)
                coupleID = targetCoupleID
            } else {
                // 建立新的 couple
                var newCouple = Couple(id: targetCoupleID, userIDs: [userID], startedAt: nil, createdAt: Date(), updatedAt: Date())
                newCouple = try await Cloud.shared.createCouple(newCouple)
                coupleID = newCouple.id
            }

            showSuccessAlert = true
            isPairing = false
        } catch {
            errorMessage = error.localizedDescription
            isPairing = false
        }
    }
}

#Preview {
    PairingView()
}
