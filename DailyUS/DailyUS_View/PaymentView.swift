//
//  PaymentView.swift
//  DailyUS
//
//  Created by 陳芸萱 on 2025/12/19.
//

import SwiftUI
import UserNotifications
import Charts

// 安全載入背景：若圖片資源缺失，退回為透明色，避免因資源缺漏崩潰
@ViewBuilder
private func safeBackground(named name: String) -> some View {
    if UIImage(named: name) != nil {
        Background(image: Image(name))
            .opacity(0.5)
            .allowsHitTesting(false)
    } else {
        Color.clear
            .opacity(0.0)
            .allowsHitTesting(false)
    }
}

#if DEBUG
private let isPreview: Bool = {
    ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
}()
#endif

// MARK: - Models

enum PaymentCategory: String, CaseIterable, Identifiable, Codable {
    case water = "水費"
    case electricity = "電費"
    case gas = "瓦斯費"
    case rent = "房租"
    case other = "其他"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .water: return "drop.fill"
        case .electricity: return "bolt.fill"
        case .gas: return "flame.fill"
        case .rent: return "house.fill"
        case .other: return "creditcard.fill"
        }
    }

    var color: Color {
        switch self {
        case .water: return .blue
        case .electricity: return .yellow
        case .gas: return .orange
        case .rent: return .purple
        case .other: return .green
        }
    }
}

struct PaymentRecord: Identifiable, Codable, Hashable {
    let id: UUID
    var date: Date
    var amount: Double
    var payer: String

    init(id: UUID = UUID(), date: Date = Date(), amount: Double, payer: String) {
        self.id = id
        self.date = date
        self.amount = amount
        self.payer = payer
    }
}

struct PaymentItem: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var category: PaymentCategory

    var dayOfMonth: Int
    var remindDaysBefore: Int
    var intervalMonths: Int

    var records: [PaymentRecord]

    init(
        id: UUID = UUID(),
        name: String,
        category: PaymentCategory,
        dayOfMonth: Int = 5,
        remindDaysBefore: Int = 3,
        intervalMonths: Int = 1,
        records: [PaymentRecord] = []
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.dayOfMonth = max(1, min(28, dayOfMonth))
        self.remindDaysBefore = max(0, remindDaysBefore)
        self.intervalMonths = max(1, intervalMonths)
        self.records = records
    }

    // O(n) 取得最後一筆（避免 sorted 重複計算）
    var lastRecord: PaymentRecord? {
        records.max(by: { $0.date < $1.date })
    }
}

// MARK: - Storage

private struct PaymentStorage {
    @AppStorage("payment_items_json") private var raw: String = ""

    func load() -> [PaymentItem] {
        guard let data = raw.data(using: .utf8), !raw.isEmpty else { return defaultItems() }
        return (try? JSONDecoder().decode([PaymentItem].self, from: data)) ?? defaultItems()
    }

    func save(_ items: [PaymentItem]) {
        guard let data = try? JSONEncoder().encode(items),
              let s = String(data: data, encoding: .utf8) else { return }
        raw = s
    }

    private func defaultItems() -> [PaymentItem] {
        [
            PaymentItem(name: "水費", category: .water, dayOfMonth: 5, remindDaysBefore: 3, intervalMonths: 2),
            PaymentItem(name: "電費", category: .electricity, dayOfMonth: 10, remindDaysBefore: 3, intervalMonths: 2),
            PaymentItem(name: "瓦斯費", category: .gas, dayOfMonth: 12, remindDaysBefore: 2, intervalMonths: 1),
            PaymentItem(name: "房租", category: .rent, dayOfMonth: 21, remindDaysBefore: 5, intervalMonths: 1)
        ]
    }
}

// MARK: - Notification scheduler

