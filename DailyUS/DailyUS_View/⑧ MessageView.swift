//
//  ⑧ MessageView.swift
//  DailyUS
//
//  Created by 陳芸萱 on 2025/12/2.
//

import SwiftUI
import AVFoundation
import Combine
import FirebaseFirestore
import FirebaseStorage

// MARK: - Model
struct MessageItem: Identifiable, Equatable {
    enum Kind: Equatable {
        case text(String)
        case audio(URL, duration: TimeInterval) // URL 可為遠端或本地，但本方案會給遠端下載 URL
    }
    let id: UUID
    let date: Date
    let sender: String // "me" or "partner"
    let kind: Kind
}

// MARK: - Uploader protocol
protocol MessageUploading {
    func uploadText(_ text: String) async throws
    func uploadAudio(fileURL: URL, duration: TimeInterval) async throws
    func fetchHistory() async throws -> [MessageItem]
}

// MARK: - Firestore + Storage 版
struct FirestoreMessageUploader: MessageUploading {
    @AppStorage("coupleID") private var coupleID: String = ""
    @AppStorage("userID") private var userID: String = UUID().uuidString

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    // Firestore: 新增文字訊息
    func uploadText(_ text: String) async throws {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !coupleID.isEmpty else { throw CloudSyncError.permissionDenied }

        let now = Date()
        let data: [String: Any] = [
            "coupleID": coupleID,
            "fromUserID": userID,
            "type": "text",
            "text": trimmed,
            "createdAt": now,
            "updatedAt": now
        ]

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            db.collection("messages").addDocument(data: data) { error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: ()) }
            }
        }
    }

    // Storage: 上傳音檔，Firestore: 存中繼資料（downloadURL + duration）
    func uploadAudio(fileURL: URL, duration: TimeInterval) async throws {
        guard !coupleID.isEmpty else { throw CloudSyncError.permissionDenied }

        let fileID = UUID().uuidString
        let path = "messages/\(coupleID)/\(fileID).m4a"
        let ref = storage.reference(withPath: path)

        // 1) 上傳檔案到 Storage
        let metadata = StorageMetadata()
        metadata.contentType = "audio/m4a"
        _ = try await ref.putFileAsync(from: fileURL, metadata: metadata)

        // 2) 取得下載 URL
        let url = try await ref.downloadURL()

        // 3) 寫 Firestore 訊息（type: "audio"）
        let now = Date()
        let data: [String: Any] = [
            "coupleID": coupleID,
            "fromUserID": userID,
            "type": "audio",
            "audioURL": url.absoluteString,
            "duration": duration,
            "createdAt": now,
            "updatedAt": now
        ]
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            db.collection("messages").addDocument(data: data) { error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume(returning: ()) }
            }
        }
    }

    // Firestore: 讀取歷史（文字 + 語音）
    func fetchHistory() async throws -> [MessageItem] {
        guard !coupleID.isEmpty else { return [] }

        let query = db.collection("messages")
            .whereField("coupleID", isEqualTo: coupleID)
            .order(by: "createdAt", descending: true)
            .limit(to: 50)

        let snap = try await query.getDocuments()
        let items: [MessageItem] = snap.documents.compactMap { doc in
            let data = doc.data()
            let fromUser = data["fromUserID"] as? String ?? ""
            let sender = (fromUser == userID) ? "me" : "partner"

            // createdAt 可能是 Date 或 Timestamp
            let date: Date
            if let d = data["createdAt"] as? Date {
                date = d
            } else if let ts = data["createdAt"] as? Timestamp {
                date = ts.dateValue()
            } else if
                let tsObj = data["createdAt"] as? NSObject,
                let d = tsObj.value(forKey: "dateValue") as? Date {
                date = d
            } else {
                date = Date()
            }

            let type = (data["type"] as? String) ?? (data["text"] != nil ? "text" : "audio")

            if type == "text" {
                guard let text = data["text"] as? String else { return nil }
                return MessageItem(id: UUID(), date: date, sender: sender, kind: .text(text))
            } else if type == "audio" {
                guard
                    let urlStr = data["audioURL"] as? String,
                    let remoteURL = URL(string: urlStr)
                else { return nil }
                let duration = (data["duration"] as? Double) ?? 0
                return MessageItem(id: UUID(), date: date, sender: sender, kind: .audio(remoteURL, duration: duration))
            } else {
                return nil
            }
        }
        return items
    }
}

