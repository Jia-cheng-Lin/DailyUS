//
//  FirebaseTest.swift
//  DailyUS
//
//  Created by 陳芸萱 on 2025/12/18.
//

import FirebaseFirestore
import Playgrounds

struct Song: Codable, Identifiable {
    @DocumentID var id: String?
    let name: String
    let singer: String
    let rate: Int
}

func createSong() {
    let db = Firestore.firestore()
    
    let song = Song(name: "陪你很久很久", singer: "小球", rate: 5)
    print("Test")
    do {
        let documentReference = try db.collection("songs").addDocument(from: song)
        print(documentReference.documentID)
    } catch {
        print(error)
    }
}


//#Playground {
//    createSong()
//}