actor PaymentNotifier {
    static let shared = PaymentNotifier()

    func requestAuthorization() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }

    func schedule(for item: PaymentItem) async {
        let center = UNUserNotificationCenter.current()
        await center.removePendingNotificationRequests(withIdentifiers: [item.id.uuidString])
        guard let next = nextTriggerDate(day: item.dayOfMonth, monthsInterval: item.intervalMonths, daysBefore: item.remindDaysBefore) else { return }

        var comps = Calendar.current.dateComponents([.year, .month, .day], from: next)
        comps.hour = 9
        // 為避免系統 repeats 限制與錯誤重複，使用 repeats: false，並在每次進入頁面時重新排程
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)

        let content = UNMutableNotificationContent()
        content.title = "繳費提醒：\(item.name)"
        content.body = "每 \(item.intervalMonths) 個月的 \(item.dayOfMonth) 號，提前 \(item.remindDaysBefore) 天提醒"
        content.sound = .default

        let req = UNNotificationRequest(identifier: item.id.uuidString, content: content, trigger: trigger)
        try? await center.add(req)
    }

    private func nextTriggerDate(day: Int, monthsInterval: Int, daysBefore: Int) -> Date? {
        let cal = Calendar.current
        let now = Date()
        var comps = cal.dateComponents([.year, .month], from: now)
        comps.day = min(day, 28)
        guard var base = cal.date(from: comps) else { return nil }
        if now > base {
            base = cal.date(byAdding: .month, value: monthsInterval, to: base) ?? base
        }
        return cal.date(byAdding: .day, value: -daysBefore, to: base)
    }
}

// MARK: - Main list

struct PaymentView: View {
    @State private var items: [PaymentItem] = []
    private let storage = PaymentStorage()

    @State private var showingAdd = false
    @State private var showAddSingleSheet = false

    // 新增單一項目暫存
    @State private var singleName: String = ""
    @State private var singleCategory: PaymentCategory = .other
    @State private var singleAmount: String = ""
    @State private var singlePayer: String = ""
    @State private var singleDate: Date = Date()

    @State private var showBackground: Bool = false