// MARK: - Audio Recorder Helper
final class AudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var isRecording: Bool = false
    @Published var currentDuration: TimeInterval = 0

    private var recorder: AVAudioRecorder?
    private var timer: Timer?

    func startRecording() throws {
        try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try AVAudioSession.sharedInstance().setActive(true)

        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        let url = Self.tempRecordingURL()
        recorder = try AVAudioRecorder(url: url, settings: settings)
        recorder?.delegate = self
        recorder?.isMeteringEnabled = true
        guard recorder?.record() == true else { throw RecorderError.failedToRecord }

        isRecording = true
        currentDuration = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self, let rec = self.recorder else { return }
            self.currentDuration = rec.currentTime
        }
    }

    func stopRecording() -> (url: URL, duration: TimeInterval)? {
        recorder?.stop()
        timer?.invalidate()
        timer = nil

        isRecording = false
        defer { recorder = nil }

        guard let rec = recorder else { return nil }
        return (rec.url, rec.currentTime)
    }

    func requestPermission() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                if granted {
                    continuation.resume(returning: ())
                } else {
                    continuation.resume(throwing: RecorderError.permissionDenied)
                }
            }
        }
    }

    static func tempRecordingURL() -> URL {
        let fileName = "msg-\(UUID().uuidString).m4a"
        return FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
    }

    enum RecorderError: Error {
        case permissionDenied
        case failedToRecord
    }
}

// MARK: - Remote audio fetcher (download remote URL to local temp for AVAudioPlayer)
actor AudioCache {
    static let shared = AudioCache()
    private var cache: [URL: URL] = [:] // remoteURL -> localFileURL

    func localURL(for remoteURL: URL) async throws -> URL {
        if let local = cache[remoteURL], FileManager.default.fileExists(atPath: local.path) {
            return local
        }
        // Download
        let (data, _) = try await URLSession.shared.data(from: remoteURL)
        let local = FileManager.default.temporaryDirectory.appendingPathComponent("dl-\(UUID().uuidString).m4a")
        try data.write(to: local)
        cache[remoteURL] = local
        return local
    }
}

// MARK: - Audio Player Helper
final class AudioPlayer: ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var progress: Double = 0 // 0.0 ~ 1.0
    @Published var isLoading: Bool = false

    private var player: AVAudioPlayer?
    private var timer: Timer?

    func play(from remoteOrLocalURL: URL) {
        Task { @MainActor in
            stop()
            isLoading = true
            do {
                let localURL: URL
                if remoteOrLocalURL.isFileURL {
                    localURL = remoteOrLocalURL
                } else {
                    localURL = try await AudioCache.shared.localURL(for: remoteOrLocalURL)
                }
                let p = try AVAudioPlayer(contentsOf: localURL)
                player = p
                p.prepareToPlay()
                p.play()
                isPlaying = true
                isLoading = false
                startTimer()
            } catch {
                isPlaying = false
                isLoading = false
            }
        }
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        progress = 0
        timer?.invalidate()
        timer = nil
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self, let p = self.player else { return }
            if p.duration > 0 {
                self.progress = p.currentTime / p.duration
            }
            if !p.isPlaying {
                self.stop()
            }
        }
    }
}

// MARK: - View
struct MessageView: View {
    // UI states
    @State private var text: String = ""
    @State private var isUploading: Bool = false
    @State private var uploadError: String?

    @State private var messages: [MessageItem] = []
    @State private var isLoadingHistory: Bool = true

    // Recording
    @StateObject private var recorder = AudioRecorder()
    @StateObject private var player = AudioPlayer()

    // Animations & accessibility
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse: Bool = false

    // Uploader（Firestore + Storage）
    private let uploader: MessageUploading = FirestoreMessageUploader()

