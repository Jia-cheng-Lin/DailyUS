////
////  0_Test.swift
////  DailyUS
////
////  Created by 林嘉誠 on 2025/12/2.
////
////
////
////   先存檔作為備份
////
//
//import SwiftUI
//
//// MARK: - App Flow Root (Launch → Onboarding → Pairing → Home)
//struct TestRoot: View {
//    // AppStorage keys
//    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
//    @AppStorage("userName") private var userName: String = ""
//    @AppStorage("userRole") private var userRole: String = "" // 例如 "Boy" / "Girl" 或自定義
//    @AppStorage("userID") private var userID: String = UUID().uuidString // 初次預設一個本地 ID
//    @AppStorage("coupleID") private var coupleID: String = "" // 只有配對成功才會有
//
//    // Launch/loading state
//    @State private var isLaunching: Bool = true
//    @State private var launchError: String?
//
//    var body: some View {
//        Group {
//            if isLaunching {
//                VStack(spacing: 12) {
//                    ProgressView("啟動中…")
//                    if let launchError {
//                        Text(launchError)
//                            .foregroundStyle(.red)
//                            .font(.footnote)
//                        Button("重試") {
//                            Task { await performLaunch() }
//                        }
//                    }
//                }
//                .frame(maxWidth: .infinity, maxHeight: .infinity)
//            } else {
//                // Flow decision
//                if !hasCompletedOnboarding {
//                    OnboardingView(
//                        currentName: userName,
//                        currentRole: userRole,
//                        onCompleted: { name, role in
//                            userName = name
//                            userRole = role
//                            hasCompletedOnboarding = true
//                        }
//                    )
//                } else if coupleID.isEmpty {
//                    CouplePairingView(
//                        userID: userID,
//                        onPaired: { newCoupleID in
//                            coupleID = newCoupleID
//                        }
//                    )
//                } else {
//                    HomeTabView()
//                }
//            }
//        }
//        .task {
//            await performLaunch()
//        }
//    }
//
//    // MARK: - Simulated Launch Initialization
//    @MainActor
//    private func performLaunch() async {
//        launchError = nil
//        isLaunching = true
//        do {
//            // 模擬啟動時初始化（可替換為 CloudKit / Firebase 初始化）
//            try await Task.sleep(nanoseconds: 500_000_000)
//            isLaunching = false
//        } catch {
//            launchError = error.localizedDescription
//            isLaunching = true
//        }
//    }
//}
//
//// MARK: - Onboarding
//struct OnboardingViewTests: View {
//    @State private var name: String
//    @State private var role: String
//    @State private var selectedRoleIndex: Int = 0
//
//    let roles = ["我是男友", "我是女友", "其他"]
//    var onCompleted: (_ name: String, _ role: String) -> Void
//
//    init(currentName: String, currentRole: String, onCompleted: @escaping (_ name: String, _ role: String) -> Void) {
//        self._name = State(initialValue: currentName)
//        self._role = State(initialValue: currentRole)
//        // 對應 roles 的初始 index
//        if let idx = roles.firstIndex(of: currentRole), !currentRole.isEmpty {
//            self._selectedRoleIndex = State(initialValue: idx)
//        }
//        self.onCompleted = onCompleted
//    }
//
//    var body: some View {
//        NavigationStack {
//            Form {
//                Section("App 介紹") {
//                    Text("歡迎來到 DailyUS！這是一款幫助情侶每日互動、留下回憶的 App。")
//                }
//                Section("設定使用者") {
//                    TextField("請輸入暱稱", text: $name)
//                    Picker("我是誰", selection: $selectedRoleIndex) {
//                        ForEach(roles.indices, id: \.self) { i in
//                            Text(roles[i]).tag(i)
//                        }
//                    }
//                }
//            }
//            .navigationTitle("Onboarding")
//            .toolbar {
//                ToolbarItem(placement: .confirmationAction) {
//                    Button("開始使用") {
//                        let finalRole = roles[selectedRoleIndex]
//                        onCompleted(name.isEmpty ? "User" : name, finalRole)
//                    }
//                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
//                }
//            }
//        }
//    }
//}
//
//// MARK: - Couple Pairing
//struct CouplePairingView: View {
//    let userID: String
//    @State private var pairingCode: String = ""
//    @State private var isPairing: Bool = false
//    @State private var showSuccessAlert: Bool = false
//    @State private var errorMessage: String?
//
//    var onPaired: (String) -> Void
//
//    var body: some View {
//        NavigationStack {
//            Form {
//                Section("與另一半配對") {
//                    TextField("請輸入配對碼", text: $pairingCode)
//                        .textInputAutocapitalization(.none)
//                        .autocorrectionDisabled()
//                    if isPairing {
//                        ProgressView("配對中…")
//                    }
//                    if let errorMessage {
//                        Text(errorMessage)
//                            .foregroundStyle(.red)
//                            .font(.footnote)
//                    }
//                    Button {
//                        Task { await pair() }
//                    } label: {
//                        Text("Pair")
//                            .frame(maxWidth: .infinity)
//                    }
//                    .disabled(pairingCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isPairing)
//                }
//                Section("說明") {
//                    Text("配對成功後會儲存 coupleID 到本機，並可在雲端（CloudKit / Firebase）建立共享紀錄。")
//                        .font(.footnote)
//                }
//            }
//            .navigationTitle("Couple Pairing")
//            .alert("配對成功！", isPresented: $showSuccessAlert) {
//                Button("OK") {}
//            } message: {
//                Text("已成功綁定另一半，開始使用 DailyUS 吧！")
//            }
//        }
//    }
//
//    @MainActor
//    private func pair() async {
//        errorMessage = nil
//        isPairing = true
//        do {
//            // 模擬呼叫雲端 API：用 pairingCode 與 userID 建立/加入 CoupleRecord
//            try await Task.sleep(nanoseconds: 800_000_000)
//            // 成功後回傳一個 coupleID（這裡用 pairingCode 略作替代）
//            let newCoupleID = "couple_" + pairingCode
//            onPaired(newCoupleID)
//            showSuccessAlert = true
//            isPairing = false
//        } catch {
//            errorMessage = error.localizedDescription
//            isPairing = false
//        }
//    }
//}
//
//// MARK: - Home Tab
//struct HomeTabView: View {
//    var body: some View {
//        TabView {
//            // Use the real DailyDashboardView from ⑤ DailyDashboardView.swift
//            DailyDashboardView()
//                .tabItem {
//                    Label("Daily", systemImage: "sun.max")
//                }
//            InteractDashboardView()
//                .tabItem {
//                    Label("Interact", systemImage: "heart")
//                }
//            // 使用正式檔案的 MemoryDashboardView（位於 ⑬ 檔案）
//            MemoryDashboardView()
//                .tabItem {
//                    Label("Memory", systemImage: "clock.arrow.circlepath")
//                }
//            ProfileView_Test()
//                .tabItem {
//                    Label("Profile", systemImage: "person.crop.circle")
//                }
//        }
//    }
//}
//
//// MARK: - Daily Tab (Test placeholder renamed to avoid conflict)
//struct DailyDashboardView_Test: View {
//    var body: some View {
//        NavigationStack {
//            List {
//                Section("今日心情") {
//                    NavigationLink("Mood Page") { MoodPage() }
//                }
//                Section("今日共通問題") {
//                    NavigationLink("DailyQ Page") { DailyQPage() }
//                }
//                Section("給對方訊息") {
//                    NavigationLink("Message Page") { MessagePage() }
//                }
//                Section("心靈小卡") {
//                    NavigationLink("SoulCard Page") { SoulCardPage() }
//                }
//            }
//            .navigationTitle("Daily (Test)")
//        }
//    }
//}
//
//struct MoodPage: View {
//    @State private var mood: Double = 5
//    var body: some View {
//        VStack(spacing: 16) {
//            Text("今日心情：\(Int(mood)) / 10")
//                .font(.headline)
//            Slider(value: $mood, in: 0...10, step: 1)
//                .padding(.horizontal)
//            Text(emoji(for: mood))
//                .font(.system(size: 60))
//                .animation(.spring, value: mood)
//            Button("同步到雲端（模擬）") {
//                Task { try? await Task.sleep(nanoseconds: 300_000_000) }
//            }
//        }
//        .padding()
//        .navigationTitle("Mood")
//    }
//
//    private func emoji(for value: Double) -> String {
//        switch value {
//        case 0...2: return "😞"
//        case 3...4: return "☹️"
//        case 5...6: return "😐"
//        case 7...8: return "🙂"
//        default: return "😄"
//        }
//    }
//}
//
//struct DailyQPage: View {
//    @State private var answer: String = ""
//    let question = "今天最想感謝對方的一件事是什麼？"
//    var body: some View {
//        Form {
//            Section("今日問題") {
//                Text(question)
//                TextField("輸入你的回答", text: $answer, axis: .vertical)
//                    .lineLimit(3, reservesSpace: true)
//            }
//            Section {
//                Button("提交（模擬同步）") {
//                    Task { try? await Task.sleep(nanoseconds: 300_000_000) }
//                }
//            }
//        }
//        .navigationTitle("DailyQ")
//    }
//}
//
//struct MessagePage: View {
//    @State private var text: String = ""
//    var body: some View {
//        VStack(spacing: 12) {
//            TextField("寫給對方的話…", text: $text, axis: .vertical)
//                .textFieldStyle(.roundedBorder)
//                .padding()
//            Button("送出（模擬即時）") {
//                Task { try? await Task.sleep(nanoseconds: 300_000_000) }
//            }
//            Spacer()
//        }
//        .navigationTitle("Message")
//    }
//}
//
//struct SoulCardPage: View {
//    @State private var card: String = "點擊抽卡"
//    let cards = ["勇敢面對", "溫柔以待", "感恩當下", "傾聽彼此", "擁抱改變"]
//    var body: some View {
//        VStack(spacing: 16) {
//            Text(card)
//                .font(.title2)
//                .padding()
//            Button("抽一張") {
//                card = cards.randomElement() ?? "今日無卡"
//            }
//        }
//        .navigationTitle("SoulCard")
//    }
//}
//
//// MARK: - Interact Tab
//struct InteractDashboardView_Test: View {
//    var body: some View {
//        NavigationStack {
//            List {
//                Section("每日互動") {
//                    // Use production HeartTapView (⑪)
//                    NavigationLink("Heart Tap ❤️") { HeartTapView() }
//                }
//                Section("每週默契測驗") {
//                    // Use production WeeklyQuizView (⑫)
//                    NavigationLink("Weekly Quiz") { WeeklyQuizView() }
//                }
//            }
//            .navigationTitle("Interact")
//        }
//    }
//}
//
//// Old temporary HeartTapPage kept for reference; not used anymore
//struct HeartTapPage: View {
//    @State private var heartCount: Int = 0
//    var body: some View {
//        VStack(spacing: 20) {
//            Text("今日愛心：\(heartCount)")
//                .font(.title2)
//            Button {
//                withAnimation(.spring) {
//                    heartCount += 1
//                }
//            } label: {
//                Image(systemName: "heart.fill")
//                    .font(.system(size: 60))
//                    .foregroundStyle(.red)
//                    .scaleEffect(1 + CGFloat(heartCount % 5) * 0.05)
//            }
//            Button("同步到雲端（模擬）") {
//                Task { try? await Task.sleep(nanoseconds: 300_000_000) }
//            }
//            Spacer()
//        }
//        .padding()
//        .navigationTitle("Heart Tap")
//    }
//}
//
//// Old temporary WeeklyQuizPage kept for reference; not used anymore
//struct WeeklyQuizPage: View {
//    @State private var myAnswer: String = ""
//    @State private var partnerAnswer: String = "尚未作答"
//    var body: some View {
//        Form {
//            Section("本週題目") {
//                Text("你們理想的假日約會是？")
//            }
//            Section("你的回答") {
//                TextField("輸入你的答案", text: $myAnswer)
//            }
//            Section("對方回答（模擬）") {
//                Text(partnerAnswer)
//            }
//            Section {
//                Button("提交並比較（模擬）") {
//                    // 模擬對比，顯示理解度
//                    partnerAnswer = ["看電影", "野餐", "爬山", "在家煮飯"].randomElement()!
//                }
//            }
//        }
//        .navigationTitle("Weekly Quiz")
//    }
//}
//
//// MARK: - Memory Tab (測試版本，為避免與正式檔案衝突，已改名)
//struct MemoryDashboardView_Test: View {
//    var body: some View {
//        NavigationStack {
//            List {
//                Section("紀念日 / 在一起天數") {
//                    NavigationLink("Anniversary") { AnniversaryPage() }
//                    NavigationLink("Together Days") { TogetherDaysPage() }
//                }
//                Section("回憶時間軸") {
//                    NavigationLink("Diary Timeline") { DiaryTimelinePage() }
//                }
//            }
//            .navigationTitle("Memory (Test)")
//        }
//    }
//}
//
//struct AnniversaryPage: View {
//    @State private var date: Date = Date()
//    var body: some View {
//        Form {
//            DatePicker("在一起日期", selection: $date, displayedComponents: .date)
//            Text("（示意）將以套件計算 day count，並可加入小動畫")
//                .font(.footnote)
//        }
//        .navigationTitle("Anniversary")
//    }
//}
//
//struct TogetherDaysPage: View {
//    @State private var startDate: Date = Calendar.current.date(byAdding: .day, value: -100, to: Date()) ?? Date()
//    var body: some View {
//        VStack(spacing: 12) {
//            Text("起始日：\(startDate.formatted(date: .abbreviated, time: .omitted))")
//            let days = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
//            Text("在一起第 \(days) 天")
//                .font(.title2)
//            Spacer()
//        }
//        .padding()
//        .navigationTitle("Together Days")
//    }
//}
//
//struct DiaryTimelinePage: View {
//    var body: some View {
//        List {
//            ForEach(0..<10, id: \.self) { i in
//                VStack(alignment: .leading, spacing: 6) {
//                    Text("Day \(i + 1)")
//                        .font(.headline)
//                    Text("留言/心情/回答等紀錄（示意）")
//                        .font(.subheadline)
//                        .foregroundStyle(.secondary)
//                }
//                .padding(.vertical, 4)
//            }
//        }
//        .navigationTitle("Diary Timeline")
//    }
//}
//
//// MARK: - Profile Tab (Test version renamed to avoid conflict with production ProfileView)
//struct ProfileView_Test: View {
//    @AppStorage("userName") private var userName: String = ""
//    @AppStorage("coupleID") private var coupleID: String = ""
//    @State private var pushEnabled: Bool = true
//    @State private var backupStatus: String = "未備份"
//    @State private var versionTapCount: Int = 0
//    @State private var showSecret: Bool = false
//
//    var body: some View {
//        NavigationStack {
//            Form {
//                Section("個人資料") {
//                    TextField("暱稱", text: $userName)
//                    HStack {
//                        Text("配對狀態")
//                        Spacer()
//                        Text(coupleID.isEmpty ? "未配對" : "已配對")
//                            .foregroundStyle(coupleID.isEmpty ? .red : .green)
//                    }
//                }
//                Section("設定") {
//                    Toggle("推播通知", isOn: $pushEnabled)
//                    HStack {
//                        Text("備份狀態")
//                        Spacer()
//                        Text(backupStatus)
//                    }
//                    Button("立即備份（模擬）") {
//                        Task {
//                            backupStatus = "備份中…"
//                            try? await Task.sleep(nanoseconds: 400_000_000)
//                            backupStatus = "已備份"
//                        }
//                    }
//                }
//                Section("關於") {
//                    Button {
//                        versionTapCount += 1
//                        if versionTapCount >= 5 {
//                            versionTapCount = 0
//                            showSecret = true
//                        }
//                    } label: {
//                        HStack {
//                            Text("版本")
//                            Spacer()
//                            Text(appVersionString())
//                                .foregroundStyle(.secondary)
//                        }
//                    }
//                }
//            }
//            .navigationTitle("Profile")
//            .navigationDestination(isPresented: $showSecret) {
//                SecretDeveloperPage()
//            }
//        }
//    }
//
//    private func appVersionString() -> String {
//        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0"
//        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
//        return "\(version) (\(build))"
//    }
//}
//
//struct SecretDeveloperPage: View {
//    var body: some View {
//        VStack(spacing: 16) {
//            Text("🎉 Secret Developer Page")
//                .font(.title2)
//            Text("這裡可以放開發者資訊、彩蛋動畫、或 app icon 預覽。")
//                .multilineTextAlignment(.center)
//            Spacer()
//        }
//        .padding()
//        .navigationTitle("Developer")
//    }
//}
//
//// MARK: - Test entry for this file
//struct Test: View {
//    var body: some View {
//        TestRoot()
//    }
//}
//
//#Preview {
//    Test()
//}
