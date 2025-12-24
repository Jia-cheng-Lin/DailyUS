//
//  Hangman.swift
//  Game
//
//  Created by 林嘉誠 on 2025/9/12.
//

import SwiftUI
import AVFoundation
import Combine

private let defaultLives = 7

// 題庫分類
private enum Category: String, CaseIterable, Identifiable {
    case animals = "動物"
    case objects = "物品"
    case actions = "動作"
    case easy    = "簡單"
    case medium  = "中等"
    case hard    = "困難"
    case extra   = "額外" // 使用者自訂
    
    var id: String { rawValue }
    
    // 固定題庫（額外由使用者輸入，不在此回傳）
    var words: [String] {
        switch self {
        case .animals:
            return [
                "CAT", "DOG", "ELEPHANT", "TIGER", "LION",
                "GIRAFFE", "KANGAROO", "PANDA", "MONKEY", "ZEBRA",
                "WHALE", "DOLPHIN", "EAGLE", "OWL", "RABBIT"
            ]
        case .objects:
            return [
                "TABLE", "CHAIR", "COMPUTER", "PHONE", "BOTTLE",
                "UMBRELLA", "BACKPACK", "KEYBOARD", "HEADPHONE", "CAMERA",
                "NOTEBOOK", "PENCIL", "SCISSORS", "MIRROR", "CLOCK"
            ]
        case .actions:
            return [
                "RUN", "JUMP", "SWIM", "SING", "DANCE",
                "WRITE", "READ", "DRIVE", "COOK", "PAINT",
                "CLIMB", "THINK", "LAUGH", "CRY", "LISTEN"
            ]
        case .easy:
            // 常見 3000 字內
            return [
                "APPLE", "HOUSE", "WATER", "MUSIC", "HAPPY",
                "FAMILY", "SCHOOL", "FRIEND", "RIVER", "GARDEN",
                "WINDOW", "ORANGE", "SUGAR", "MONEY", "SUMMER",
                "WINTER", "SLEEP", "DREAM", "SMILE", "FLOWER"
            ]
        case .medium:
            // 約 7000 字等級
            return [
                "ACCOUNTANT", "ADJUSTMENT", "BENEFICIAL", "CANDIDATE", "CONSIDER",
                "DELIVERY", "EFFICIENT", "FEEDBACK", "GENERATE", "HARMONY",
                "INCIDENT", "LANDSCAPE", "MAJORITY", "NEGOTIATE", "OUTCOME",
                "PURCHASE", "RESEARCH", "STRATEGY", "TOLERANCE", "VALUABLE"
            ]
        case .hard:
            // TOEIC/商務等較難詞彙
            return [
                "AGREEMENT", "APPLICANT", "BUDGET", "CONTRACT", "DEADLINE",
                "DEPARTMENT", "ENTERPRISE", "FACILITY", "GUARANTEE", "HEADQUARTERS",
                "LIABILITY", "LOGISTICS", "MANAGEMENT", "NEGOTIATION", "PROCUREMENT",
                "REVENUE", "SUBSIDIARY", "SUPERVISOR", "SYNERGY", "TURNOVER",
                "WORKFORCE", "COMPLIANCE"
            ]
        case .extra:
            // 額外由使用者輸入，這裡不回傳
            return []
        }
    }
}

// 鍵盤排列
private enum KeyboardLayout: String, CaseIterable, Identifiable {
    case alphabetical
    case qwerty
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .alphabetical: return "A–Z"
        case .qwerty: return "打字"
        }
    }
}

// 短促提示音（系統音效）
private enum SoundPlayer {
    static func playCorrect() {
        AudioServicesPlaySystemSound(SystemSoundID(1057)) // 輕快提示
    }
    static func playWrong() {
        AudioServicesPlaySystemSound(SystemSoundID(1022)) // 低沉提示
    }
    // 倒數滴答（使用系統音效，不需資源）
    static func playTickSlow() {
        AudioServicesPlaySystemSound(SystemSoundID(1104)) // 鍵盤點按聲，作為慢滴答
    }
    static func playTickFast() {
        AudioServicesPlaySystemSound(SystemSoundID(1103)) // 另一個點按聲，作為快滴答
    }
}

