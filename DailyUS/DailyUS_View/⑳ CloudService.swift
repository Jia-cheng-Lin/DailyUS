//
//  ⑳ CloudService.swift
//  DailyUS
//
//  Created by 陳芸萱 on 2025/12/3.
//

import Foundation

// MARK: - Cloud Sync Errors

public enum CloudSyncError: Error, LocalizedError, Sendable {
    case notFound
    case permissionDenied
    case network
    case decoding
    case encoding
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .notFound: return "找不到資料"
        case .permissionDenied: return "沒有權限"
        case .network: return "網路連線異常"
        case .decoding: return "資料解析失敗"
        case .encoding: return "資料編碼失敗"
        case .unknown(let msg): return "未知錯誤：\(msg)"
        }
    }
}

// MARK: - Cloud Service Protocol

public protocol CloudService: Sendable {
    // Users
    func createUser(_ user: User) async throws -> User
    func fetchUser(id: String) async throws -> User
    func updateUser(_ user: User) async throws -> User
    func deleteUser(id: String) async throws

    // Couples
    func createCouple(_ couple: Couple) async throws -> Couple
    func fetchCouple(id: String) async throws -> Couple
    func updateCouple(_ couple: Couple) async throws -> Couple
    func deleteCouple(id: String) async throws

    // Mood
    func addMoodRecord(_ record: MoodRecord) async throws -> MoodRecord
    func listMoodRecords(coupleID: String, limit: Int?) async throws -> [MoodRecord]

    // Messages
    func addMessage(_ message: Message) async throws -> Message
    func listMessages(coupleID: String, limit: Int?) async throws -> [Message]

    // Daily Questions
    func upsertDailyQuestion(_ question: DailyQuestionModel) async throws -> DailyQuestionModel
    func fetchDailyQuestion(for date: Date) async throws -> DailyQuestionModel
    func submitAnswer(_ answer: DailyQuestionAnswerModel) async throws -> DailyQuestionAnswerModel
    func listAnswers(questionID: String, coupleID: String) async throws -> [DailyQuestionAnswerModel]
}

// MARK: - Shared entry point

public enum Cloud {
    // Switch to Firebase implementation
    public static let shared: CloudService = FirebaseCloudService()
}

// MARK: - Thread-safe in-memory mock (development)

actor MockCloudStorage {
    var users: [String: User] = [:]
    var couples: [String: Couple] = [:]
    var moods: [String: MoodRecord] = [:]
    var messages: [String: Message] = [:]
    var questions: [String: DailyQuestionModel] = [:] // keyed by id
    var answers: [String: DailyQuestionAnswerModel] = [:]

    // Helper indexes
    func questionForDay(_ day: Date) -> DailyQuestionModel? {
        let key = dayKey(day)
        return questions.values.first { dayKey($0.date) == key }
    }

    func dayKey(_ date: Date) -> String {
        let comps = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(comps.year ?? 0)-\(comps.month ?? 0)-\(comps.day ?? 0)"
    }
}

public final class MockCloudService: CloudService, @unchecked Sendable {
    private let store = MockCloudStorage()

    public init() {}

    // MARK: Users
    public func createUser(_ user: User) async throws -> User {
        try await Task.sleep(nanoseconds: 50_000_000)
        await store.users[user.id] = user
        return user
    }

    public func fetchUser(id: String) async throws -> User {
        try await Task.sleep(nanoseconds: 30_000_000)
        guard let u = await store.users[id] else { throw CloudSyncError.notFound }
        return u
    }

    public func updateUser(_ user: User) async throws -> User {
        try await Task.sleep(nanoseconds: 40_000_000)
        guard await store.users[user.id] != nil else { throw CloudSyncError.notFound }
        await store.users[user.id] = user
        return user
    }

    public func deleteUser(id: String) async throws {
        try await Task.sleep(nanoseconds: 30_000_000)
        await store.users.removeValue(forKey: id)
    }

    // MARK: Couples
    public func createCouple(_ couple: Couple) async throws -> Couple {
        try await Task.sleep(nanoseconds: 50_000_000)
        await store.couples[couple.id] = couple
        return couple
    }

    public func fetchCouple(id: String) async throws -> Couple {
        try await Task.sleep(nanoseconds: 30_000_000)
        guard let c = await store.couples[id] else { throw CloudSyncError.notFound }
        return c
    }

    public func updateCouple(_ couple: Couple) async throws -> Couple {
        try await Task.sleep(nanoseconds: 40_000_000)
        guard await store.couples[couple.id] != nil else { throw CloudSyncError.notFound }
        await store.couples[couple.id] = couple
        return couple
    }

    public func deleteCouple(id: String) async throws {
        try await Task.sleep(nanoseconds: 30_000_000)
        await store.couples.removeValue(forKey: id)
    }

    // MARK: Mood
    public func addMoodRecord(_ record: MoodRecord) async throws -> MoodRecord {
        try await Task.sleep(nanoseconds: 40_000_000)
        await store.moods[record.id] = record
        return record
    }

    public func listMoodRecords(coupleID: String, limit: Int?) async throws -> [MoodRecord] {
        try await Task.sleep(nanoseconds: 40_000_000)
        let all = await store.moods.values.filter { $0.coupleID == coupleID }
            .sorted(by: { $0.date > $1.date })
        if let limit { return Array(all.prefix(limit)) }
        return all
    }

    // MARK: Messages
    public func addMessage(_ message: Message) async throws -> Message {
        try await Task.sleep(nanoseconds: 40_000_000)
        await store.messages[message.id] = message
        return message
    }

    public func listMessages(coupleID: String, limit: Int?) async throws -> [Message] {
        try await Task.sleep(nanoseconds: 40_000_000)
        let all = await store.messages.values.filter { $0.coupleID == coupleID }
            .sorted(by: { $0.createdAt > $1.createdAt })
        if let limit { return Array(all.prefix(limit)) }
        return all
    }

    // MARK: Daily Questions
    public func upsertDailyQuestion(_ question: DailyQuestionModel) async throws -> DailyQuestionModel {
        try await Task.sleep(nanoseconds: 50_000_000)
        await store.questions[question.id] = question
        return question
    }

    public func fetchDailyQuestion(for date: Date) async throws -> DailyQuestionModel {
        try await Task.sleep(nanoseconds: 40_000_000)
        if let q = await store.questionForDay(date) {
            return q
        } else {
            throw CloudSyncError.notFound
        }
    }

    public func submitAnswer(_ answer: DailyQuestionAnswerModel) async throws -> DailyQuestionAnswerModel {
        try await Task.sleep(nanoseconds: 50_000_000)
        await store.answers[answer.id] = answer
        return answer
    }

    public func listAnswers(questionID: String, coupleID: String) async throws -> [DailyQuestionAnswerModel] {
        try await Task.sleep(nanoseconds: 40_000_000)
        let all = await store.answers.values.filter { $0.questionID == questionID && $0.coupleID == coupleID }
            .sorted(by: { $0.createdAt > $1.createdAt })
        return all
    }
}
