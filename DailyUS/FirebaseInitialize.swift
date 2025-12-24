import Foundation
import FirebaseCore
import FirebaseFirestore

enum FirestoreInitializer {
    static func firestoreSmokeTest() {
        let db = Firestore.firestore()
        db.collection("smokeTests").document("hello").setData([
            "message": "Hello Firebase",
            "timestamp": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                print("Firestore write error:", error)
            } else {
                print("Firestore write success")
                db.collection("smokeTests").document("hello").getDocument { snapshot, error in
                    if let data = snapshot?.data() {
                        print("Firestore read success:", data)
                    } else {
                        print("Firestore read error:", error ?? "nil")
                    }
                }
            }
        }
    }
}