    var body: some View {
        ZStack {
            if showBackground {
                #if DEBUG
                if isPreview {
                    LinearGradient(colors: [.clear, .clear], startPoint: .top, endPoint: .bottom)
                        .opacity(0.5)
                        .allowsHitTesting(false)
                } else {
                    safeBackground(named: "Back_3")
                }
                #else
                safeBackground(named: "Back_3")
                #endif
            }

            List {
                Section {
                    ForEach(items) { item in
                        NavigationLink {
                            PaymentDetailView(item: item) { updated in
                                updateItem(updated)
                            } onDelete: {
                                deleteItem(item)
                            }
                        } label: {
                            PaymentRow(item: item)
                        }
                    }
                    .onDelete(perform: remove)
                } header: {
                    Text("繳費提醒 / 記帳紀錄")
                }

                Section {
                    Button {
                        showingAdd = true
                    } label: {
                        Label("新增固定項目", systemImage: "plus.circle.fill")
                    }
                }

                Section("新增單一項目") {
                    Button {
                        singleName = ""
                        singleCategory = .other
                        singleAmount = ""
                        singlePayer = ""
                        singleDate = Date()
                        showAddSingleSheet = true
                    } label: {
                        Label("新增單一項目", systemImage: "plus.circle.fill")
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .padding(.top, 16)
            .safeAreaInset(edge: .top) { Color.clear.frame(height: 8) }
        }
        .navigationTitle("繳費與記帳")
        .onAppear {
            items = storage.load()
            // 直接顯示背景，避免淡入動畫造成首幀卡頓
            showBackground = true

            #if DEBUG
            if isPreview {
                // 預覽模式：使用少量假資料，避免通知與 I/O
                items = [
                    PaymentItem(name: "水費", category: .water),
                    PaymentItem(name: "電費", category: .electricity)
                ]
                return
            }
            #endif

            Task { await PaymentNotifier.shared.requestAuthorization() }
            // 輕量地重新排程提醒（避免重覆排程可用去重策略）
            Task {
                for item in items {
                    await PaymentNotifier.shared.schedule(for: item)
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            PaymentEditView(item: PaymentItem(name: "", category: .other)) { newItem in
                addItem(newItem)
            } onCancel: { showingAdd = false }
        }
        .sheet(isPresented: $showAddSingleSheet) {
            SinglePaymentFormView(
                name: $singleName,
                category: $singleCategory,
                amount: $singleAmount,
                payer: $singlePayer,
                date: $singleDate,
                onCancel: { showAddSingleSheet = false },
                onSave: { saveSingleFromSheet() }
            )
        }
    }

    private func addItem(_ item: PaymentItem) {
        var i = item
        if i.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            i.name = i.category.rawValue
        }
        items.append(i)
        storage.save(items)
        Task { await PaymentNotifier.shared.schedule(for: i) }
        showingAdd = false
    }

    private func updateItem(_ item: PaymentItem) {
        if let idx = items.firstIndex(where: { $0.id == item.id }) {
            items[idx] = item
            storage.save(items)
            Task { await PaymentNotifier.shared.schedule(for: item) }
        }
    }

    private func deleteItem(_ item: PaymentItem) {
        items.removeAll { $0.id == item.id }
        storage.save(items)
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [item.id.uuidString])
    }

    private func remove(at offsets: IndexSet) {
        let removed = offsets.map { items[$0] }
        items.remove(atOffsets: offsets)
        storage.save(items)
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: removed.map { $0.id.uuidString })
    }

    private func saveSingleFromSheet() {
        guard let amount = Double(singleAmount) else { return }
        var name = singleName.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty { name = singleCategory.rawValue }

        let record = PaymentRecord(date: singleDate, amount: amount, payer: singlePayer)
        let oneOff = PaymentItem(
            name: name,
            category: singleCategory,
            dayOfMonth: 1,
            remindDaysBefore: 0,
            intervalMonths: 1,
            records: [record]
        )
        items.append(oneOff)
        storage.save(items)
        showAddSingleSheet = false
    }
}

// MARK: - Lightweight row (避免在 label 內做排序)

private struct PaymentRow: View {
    let item: PaymentItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.category.symbol)
                .foregroundStyle(item.category.color)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name).font(.headline)
                Text("每 \(item.intervalMonths) 個月的 \(item.dayOfMonth) 號 · 提前 \(item.remindDaysBefore) 天提醒")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let last = item.lastRecord {
                Text(String(format: "$%.0f", last.amount))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Detail view（排序只做一次）

struct PaymentDetailView: View {
    @State var item: PaymentItem
    var onSave: (PaymentItem) -> Void
    var onDelete: () -> Void

    @State private var showingEdit = false
    @State private var newAmount: String = ""
    @State private var newPayer: String = ""
    @State private var newDate: Date = Date()

    @State private var editTargetRecord: PaymentRecord?
    @State private var showEditRecordSheet: Bool = false

    var body: some View {
        ZStack {
            #if DEBUG
            if isPreview {
                LinearGradient(colors: [.clear, .clear], startPoint: .top, endPoint: .bottom)
                    .opacity(0.5)
                    .allowsHitTesting(false)
            } else {
                safeBackground(named: "Back_4")
            }
            #else
            safeBackground(named: "Back_4")
            #endif

            List {
                Section("設定") {
                    displayRow("名稱", value: item.name)
                    displayRow("類別", value: item.category.rawValue, symbol: item.category.symbol)
                    displayRow("每幾個月", value: "\(item.intervalMonths) 個月")
                    displayRow("每月日子", value: "\(item.dayOfMonth) 號")
                    displayRow("提前提醒", value: "\(item.remindDaysBefore) 天")
                    Button { showingEdit = true } label: {
                        Label("修改設定", systemImage: "pencil")
                    }
                }

                Section("新增本期費用") {
                    HStack {
                        Text("金額")
                        TextField("0", text: $newAmount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("付款人")
                        TextField("例如 我 / 對方 / 名字", text: $newPayer)
                            .multilineTextAlignment(.trailing)
                    }
                    DatePicker("日期", selection: $newDate, displayedComponents: .date)

                    Button {
                        addRecord()
                    } label: {
                        Label("加入紀錄", systemImage: "plus.circle.fill")
                    }
                    .disabled(Double(newAmount) == nil || newPayer.trimmingCharacters(in: .whitespaces).isEmpty)
                }

                if !item.records.isEmpty {
                    Section("歷史紀錄") {
                        let sorted = item.records.sorted(by: { $0.date > $1.date })
                        ForEach(sorted, id: \.id) { r in
                            Button {
                                editTargetRecord = r
                                showEditRecordSheet = true
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(r.date.formatted(date: .abbreviated, time: .omitted))
                                            .font(.subheadline.weight(.semibold))
                                        Text(r.payer)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text(String(format: "$%.0f", r.amount))
                                        .font(.headline)
                                }
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) { deleteRecord(r) } label: {
                                    Label("刪除此筆", systemImage: "trash")
                                }
                            }
                        }
                        .onDelete { indexSet in
                            let sorted = item.records.sorted(by: { $0.date > $1.date })
                            let ids = indexSet.compactMap { $0 < sorted.count ? sorted[$0].id : nil }
                            item.records.removeAll { ids.contains($0.id) }
                            onSave(item)
                        }
                    }

                    Section("消費分析（依付款人）") {
                        if #available(iOS 16.0, *) {
                            PaymentPieChart(records: item.records)
                                .frame(height: 220)
                        } else {
                            Text("需要 iOS 16 以上才能顯示圖表")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .padding(.top, 16)
            .safeAreaInset(edge: .top) { Color.clear.frame(height: 8) }
        }
        .navigationTitle(item.name)
        .sheet(isPresented: $showingEdit) {
            PaymentEditView(item: item) { updated in
                item = updated
                onSave(updated)
                showingEdit = false
            } onCancel: { showingEdit = false }
        }
        .sheet(isPresented: $showEditRecordSheet) {
            if let target = editTargetRecord {
                RecordEditView(
                    record: target,
                    onCancel: { showEditRecordSheet = false },
                    onSave: { updated in
                        applyEditedRecord(updated)
                        showEditRecordSheet = false
                    },
                    onDelete: {
                        deleteRecord(target)
                        showEditRecordSheet = false
                    }
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) { onDelete() } label: {
                        Label("刪除項目", systemImage: "trash")
                    }
                } label: { Image(systemName: "ellipsis.circle") }
            }
        }
    }

    private func displayRow(_ title: String, value: String, symbol: String? = nil) -> some View {
        HStack {
            Text(title)
            Spacer()
            if let symbol {
                Label(value, systemImage: symbol).foregroundStyle(.secondary)
            } else {
                Text(value).foregroundStyle(.secondary)
            }
        }
    }

    private func addRecord() {
        guard let amount = Double(newAmount) else { return }
        let rec = PaymentRecord(date: newDate, amount: amount, payer: newPayer)
        item.records.append(rec)
        onSave(item)
        newAmount = ""
        newPayer = ""
        newDate = Date()
    }

    private func applyEditedRecord(_ updated: PaymentRecord) {
        if let idx = item.records.firstIndex(where: { $0.id == updated.id }) {
            item.records[idx] = updated
            onSave(item)
        }
    }

    private func deleteRecord(_ r: PaymentRecord) {
        item.records.removeAll { $0.id == r.id }
        onSave(item)
    }
}

// MARK: - Edit view

struct PaymentEditView: View {
    @State var item: PaymentItem
    var onSave: (PaymentItem) -> Void
    var onCancel: () -> Void

    var body: some View {
        Form {
            Section("基本") {
                TextField("名稱", text: $item.name)
                Picker("類別", selection: $item.category) {
                    ForEach(PaymentCategory.allCases) { cat in
                        Label(cat.rawValue, systemImage: cat.symbol).tag(cat)
                    }
                }
            }
            Section("提醒設定") {
                Stepper(value: $item.intervalMonths, in: 1...12) {
                    Text("每 \(item.intervalMonths) 個月")
                }
                Stepper(value: $item.dayOfMonth, in: 1...28) {
                    Text("每月 \(item.dayOfMonth) 號")
                }
                Stepper(value: $item.remindDaysBefore, in: 0...14) {
                    Text("提前 \(item.remindDaysBefore) 天提醒")
                }
            }
        }
        .navigationTitle("編輯項目")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { onCancel() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("儲存") {
                    var fixed = item
                    if fixed.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        fixed.name = fixed.category.rawValue
                    }
                    onSave(fixed)
                }
            }
        }
    }
}

// MARK: - Record edit sheet

private struct RecordEditView: View {
    @State var record: PaymentRecord
    var onCancel: () -> Void
    var onSave: (PaymentRecord) -> Void
    var onDelete: () -> Void

