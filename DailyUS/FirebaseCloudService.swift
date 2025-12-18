import Foundation
import FirebaseCore
import FirebaseFirestore
import FirebaseFirestoreSwift

// Firestore-based implementation of CloudService.
// Step 1: Implement Couples & Messages for pairing + chat flow.
// Step 2: You can extend others (Users/Mood/DailyQ) later similarly.
public final class FirebaseCloudService: CloudService, @unchecked Sendable {
    private let db: Firestore

    public init(db: Firestore = Firestore.firestore()) {
        self.db = db
    }

    // MARK: - Collections
    private var usersCol: CollectionReference { db.collection("users") }
    private var couplesCol: CollectionReference { db.collection("couples") }
    private var messagesCol: CollectionReference { db.collection("messages") } // flat collection; you may change to subcollection if you prefer

    // MARK: - Users
    public func createUser(_ user: User) async throws -> User {
        try await usersCol.document(user.id).setData(from: user, merge: false)
        return user
    }

    public func fetchUser(id: String) async throws -> User {
        let snap = try await usersCol.document(id).getDocument()
        guard let u = try snap.data(as: User?.self) else { throw CloudSyncError.notFound }
        return u
    }

    public func updateUser(_ user: User) async throws -> User {
        try await usersCol.document(user.id).setData(from: user, merge: true)
        return user
    }

    public func deleteUser(id: String) async throws {
        try await usersCol.document(id).delete()
    }

    // MARK: - Couples
    public func createCouple(_ couple: Couple) async throws -> Couple {
        try await couplesCol.document(couple.id).setData(from: couple, merge: false)
        return couple
    }

    public func fetchCouple(id: String) async throws -> Couple {
        let snap = try await couplesCol.document(id).getDocument()
        guard let c = try snap.data(as: Couple?.self) else { throw CloudSyncError.notFound }
        return c
    }

    public func updateCouple(_ couple: Couple) async throws -> Couple {
        try await couplesCol.document(couple.id).setData(from: couple, merge: true)
        return couple
    }

    public func deleteCouple(id: String) async throws {
        try await couplesCol.document(id).delete()
    }

    // MARK: - Mood (not implemented yet)
    public func addMoodRecord(_ record: MoodRecord) async throws -> MoodRecord {
        // Implement later
        throw CloudSyncError.unknown("Mood not implemented yet")
    }

    public func listMoodRecords(coupleID: String, limit: Int?) async throws -> [MoodRecord] {
        // Implement later
        return []
    }

    // MARK: - Messages
    public func addMessage(_ message: Message) async throws -> Message {
        try await messagesCol.document(message.id).setData(from: message, merge: false)
        return message
    }

    public func listMessages(coupleID: String, limit: Int?) async throws -> [Message] {
        var q: Query = messagesCol.whereField("coupleID", isEqualTo: coupleID).order(by: "createdAt", descending: true)
        if let limit { q = q.limit(to: limit) }
        let snap = try await q.getDocuments()
        let items: [Message] = try snap.documents.compactMap { doc in
            try doc.data(as: Message.self)
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
