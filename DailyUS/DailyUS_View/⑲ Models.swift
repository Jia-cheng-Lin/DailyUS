//
//  ⑲ Models.swift
//  DailyUS
//
//  Created by 陳芸萱 on 2025/12/2.
//

import Foundation

// MARK: - User

public struct User: Identifiable, Codable, Sendable, Hashable {
    public let id: String                // userID
    public var name: String
    public var role: String              // e.g., "男友" / "女友" / "伴侶"
    public var coupleID: String?         // linked couple if paired
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: String = UUID().uuidString,
        name: String,
        role: String,
        coupleID: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.coupleID = coupleID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Couple

public struct Couple: Identifiable, Codable, Sendable, Hashable {
    public let id: String                // coupleID
    public var userIDs: [String]         // usually 2 userIDs
    public var startedAt: Date?          // 在一起日期
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: String = UUID().uuidString,
        userIDs: [String],
        startedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userIDs = userIDs
        self.startedAt = startedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - MoodRecord

public struct MoodRecord: Identifiable, Codable, Sendable, Hashable {
    public let id: String
    public var coupleID: String
    public var userID: String
    public var score: Int                // 0...10
    public var note: String?             // optional text
    public var date: Date                // when recorded
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: String = UUID().uuidString,
        coupleID: String,
        userID: String,
        score: Int,
        note: String? = nil,
        date: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.coupleID = coupleID
        self.userID = userID
        self.score = max(0, min(10, score))
        self.note = note
        self.date = date
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Message

public struct Message: Identifiable, Codable, Sendable, Hashable {
    public let id: String
    public var coupleID: String
    public var fromUserID: String
    public var toUserID: String?
    public var text: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: String = UUID().uuidString,
        coupleID: String,
        fromUserID: String,
        toUserID: String? = nil,
        text: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.coupleID = coupleID
        self.fromUserID = fromUserID
        self.toUserID = toUserID
        self.text = text
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - DailyQuestion (renamed to avoid collision)

public struct DailyQuestionModel: Identifiable, Codable, Sendable, Hashable {
    public let id: String
    public var title: String                 // 問題文字
    public var date: Date                    // 問題的日期（每日一題）
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: String = UUID().uuidString,
        title: String,
        date: Date = Date(),
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - DailyQuestionAnswer (renamed accordingly)

public struct DailyQuestionAnswerModel: Identifiable, Codable, Sendable, Hashable {
    public let id: String
    public var questionID: String
    public var coupleID: String
    public var userID: String
    public var answer: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: String = UUID().uuidString,
        questionID: String,
        coupleID: String,
        userID: String,
        answer: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.questionID = questionID
        self.coupleID = coupleID
        self.userID = userID
        self.answer = answer
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