    @State private var amountText: String = ""
    @State private var payerText: String = ""
    @State private var dateValue: Date = Date()

    private var canSave: Bool {
        Double(amountText) != nil && !payerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(record: PaymentRecord, onCancel: @escaping () -> Void, onSave: @escaping (PaymentRecord) -> Void, onDelete: @escaping () -> Void) {
        self._record = State(initialValue: record)
        self.onCancel = onCancel
        self.onSave = onSave
        self.onDelete = onDelete
        self._amountText = State(initialValue: String(format: "%.0f", record.amount))
        self._payerText = State(initialValue: record.payer)
        self._dateValue = State(initialValue: record.date)
    }

    var body: some View {
        Form {
            Section("紀錄內容") {
                TextField("金額", text: $amountText).keyboardType(.decimalPad)
                TextField("付款人", text: $payerText)
                    .textInputAutocapitalization(.none)
                    .autocorrectionDisabled()
                DatePicker("日期", selection: $dateValue, displayedComponents: .date)
            }

            Section {
                Button(role: .destructive) { onDelete() } label: {
                    Label("刪除這筆紀錄", systemImage: "trash")
                }
            }
        }
        .navigationTitle("編輯紀錄")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("取消") { onCancel() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("儲存") {
                    guard let amount = Double(amountText) else { return }
                    var updated = record
                    updated.amount = amount
                    updated.payer = payerText
                    updated.date = dateValue
                    onSave(updated)
                }
                .disabled(!canSave)
            }
        }
    }
}

// MARK: - Pie chart（只在詳細頁使用，避免主頁負擔）

struct PaymentPieChart: View {
    let records: [PaymentRecord]

