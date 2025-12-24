//
//  LoadMessage.swift
//  DailyUS
//
//  Created by 陳芸萱 on 2025/12/23.
//

import SwiftUI
import FirebaseFirestore

struct TextMessage: Codable, Identifiable {
    @DocumentID var id: String?
    let coupleID: String
    let createdAt: Date
    let text: String
}

struct TestSong: Codable, Identifiable {
    @DocumentID var id: String?
    let name: String
    let singer: String
    let rate: Int
}

func fetchSongs() {
    let db = Firestore.firestore()
    db.collection("songs").getDocuments { snapshot, error in
            
         guard let snapshot else { return }
        
         let songs = snapshot.documents.compactMap { snapshot in
             try? snapshot.data(as: Song.self)
         }
         print(songs)
     }
}

struct LoadMessage: View {
    @FirestoreQuery(collectionPath: "messages") var messages: [TextMessage]
    @State private var firstMessage: TextMessage? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            Button("顯示第一則訊息") {
                firstMessage = messages.first
            }
            .buttonStyle(.borderedProminent)

            if let msg = firstMessage {
                VStack(alignment: .leading, spacing: 8) {
                    Text("coupleID: \(msg.coupleID)")
                    Text("createdAt: \(msg.createdAt)")
                    Text("text: \(msg.text)")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            } else {
                Text("尚未選取訊息")
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
    }
}

struct TestedMessage: View {
//    @FirestoreQuery(collectionPath: "songs") var songs: [Song]
    @FirestoreQuery(collectionPath: "messages", predicates: [.order(by:"createdAt", descending: true)]) var messages: [TextMessage]
    
    var body: some View {
        List {
            ForEach(messages) { message in
                HStack {
                    Text(message.coupleID)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(message.text)
                        Text(message.createdAt.description)
                    }
                }
            }
        }
//        List {
//            ForEach(songs) { song in
//                HStack {
//                    Text(song.name)
//                    Spacer()
//                    VStack(alignment: .trailing) {
//                        Text(song.singer)
//                        Text("\(song.rate)")
//                    }
//                }
//            }
//        }
    }
}

struct TestedSongs: View {
    @FirestoreQuery(collectionPath: "songs") var songs: [Song]
    //    @FirestoreQuery(collectionPath: "messages") var messages: [TextMessage]
    
    var body: some View {
        //        List {
        //            ForEach(messages) { message in
        //                HStack {
        //                    Text(message.coupleID)
        //                    Spacer()
        //                    VStack(alignment: .trailing) {
        //                        Text(message.text)
        //                        Text(message.createdAt.description)
        //                    }
        //                }
        //            }
        //        }
        List {
            ForEach(songs) { song in
                HStack {
                    Text(song.name)
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(song.singer)
                        Text("\(song.rate)")
                    }
                }
            }
        }
    }
}

//#Preview {
//    LoadMessage()
//}

#Preview {
    TestedMessage()
}

//#Preview {
//    TestedSongs()
//}
