//
//  HomeList.swift
//  Acknowledger
//
//  Created by 林嘉誠 on 2025/11/5.
//

import SwiftUI

struct HomeList: View {
    let notes : [Note]
    
    var body: some View {
        NavigationStack {
//            List {
                ScrollView(.horizontal, showsIndicators: false){
                    HStack{
                        ForEach(notes, id: \.id) { note in
                            NavigationLink {
                                LectureView(note: note)
                            } label: {
                                Card(note: note)
                            }
                        }
                    }
                }
//            }
            .scrollContentBackground(.hidden) // 讓外層 Background 透出
            .background(Color.clear)
//            .navigationTitle("Course Information")
        }
    }
}

#Preview (traits: .sizeThatFitsLayout) {
    // 預覽用假資料
    let previewNotes: [Note] = [
        Note(
            image: Image("E1"),
            title: "專業人才溝通術",
            subtitle: "Course 1: Course Introduction",
            speaker: "Lily",
            content: """
            ❓What is Professionalism?
            📖”The combination of all the qualities that are connected with trained and skilled people.” - 《Cambridge Dictionary》
            """
        ),
        Note(
            image: Image("E2"),
            title: "專業人才溝通術",
            subtitle: "Course 2: Essential Soft Skills Towards Professionalism",
            speaker: "Lily",
            content: "lecture note week 2"
        ),
        Note(
            image: Image("E3-1"),
            title: "專業人才溝通術",
            subtitle: "Course 3: Build your networking before you need it!",
            speaker: "Lily",
            content: "Week 3"
        )
    ]
    
    NavigationStack {
        HomeList(notes: previewNotes)
    }
}