// 背景音樂/較長音效（mp3/wav 由專案資源提供）
private final class BGMPlayer {
    static let shared = BGMPlayer()
    private var player: AVAudioPlayer?

    func play(resource name: String, ext: String = "mp3", volume: Float = 1.0) {
        stop()
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            // 資源缺失時安靜失敗
            return
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.ambient, options: [.mixWithOthers])
            try? session.setActive(true, options: [])
            
            let p = try AVAudioPlayer(contentsOf: url)
            p.volume = volume
            p.prepareToPlay()
            p.play()
            self.player = p
        } catch {
            // 播放失敗忽略
        }
    }
    
    func stop() {
        player?.stop()
        player = nil
    }
}

struct Hangman: View {
    @State private var isInSetup: Bool = true
    
    @State private var selectedCategory: Category? = nil
    @State private var targetWord: String = ""
    @State private var guessedLetters: Set<Character> = []
    @State private var remainingLives: Int = defaultLives
    @State private var isGameOver: Bool = false
    @State private var isWin: Bool = false
    
    // 額外題庫儲存（跨啟動保存，使用換行分隔）
    @AppStorage("extraWordsRaw") private var extraWordsRaw: String = ""
    @State private var showExtraEditor: Bool = false
    @State private var extraEditorText: String = ""
    
    // 鍵盤排列偏好（跨啟動保存）
    @AppStorage("keyboardLayout") private var keyboardLayoutRaw: String = KeyboardLayout.alphabetical.rawValue
    private var currentKeyboardLayout: KeyboardLayout {
        KeyboardLayout(rawValue: keyboardLayoutRaw) ?? .alphabetical
    }
    
    // QWERTY 字體大小（整數，跨啟動保存）
    @AppStorage("qwertyFontSize") private var qwertyFontSize: Int = 11
    
    // 每次按字母的倒數秒數（跨啟動保存）
    @AppStorage("guessIntervalSeconds") private var guessIntervalSeconds: Int = 10
    @State private var countdownRemaining: Int = 0
    
    // 每秒計時器
    private let secondTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var isTimerActive: Bool {
        !isInSetup && !isGameOver && selectedCategory != nil && !targetWord.isEmpty
    }
    
    var maskedWord: String {
        targetWord.map { guessedLetters.contains($0) ? String($0) : "_" }
            .joined(separator: " ")
    }
    
    var wrongGuesses: [Character] {
        guessedLetters.filter { !targetWord.contains($0) }.sorted()
    }
    
    // 目前額外題庫（已正規化、去重後存成一行一字）
    private var extraWords: [String] {
        extraWordsRaw
            .split(separator: "\n")
            .map(String.init)
            .filter { !$0.isEmpty }
    }
    
    private var canStartGame: Bool {
        guard let selectedCategory else { return false }
        if selectedCategory == .extra && extraWords.isEmpty { return false }
        return true
    }
    
    var body: some View {
        ZStack {
            if isInSetup {
                setupScreen
            } else {
                gameScreen
            }
        }
        .onAppear {
            // 初次載入：顯示設定畫面
            isInSetup = true
            clearGame()
            // 給一個預設題庫，讓使用者可直接開始
            if selectedCategory == nil {
                selectedCategory = .animals
            }
        }
        // 每秒處理倒數、音效與逾時扣命（僅在遊戲畫面時）
        .onReceive(secondTimer) { _ in
            guard isTimerActive else { return }
            guard countdownRemaining > 0 else {
                // 已為 0，視為逾時：扣一命並重置倒數
                remainingLives -= 1
                SoundPlayer.playWrong()
                if remainingLives <= 0 {
                    isWin = false
                    isGameOver = true
                    BGMPlayer.shared.play(resource: "wrong", ext: "mp3", volume: 1.0)
                } else {
                    countdownRemaining = max(1, guessIntervalSeconds) // 避免 0
                }
                return
            }
            
            countdownRemaining -= 1
            
            if countdownRemaining > 0 {
                if countdownRemaining <= 3 {
                    SoundPlayer.playTickFast()
                } else {
                    SoundPlayer.playTickSlow()
                }
            }
        }
        .sheet(isPresented: $showExtraEditor) {
            extraEditorSheet
        }
    }
    