    private var grouped: [(payer: String, total: Double)] {
        // 單次 O(n) 彙總
        var totals: [String: Double] = [:]
        for r in records {
            totals[r.payer, default: 0] += r.amount
        }
        return totals.map { ($0.key, $0.value) }
            .sorted { $0.total > $1.total }
    }

    var body: some View {
        Chart(grouped, id: \.payer) { row in
            SectorMark(
                angle: .value("金額", row.total),
                innerRadius: .ratio(0.5),
                angularInset: 1
            )
            .foregroundStyle(by: .value("付款人", row.payer))
            .annotation(position: .overlay) {
                if row.total > (totalAmount() * 0.08) {
                    Text("\(row.payer)\n\(String(format: "$%.0f", row.total))")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.white)
                }
            }
        }
        .chartLegend(.visible)
        .chartBackground { _ in
            if records.isEmpty {
                Text("尚無資料").foregroundStyle(.secondary)
            }
        }
    }

    private func totalAmount() -> Double {
        records.reduce(0) { $0 + $1.amount }
    }
}

#Preview("主畫面（輕量預覽）") {
    NavigationStack {
        PaymentView()
    }
}

#Preview("詳細頁（假資料）") {
    NavigationStack {
        PaymentDetailView(
            item: PaymentItem(
                name: "電費",
                category: .electricity,
                records: [
                    PaymentRecord(date: .now, amount: 800, payer: "我"),
                    PaymentRecord(date: .now.addingTimeInterval(-86400*30), amount: 760, payer: "對方")
                ]
            ),
            onSave: { _ in },
            onDelete: {}
        )
    }
}

// MARK: - Single one-off payment form
private struct SinglePaymentFormView: View {
    @Binding var name: String
    @Binding var category: PaymentCategory
    @Binding var amount: String
    @Binding var payer: String
    @Binding var date: Date

    var onCancel: () -> Void
    var onSave: () -> Void

    private var canSave: Bool {
        // 名稱可留空，外層會以類別名稱代填；此處只驗證金額與付款人
        Double(amount) != nil && !payer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("基本資訊") {
                    TextField("名稱（可留空）", text: $name)
                    Picker("類別", selection: $category) {
                        ForEach(PaymentCategory.allCases) { cat in
                            Label(cat.rawValue, systemImage: cat.symbol).tag(cat)
                        }
                    }
                }

                Section("紀錄內容") {
                    TextField("金額", text: $amount)
                        .keyboardType(.decimalPad)
                    TextField("付款人", text: $payer)
                        .textInputAutocapitalization(.none)
                        .autocorrectionDisabled()
                    DatePicker("日期", selection: $date, displayedComponents: .date)
                }
            }
            .navigationTitle("新增單一項目")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") { onSave() }
                        .disabled(!canSave)
                }
            }
        }
    }
}