    var body: some View {
        ZStack {
            // 背景圖層
            Background(image: Image("Back_1"))
                .opacity(0.5)

            // 內容圖層
            VStack(spacing: 12) {
                header
                historyList
                inputArea
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .navigationTitle("傳訊息")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadHistory()
        }
        .onAppear {
            if !reduceMotion { pulse = true }
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.green.opacity(0.18))
                    .frame(width: 44, height: 44)
                    .scaleEffect(reduceMotion ? 1.0 : (pulse ? 1.05 : 0.95))
                    .animation(reduceMotion ? nil : .easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
                Image(systemName: "paperplane.fill")
                    .foregroundStyle(.green)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text("給對方訊息")
                    .font(.headline)
                Text("錄音或文字，上傳並查看歷史")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isLoadingHistory {
                ProgressView()
            }
        }
    }

    // MARK: - History
    private var historyList: some View {
        Group {
            if messages.isEmpty {
                VStack(spacing: 8) {
                    if isLoadingHistory {
                        EmptyView()
                    } else {
                        Text("尚無訊息")
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 160)
            } else {
                List {
                    ForEach(messages) { item in
                        MessageRow(item: item, player: player)
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Input
    private var inputArea: some View {
        VStack(spacing: 10) {
            HStack(alignment: .bottom, spacing: 8) {
                TextField("輸入文字訊息…", text: $text, axis: .vertical)
                    .lineLimit(3, reservesSpace: true)
                    .textFieldStyle(.roundedBorder)

                Button {
                    Task { await sendText() }
                } label: {
                    if isUploading {
                        ProgressView().scaleEffect(0.9)
                    } else {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 26))
                    }
                }
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isUploading)
                .accessibilityLabel("送出文字")
            }

            HStack(spacing: 12) {
                Button {
                    Task { await toggleRecordingAndUpload() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: recorder.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                        Text(recorder.isRecording ? "停止並上傳" : "開始錄音")
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(recorder.isRecording ? Color.red : Color.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                if recorder.isRecording {
                    Text(timeString(recorder.currentDuration))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("已錄音 \(Int(recorder.currentDuration)) 秒")
                }

                Spacer()
            }

            if let uploadError {
                Text(uploadError)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .padding(.top, 6)
    }

    // MARK: - Actions
    @MainActor
    private func loadHistory() async {
        isLoadingHistory = true
        do {
            let items = try await uploader.fetchHistory()
            messages = items
            isLoadingHistory = false
        } catch {
            isLoadingHistory = false
            uploadError = localizedFirestoreError(error)
        }
    }

    @MainActor
    private func sendText() async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        uploadError = nil
        isUploading = true
        do {
            try await uploader.uploadText(trimmed)
            text = ""
            isUploading = false
            await loadHistory()
        } catch {
            isUploading = false
            uploadError = localizedFirestoreError(error)
        }
    }

    @MainActor
    private func toggleRecordingAndUpload() async {
        if recorder.isRecording {
            // 停止錄音並上傳
            guard let result = recorder.stopRecording() else { return }
            uploadError = nil
            isUploading = true
            do {
                try await uploader.uploadAudio(fileURL: result.url, duration: result.duration)
                isUploading = false
                await loadHistory()
            } catch {
                isUploading = false
                uploadError = localizedStorageError(error)
            }
        } else {
            do {
                try await recorder.requestPermission()
                try recorder.startRecording()
            } catch {
                uploadError = "無法開始錄音：\(error.localizedDescription)"
            }
        }
    }

    private func timeString(_ t: TimeInterval) -> String {
        let s = Int(t)
        let mm = s / 60
        let ss = s % 60
        return String(format: "%02d:%02d", mm, ss)
    }

    private func localizedFirestoreError(_ error: Error) -> String {
        let msg = (error as NSError).localizedDescription
        if msg.localizedCaseInsensitiveContains("FAILED_PRECONDITION") || msg.localizedCaseInsensitiveContains("index") {
            return "查詢需要建立索引，請至 Firebase Console 建立索引後再試"
        }
        if msg.localizedCaseInsensitiveContains("PERMISSION_DENIED") {
            return "權限不足，請檢查 Firestore 規則"
        }
        return "操作失敗，請稍後重試（\(msg)）"
    }

    private func localizedStorageError(_ error: Error) -> String {
        let msg = (error as NSError).localizedDescription
        if msg.localizedCaseInsensitiveContains("object") && msg.localizedCaseInsensitiveContains("not found") {
            return "找不到檔案，請稍後重試"
        }
        if msg.localizedCaseInsensitiveContains("unauthorized") || msg.localizedCaseInsensitiveContains("permission") {
            return "沒有上傳權限，請檢查 Storage 規則"
        }
        return "上傳失敗，請稍後重試（\(msg)）"
    }
}

// MARK: - Row
private struct MessageRow: View {
    let item: MessageItem
    @ObservedObject var player: AudioPlayer

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            icon
            content
            Spacer()
            Text(item.date, style: .time)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private var icon: some View {
        switch item.kind {
        case .text:
            Image(systemName: "text.bubble.fill")
                .foregroundStyle(.blue)
        case .audio:
            Image(systemName: "waveform.circle.fill")
                .foregroundStyle(.orange)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch item.kind {
        case .text(let text):
            Text(text)
                .font(.body)
                .multilineTextAlignment(.leading)
        case .audio(let url, let duration):
            HStack(spacing: 10) {
                Button {
                    if player.isPlaying {
                        player.stop()
                    } else {
                        player.play(from: url)
                    }
                } label: {
                    HStack(spacing: 6) {
                        if player.isLoading {
                            ProgressView().scaleEffect(0.8).tint(.white)
                        } else {
                            Image(systemName: player.isPlaying ? "stop.fill" : "play.fill")
                        }
                    }
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(player.isPlaying ? Color.red : Color.orange)
                    .clipShape(Capsule())
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("語音訊息")
                        .font(.subheadline)
                    ProgressView(value: player.progress)
                        .progressViewStyle(.linear)
                        .frame(width: 120)
                        .tint(.orange)
                }

                Text(timeString(duration))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func timeString(_ t: TimeInterval) -> String {
        let s = Int(t.rounded())
        let mm = s / 60
        let ss = s % 60
        return String(format: "%02d:%02d", mm, ss)
    }
}

#Preview {
    NavigationStack {
        MessageView()
    }
}

