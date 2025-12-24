import Foundation
import FirebaseCore
import FirebaseFirestore

public final class FirebaseCloudService: CloudService, @unchecked Sendable {
    private let db: Firestore

    public init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    // MARK: - Collections
    private var usersCol: CollectionReference { db.collection("users") }
    private var couplesCol: CollectionReference { db.collection("couples") }
    private var messagesCol: CollectionReference { db.collection("messages") }

    // MARK: - Users
    public func createUser(_ user: User) async throws -> User {
        try await usersCol.document(user.id).setData(user.toDict())
        return user
    }

    public func fetchUser(id: String) async throws -> User {
        let snap = try await usersCol.document(id).getDocument()
        guard let data = snap.data(), let u = User.fromDict(id: snap.documentID, data: data) else {
            throw CloudSyncError.notFound
        }
        return u
    }

    public func updateUser(_ user: User) async throws -> User {
        try await usersCol.document(user.id).setData(user.toDict(), merge: true)
        return user
    }

    public func deleteUser(id: String) async throws {
        try await usersCol.document(id).delete()
    }

    // MARK: - Couples
    public func createCouple(_ couple: Couple) async throws -> Couple {
        try await couplesCol.document(couple.id).setData(couple.toDict())
        return couple
    }

    public func fetchCouple(id: String) async throws -> Couple {
        let snap = try await couplesCol.document(id).getDocument()
        guard let data = snap.data(), let c = Couple.fromDict(id: snap.documentID, data: data) else {
            throw CloudSyncError.notFound
        }
        return c
    }

    public func updateCouple(_ couple: Couple) async throws -> Couple {
        try await couplesCol.document(couple.id).setData(couple.toDict(), merge: true)
        return couple
    }

    public func deleteCouple(id: String) async throws {
        try await couplesCol.document(id).delete()
    }

    // MARK: - Mood (not implemented yet)
    public func addMoodRecord(_ record: MoodRecord) async throws -> MoodRecord {
        throw CloudSyncError.unknown("Mood not implemented yet")
    }

    public func listMoodRecords(coupleID: String, limit: Int?) async throws -> [MoodRecord] {
        return []
    }

    // MARK: - Messages
    public func addMessage(_ message: Message) async throws -> Message {
        try await messagesCol.document(message.id).setData(message.toDict())
        return message
    }

    public func listMessages(coupleID: String, limit: Int?) async throws -> [Message] {
        var q: Query = messagesCol.whereField("coupleID", isEqualTo: coupleID).order(by: "createdAt", descending: true)
        if let limit { q = q.limit(to: limit) }
        let snap = try await q.getDocuments()
        let items: [Message] = snap.documents.compactMap { doc in
            guard let m = Message.fromDict(id: doc.documentID, data: doc.data()) else { return nil }
            return m
        }
        return items
    }

    // MARK: - Daily Questions (not implemented yet)
    public func upsertDailyQuestion(_ question: DailyQuestionModel) async throws -> DailyQuestionModel {
        throw CloudSyncError.unknown("DailyQuestion not implemented yet")
    }

    public func fetchDailyQuestion(for date: Date) async throws -> DailyQuestionModel {
        throw CloudSyncError.unknown("DailyQuestion not implemented yet")
    }

    public func submitAnswer(_ answer: DailyQuestionAnswerModel) async throws -> DailyQuestionAnswerModel {
        throw CloudSyncError.unknown("DailyQuestion not implemented yet")
    }

    public func listAnswers(questionID: String, coupleID: String) async throws -> [DailyQuestionAnswerModel] {
        return []
    }
}
// MARK: - Manual mapping helpers (dictionary <-> model)
private extension User {
    func toDict() -> [String: Any] {
        [
            "id": id,
            "name": name,
            "role": role,
            "coupleID": coupleID as Any,
            "createdAt": createdAt,
            "updatedAt": updatedAt
        ]
    }

    static func fromDict(id: String, data: [String: Any]) -> User? {
        guard
            let name = data["name"] as? String,
            let role = data["role"] as? String,
            let createdAt = data["createdAt"] as? TimestampConvertible,
            let updatedAt = data["updatedAt"] as? TimestampConvertible
        else { return nil }
        let coupleID = data["coupleID"] as? String
        return User(
            id: id,
            name: name,
            role: role,
            coupleID: coupleID,
            createdAt: createdAt.asDate,
            updatedAt: updatedAt.asDate
        )
    }
}

private extension Couple {
    func toDict() -> [String: Any] {
        [
            "id": id,
            "userIDs": userIDs,
            "startedAt": startedAt as Any,
            "createdAt": createdAt,
            "updatedAt": updatedAt
        ]
    }

    static func fromDict(id: String, data: [String: Any]) -> Couple? {
        guard
            let userIDs = data["userIDs"] as? [String],
            let createdAt = data["createdAt"] as? TimestampConvertible,
            let updatedAt = data["updatedAt"] as? TimestampConvertible
        else { return nil }
        let startedAt = (data["startedAt"] as? TimestampConvertible)?.asDate
        return Couple(
            id: id,
            userIDs: userIDs,
            startedAt: startedAt,
            createdAt: createdAt.asDate,
            updatedAt: updatedAt.asDate
        )
    }
}

private extension Message {
    func toDict() -> [String: Any] {
        [
            "id": id,
            "coupleID": coupleID,
            "fromUserID": fromUserID,
            "toUserID": toUserID as Any,
            "text": text,
            "createdAt": createdAt,
            "updatedAt": updatedAt
        ]
    }

    static func fromDict(id: String, data: [String: Any]) -> Message? {
        guard
            let coupleID = data["coupleID"] as? String,
            let fromUserID = data["fromUserID"] as? String,
            let text = data["text"] as? String,
            let createdAt = data["createdAt"] as? TimestampConvertible,
            let updatedAt = data["updatedAt"] as? TimestampConvertible
        else { return nil }
        let toUserID = data["toUserID"] as? String
        return Message(
            id: id,
            coupleID: coupleID,
            fromUserID: fromUserID,
            toUserID: toUserID,
            text: text,
            createdAt: createdAt.asDate,
            updatedAt: updatedAt.asDate
        )
    }
}

// MARK: - Timestamp helper
// Firestore iOS SDK 10.17+ 對 Date 支援更好，但若讀到 Timestamp 型別，這裡提供一個轉換協定
private protocol TimestampConvertible {
    var asDate: Date { get }
}
extension Date: TimestampConvertible { var asDate: Date { self } }
// 若讀到的是 Firestore.Timestamp，避免直接 import FirebaseFirestoreSwift，我們用 type-erasure 方式處理
extension NSObject: TimestampConvertible {
    @objc var asDate: Date {
        if let ts = self.value(forKey: "dateValue") as? Date { return ts }
        return self as? Date ?? Date()
    }
}