    // MARK: - 設定畫面（滿版）
    private var setupScreen: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Hangman")
                        .font(.largeTitle.bold())
                        .padding(.top, 8)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("選擇題庫")
                            .font(.headline)
                        Picker("題庫", selection: Binding(
                            get: { selectedCategory ?? Category.animals },
                            set: { newValue in
                                selectedCategory = newValue
                            }
                        )) {
                            ForEach(Category.allCases) { category in
                                Text(category.rawValue).tag(category)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("使用的鍵盤")
                            .font(.headline)
                        Picker("鍵盤排列", selection: Binding<KeyboardLayout>(
                            get: { currentKeyboardLayout },
                            set: { keyboardLayoutRaw = $0.rawValue }
                        )) {
                            ForEach(KeyboardLayout.allCases) { layout in
                                Text(layout.displayName).tag(layout)
                            }
                        }
                        .pickerStyle(.segmented)
                        
                        // 僅在 QWERTY 模式顯示字體大小調整
                        if currentKeyboardLayout == .qwerty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("打字的 字體大小")
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(qwertyFontSize) pt")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .accessibilityLabel("字體大小 \(qwertyFontSize) 點")
                                }
                                Slider(
                                    value: Binding(
                                        get: { Double(qwertyFontSize) },
                                        set: { qwertyFontSize = Int($0.rounded()) }
                                    ),
                                    in: 9...20,
                                    step: 1
                                )
                                .accessibilityLabel("打字的字體大小調整")
                            }
                            .padding(.top, 4)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("每次按字母的限時")
                            .font(.headline)
                        Picker("每次限時", selection: $guessIntervalSeconds) {
                            Text("5 秒").tag(5)
                            Text("10 秒").tag(10)
                            Text("15 秒").tag(15)
                            Text("20 秒").tag(20)
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityLabel("每次限時 \(guessIntervalSeconds) 秒")
                    }
                    
