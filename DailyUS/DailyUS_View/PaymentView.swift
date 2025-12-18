//
//  PaymentView.swift
//  DailyUS
//
//  Created by 陳芸萱 on 2025/12/19.
//

import SwiftUI
import UserNotifications
import Charts

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
    var payer: String // 例如「我」「對方」或名字

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

    // 提醒設定
    var dayOfMonth: Int            // 每月幾號（1...28，避免月底跨月問題）
    var remindDaysBefore: Int      // 提前幾天提醒
    var intervalMonths: Int        // 每幾個月一次（1=每月、2=雙月…）

    // 歷史紀錄
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
}

// MARK: - Simple JSON storage via AppStorage

private struct PaymentStorage {
    @AppStorage("payment_items_json") private var raw: String = ""

    func load() -> [PaymentItem] {
        guard let data = raw.data(using: .utf8), !raw.isEmpty else { return defaultItems() }
        do {
            return try JSONDecoder().decode([PaymentItem].self, from: data)
        } catch {
            return defaultItems()
        }
    }

    func save(_ items: [PaymentItem]) {
        do {
            let data = try JSONEncoder().encode(items)
            if let s = String(data: data, encoding: .utf8) {
                raw = s
            }
        } catch {
            // ignore
        }
    }

    private func defaultItems() -> [PaymentItem] {
        [
            PaymentItem(name: "水費", category: .water, dayOfMonth: 5, remindDaysBefore: 3, intervalMonths: 2),
            PaymentItem(name: "電費", category: .electricity, dayOfMonth: 10, remindDaysBefore: 3, intervalMonths: 2),
            PaymentItem(name: "瓦斯費", category: .gas, dayOfMonth: 12, remindDaysBefore: 2, intervalMonths: 1),
            PaymentItem(name: "房租", category: .rent, dayOfMonth: 1, remindDaysBefore: 5, intervalMonths: 1)
        ]
    }
}

// MARK: - Notification scheduler

actor PaymentNotifier {
    static let shared = PaymentNotifier()

    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }

    func schedule(for item: PaymentItem) async {
        let center = UNUserNotificationCenter.current()
        // 清除同 id 舊的排程
        await center.removePendingNotificationRequests(withIdentifiers: [item.id.uuidString])

        // 計算下一次提醒日期（簡化：固定每月/每 n 個月的 dayOfMonth，提前 remindDaysBefore 天）
        guard let next = nextTriggerDate(day: item.dayOfMonth, monthsInterval: item.intervalMonths, daysBefore: item.remindDaysBefore) else { return }

        var comps = Calendar.current.dateComponents([.year, .month, .day], from: next)
        comps.hour = 9 // 早上 9 點提醒，可視需求改 UI 設定

        // 注意：UNCalendarNotificationTrigger 的 repeats 無法直接支援「每 n 個月」此類間隔。
        // 這裡示範使用 repeats: true（每年同月日），實務上建議 repeats: false 並在 app 啟動或進入頁面時重新計算下一次排程。
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = "繳費提醒：\(item.name)"
        content.body = "快到繳費日囉（每 \(item.intervalMonths) 個月的 \(item.dayOfMonth) 號），別忘了！"
        content.sound = .default

        let req = UNNotificationRequest(identifier: item.id.uuidString, content: content, trigger: trigger)
        do {
            try await center.add(req)
        } catch {
            // ignore
        }
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

    var body: some View {
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
                        HStack(spacing: 12) {
                            Image(systemName: item.category.symbol)
                                .foregroundStyle(item.category.color)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.name)
                                    .font(.headline)
                                Text("每 \(item.intervalMonths) 個月的 \(item.dayOfMonth) 號 · 提前 \(item.remindDaysBefore) 天提醒")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let last = item.records.sorted(by: { $0.date > $1.date }).first {
                                Text(String(format: "$%.0f", last.amount))
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }
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
                    Label("新增項目", systemImage: "plus.circle.fill")
                }
            }
        }
        .navigationTitle("繳費與記帳")
        .onAppear {
            items = storage.load()
        }
        .sheet(isPresented: $showingAdd) {
            NavigationStack {
                PaymentEditView(item: PaymentItem(name: "", category: .other)) { newItem in
                    addItem(newItem)
                } onCancel: { showingAdd = false }
            }
        }
        .task {
            _ = await PaymentNotifier.shared.requestAuthorization()
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
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [item.id.uuidString])
    }

    private func remove(at offsets: IndexSet) {
        let removed = offsets.map { items[$0] }
        items.remove(atOffsets: offsets)
        storage.save(items)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: removed.map { $0.id.uuidString })
    }
}

// MARK: - Detail view

struct PaymentDetailView: View {
    @State var item: PaymentItem
    var onSave: (PaymentItem) -> Void
    var onDelete: () -> Void

    @State private var showingEdit = false
    @State private var newAmount: String = ""
    @State private var newPayer: String = ""
    @State private var newDate: Date = Date()

    var body: some View {
        List {
            Section("設定") {
                HStack {
                    Text("名稱")
                    Spacer()
                    Text(item.name).foregroundStyle(.secondary)
                }
                HStack {
                    Text("類別")
                    Spacer()
                    Label(item.category.rawValue, systemImage: item.category.symbol)
                        .labelStyle(.titleAndIcon)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("每幾個月")
                    Spacer()
                    Text("\(item.intervalMonths) 個月").foregroundStyle(.secondary)
                }
                HStack {
                    Text("每月日子")
                    Spacer()
                    Text("\(item.dayOfMonth) 號").foregroundStyle(.secondary)
                }
                HStack {
                    Text("提前提醒")
                    Spacer()
                    Text("\(item.remindDaysBefore) 天").foregroundStyle(.secondary)
                }
                Button {
                    showingEdit = true
                } label: {
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
                    ForEach(item.records.sorted(by: { $0.date > $1.date })) { r in
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
                }

                Section("消費分析（依付款人）") {
                    PaymentPieChart(records: item.records)
                        .frame(height: 220)
                }
            }
        }
        .navigationTitle(item.name)
        .sheet(isPresented: $showingEdit) {
            NavigationStack {
                PaymentEditView(item: item) { updated in
                    item = updated
                    onSave(updated)
                    showingEdit = false
                } onCancel: {
                    showingEdit = false
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("刪除項目", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }

    private func addRecord() {
        guard let amount = Double(newAmount) else { return }
        let rec = PaymentRecord(amount: amount, payer: newPayer, date: newDate)
        item.records.append(rec)
        onSave(item)
        newAmount = ""
        newPayer = ""
        newDate = Date()
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

// MARK: - Pie chart

struct PaymentPieChart: View {
    let records: [PaymentRecord]

    private var grouped: [(payer: String, total: Double)] {
        let dict = Dictionary(grouping: records, by: { $0.payer })
            .mapValues { $0.reduce(0) { $0 + $1.amount } }
        return dict.map { ($0.key, $0.value) }.sorted { $0.total > $1.total }
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
                Text("尚無資料")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func totalAmount() -> Double {
        records.reduce(0) { $0 + $1.amount }
    }
}