                    // 額外題庫管理區（當選擇「額外」時顯示）
                    if selectedCategory == .extra {
                        VStack(spacing: 8) {
                            HStack {
                                Button {
                                    showExtraEditor = true
                                } label: {
                                    Label("管理額外題庫", systemImage: "square.and.pencil")
                                }
                                .buttonStyle(.bordered)
                                
                                Text("單字數：\(extraWords.count)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                
                                Spacer()
                            }
                            
                            if extraWords.isEmpty {
                                Text("額外題庫目前為空，請點選「管理額外題庫」新增單字後再開始遊戲。")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    Button {
                        startGame()
                    } label: {
                        Label("開始遊戲", systemImage: "play.fill")
                            .font(.headline)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canStartGame)
                    .padding(.top, 8)
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("設定")
        }
    }
    
    // MARK: - 遊戲畫面
    private var gameScreen: some View {
        ZStack {
            VStack(spacing: 20) {
                // 吊人圖：依剩餘生命顯示部位
                HangmanFigure(lostLives: defaultLives - remainingLives)
                    .frame(height: 160)
                    .frame(maxWidth: 260)
                    .accessibilityLabel("吊人圖")
                    .accessibilityValue("已失去 \(defaultLives - remainingLives) / \(defaultLives) 生命")
                
                Text("Hangman")
                    .font(.largeTitle.bold())
                
                // 顯示當前題庫提示
                if let selectedCategory {
                    Text("題庫：\(selectedCategory.rawValue)")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                
                // 生命與倒數
                VStack(spacing: 4) {
                    Text("剩餘生命：\(remainingLives)")
                        .font(.headline)
                        .foregroundColor(remainingLives > 2 ? .primary : .red)
                    
                    if isTimerActive {
                        Text("剩餘秒數：\(countdownRemaining)")
                            .font(.headline)
                            .foregroundColor(countdownRemaining <= 3 ? .red : .primary)
                            .accessibilityLabel("剩餘秒數 \(countdownRemaining) 秒")
                    }
                }
                
                Text(maskedWord)
                    .font(.system(size: 40, weight: .semibold, design: .monospaced))
                    .accessibilityLabel(maskedWord.replacingOccurrences(of: " ", with: " "))
                    .padding(.top, 8)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity)
                
                if !wrongGuesses.isEmpty {
                    Text("猜錯：\(String(wrongGuesses))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // 額外題庫管理區（當選擇「額外」時顯示）
                if selectedCategory == .extra {
                    VStack(spacing: 8) {
                        HStack {
                            Button {
                                showExtraEditor = true
                            } label: {
                                Label("管理額外題庫", systemImage: "square.and.pencil")
                            }
                            .buttonStyle(.bordered)
                            
                            Text("單字數：\(extraWords.count)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Spacer()
                        }
                        
                        if extraWords.isEmpty {
                            Text("額外題庫目前為空，請點選「管理額外題庫」新增單字後再開始遊戲。")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                
                KeyboardView(
                    enabled: !isGameOver && selectedCategory != nil && !targetWord.isEmpty,
                    guessedLetters: guessedLetters,
                    onTap: handleGuess,
                    layout: currentKeyboardLayout,
                    qwertyFontSize: qwertyFontSize
                )
                .padding(.top, 8)
                
                HStack(spacing: 12) {
                    Button(action: resetGame) {
                        Label("重新開始", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedCategory == nil)
                    
                    // 可選擇更換題庫（會重開遊戲）
                    Menu {
                        ForEach(Category.allCases) { category in
                            Button(category.rawValue) {
                                changeCategory(to: category)
                            }
                        }
                        Button {
                            // 回到設定畫面
                            isInSetup = true
                            // 不清空選擇，保留目前設定，讓使用者可調整後開始
                            clearGame()
                        } label: {
                            Label("回到設定畫面", systemImage: "gearshape")
                        }
                        if selectedCategory != nil {
                            Button(role: .destructive) {
                                // 清除並回設定畫面
                                selectedCategory = nil
                                isInSetup = true
                                clearGame()
                            } label: {
                                Label("清除選擇", systemImage: "xmark.circle")
                            }
                        }
                    } label: {
                        Label("更多", systemImage: "ellipsis.circle")
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.top, 4)
            }
            .padding()
            
            // 遊戲結束疊層：顯示 win/lose 圖片與再玩一次
            if isGameOver {
                GameOverOverlay(
                    isWin: isWin,
                    answer: targetWord,
                    onReplay: {
                        BGMPlayer.shared.stop()
                        resetGame()
                    }
                )
                .transition(.opacity.combined(with: .scale))
                .zIndex(1)
            }
        }
    }
    
    private func startGame() {
        isInSetup = false
        resetGame()
    }
    
    private func changeCategory(to newCategory: Category) {
        guard selectedCategory != newCategory else { return }
        selectedCategory = newCategory
        resetGame()
    }
    
    private func handleGuess(_ letter: Character) {
        guard !isGameOver else { return }
        guard letter.isLetter else { return }
        let upper = Character(letter.uppercased())
        guard !guessedLetters.contains(upper) else { return }
        
        guessedLetters.insert(upper)
        
        if !targetWord.contains(upper) {
            remainingLives -= 1
            SoundPlayer.playWrong() // 每次猜錯的短音效（保留）
            if remainingLives <= 0 {
                isWin = false
                isGameOver = true
                // 終局：只播放 wrong.mp3
                BGMPlayer.shared.play(resource: "wrong", ext: "mp3", volume: 1.0)
                return
            }
        } else {
            SoundPlayer.playCorrect() // 每次猜對的短音效（保留）
            // 檢查是否全部揭露
            let allRevealed = targetWord.allSatisfy { guessedLetters.contains($0) }
            if allRevealed {
                isWin = true
                isGameOver = true
                // 終局：只播放 correct.mp3
                BGMPlayer.shared.play(resource: "correct", ext: "mp3", volume: 1.0)
            }
        }
        
        // 每次按字母後，若遊戲仍在進行，重置倒數
        if !isGameOver {
            countdownRemaining = max(1, guessIntervalSeconds)
        }
    }
    
    private func resetGame() {
        BGMPlayer.shared.stop()
        guessedLetters = []
        remainingLives = defaultLives
        isGameOver = false
        isWin = false
        
        if let selectedCategory {
            let list = words(for: selectedCategory)
            if let word = list.randomElement() {
                targetWord = word
                countdownRemaining = max(1, guessIntervalSeconds)
            } else {
                targetWord = ""
                countdownRemaining = 0
            }
        } else {
            targetWord = ""
            countdownRemaining = 0
        }
    }
    
    private func clearGame() {
        BGMPlayer.shared.stop()
        targetWord = ""
        guessedLetters = []
        remainingLives = defaultLives
        isGameOver = false
        isWin = false
        countdownRemaining = 0
    }
    
    // 依類別取得可用單字
    private func words(for category: Category) -> [String] {
        switch category {
        case .extra:
            return extraWords
        default:
            return category.words
        }
    }
    
    // 將輸入文字轉為 A–Z 大寫單字陣列，去掉非字母、去重、去空
    private func normalizeWords(from text: String) -> [String] {
        let separators = CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ",;，、.。/\\|"))
        let rawTokens = text.components(separatedBy: separators)
        
        let allowed = Set("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        var seen = Set<String>()
        var result: [String] = []
        
        for token in rawTokens {
            let upper = token.uppercased()
            let cleaned = String(upper.filter { allowed.contains($0) })
            // 過濾掉空字與過短字（至少 2 個字母較合理）
            guard cleaned.count >= 2 else { continue }
            if !seen.contains(cleaned) {
                seen.insert(cleaned)
                result.append(cleaned)
            }
        }
        return result
    }
    
    // 額外題庫編輯面板
    private var extraEditorSheet: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Text("每行或以逗號分隔一個單字，系統會自動轉為 A–Z 大寫並去除重複。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                TextEditor(text: $extraEditorText)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 220)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3))
                    )
                    .onAppear {
                        // 將目前額外題庫載入編輯器
                        extraEditorText = extraWords.joined(separator: "\n")
                    }
                
                HStack {
                    Button(role: .destructive) {
                        extraEditorText = ""
                    } label: {
                        Label("清空輸入", systemImage: "trash")
                    }
                    
                    Spacer()
                    
                    Button {
                        let words = normalizeWords(from: extraEditorText)
                        extraWordsRaw = words.joined(separator: "\n")
                        // 若當前選擇「額外」，儲存後立即重開一局
                        if selectedCategory == .extra && !isInSetup {
                            resetGame()
                        }
                        showExtraEditor = false
                    } label: {
                        Label("儲存", systemImage: "checkmark.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationTitle("管理額外題庫")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("關閉") {
                        showExtraEditor = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// 結束畫面 Overlay
private struct GameOverOverlay: View {
    let isWin: Bool
    let answer: String
    let onReplay: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            // 顯示 win / lose 圖片（需在 Assets 中提供名為 "win"、"lose" 的圖片）
            Image(isWin ? "win" : "lose")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 240)
                .shadow(radius: 8)
                .padding(.horizontal)
            
            Text(isWin ? "你贏了！" : "遊戲結束")
                .font(.title.bold())
            Text(isWin ? "答對：\(answer)" : "正確答案：\(answer)")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            Button {
                onReplay()
            } label: {
                Label("再玩一次", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            // 半透明遮罩
            Color.black.opacity(0.35).ignoresSafeArea()
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(isWin ? "勝利畫面" : "失敗畫面")
    }
}

// 吊人圖：依序顯示 1) 吊繩 2) 頭 3) 左手 4) 右手 5) 身體 6) 左腳 7) 右腳
private struct HangmanFigure: View {
    let lostLives: Int // 0...7
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            // 基準點與尺寸
            let baseY = h * 0.95
            let baseLeftX = w * 0.15
            let baseRightX = w * 0.85
            let postTopY = h * 0.1
            let postX = baseLeftX
            let beamEndX = w * 0.55
            let ropeX = beamEndX
            let ropeTopY = postTopY
            let ropeBottomY = h * 0.32
            
            let headCenter = CGPoint(x: ropeX, y: ropeBottomY + (h * 0.055))
            let headRadius = h * 0.055
            let neckY = headCenter.y + headRadius
            let torsoBottomY = neckY + h * 0.20
            
            let armSpan = w * 0.16
            let armY = neckY + h * 0.05
            
            let legSpan = w * 0.18
            let legTopY = torsoBottomY
            let legBottomY = legTopY + h * 0.22
            
            // 絞刑台（固定顯示，非生命階段）
            Path { p in
                // 地台
                p.move(to: CGPoint(x: baseLeftX, y: baseY))
                p.addLine(to: CGPoint(x: baseRightX, y: baseY))
                // 立柱
                p.move(to: CGPoint(x: postX, y: baseY))
                p.addLine(to: CGPoint(x: postX, y: postTopY))
                // 橫梁
                p.addLine(to: CGPoint(x: beamEndX, y: postTopY))
                // 小支撐
                p.move(to: CGPoint(x: postX, y: h * 0.35))
                p.addLine(to: CGPoint(x: w * 0.32, y: postTopY))
            }
            .stroke(Color.secondary, lineWidth: 3)
            
            // 1) 吊繩
            if lostLives >= 1 {
                Path { p in
                    p.move(to: CGPoint(x: ropeX, y: ropeTopY))
                    p.addLine(to: CGPoint(x: ropeX, y: ropeBottomY))
                }
                .stroke(Color.primary, lineWidth: 3)
            }
            // 2) 頭
            if lostLives >= 2 {
                Circle()
                    .stroke(Color.primary, lineWidth: 3)
                    .frame(width: headRadius * 2, height: headRadius * 2)
                    .position(headCenter)
            }
            // 3) 左手
            if lostLives >= 3 {
                Path { p in
                    p.move(to: CGPoint(x: ropeX, y: armY))
                    p.addLine(to: CGPoint(x: ropeX - armSpan, y: armY + h * 0.05))
                }
                .stroke(Color.primary, lineWidth: 3)
            }
            // 4) 右手
            if lostLives >= 4 {
                Path { p in
                    p.move(to: CGPoint(x: ropeX, y: armY))
                    p.addLine(to: CGPoint(x: ropeX + armSpan, y: armY + h * 0.05))
                }
                .stroke(Color.primary, lineWidth: 3)
            }
            // 5) 身體
            if lostLives >= 5 {
                Path { p in
                    p.move(to: CGPoint(x: ropeX, y: neckY))
                    p.addLine(to: CGPoint(x: ropeX, y: torsoBottomY))
                }
                .stroke(Color.primary, lineWidth: 3)
            }
            // 6) 左腳
            if lostLives >= 6 {
                Path { p in
                    p.move(to: CGPoint(x: ropeX, y: legTopY))
                    p.addLine(to: CGPoint(x: ropeX - legSpan, y: legBottomY))
                }
                .stroke(Color.primary, lineWidth: 3)
            }
            // 7) 右腳
            if lostLives >= 7 {
                Path { p in
                    p.move(to: CGPoint(x: ropeX, y: legTopY))
                    p.addLine(to: CGPoint(x: ropeX + legSpan, y: legBottomY))
                }
                .stroke(Color.primary, lineWidth: 3)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: lostLives)
    }
}

private struct KeyboardView: View {
    let enabled: Bool
    let guessedLetters: Set<Character>
    let onTap: (Character) -> Void
    let layout: KeyboardLayout
    let qwertyFontSize: Int
    
    // A–Z 或 QWERTY 排列
    private var rows: [[Character]] {
        switch layout {
        case .alphabetical:
            let letters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
            let row1 = Array(letters[0..<7])   // A–G
            let row2 = Array(letters[7..<14])  // H–N
            let row3 = Array(letters[14..<20]) // O–T
            let row4 = Array(letters[20..<26]) // U–Z
            return [row1, row2, row3, row4]
        case .qwerty:
            let row1 = Array("QWERTYUIOP")
            let row2 = Array("ASDFGHJKL")
            let row3 = Array("ZXCVBNM")
            return [row1, row2, row3]
        }
    }
    
    // 依排列調整鍵帽字體：QWERTY 使用可調整大小
    private var keyFont: Font {
        switch layout {
        case .alphabetical:
            return .headline
        case .qwerty:
            return Font.system(size: CGFloat(qwertyFontSize), weight: .semibold, design: .default)
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: 6) {
                    ForEach(rows[rowIndex], id: \.self) { letter in
                        let guessed = guessedLetters.contains(letter)
                        Button(action: { onTap(letter) }) {
                            Text(String(letter))
                                .font(keyFont)
                                .frame(maxWidth: .infinity, minHeight: 40)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.bordered)
                        .tint(guessed ? .gray : .accentColor)
                        .disabled(!enabled || guessed)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("鍵盤")
    }
}

#Preview {
    Hangman()
}
