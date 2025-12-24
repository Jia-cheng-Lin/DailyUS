//
//  CourseListView.swift
//  Acknowledger
//
//  Created by Assistant on 2025/11/4.
//

import SwiftUI

struct CourseListView: View {
    let teacherName: String
    let notes: [Note]
    
    var body: some View {
        if notes.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("尚未建立課程清單")
                    .font(.headline)
                Text("之後可以在這裡放「\(teacherName)」的課程列表，點進去到 LectureView")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            List {
                ForEach(notes, id: \.id) { note in
                    NavigationLink {
                        LectureView(note: note)
                    } label: {
                        LectureRow(note: note)
                    }
                }
                // Circle()
                //     .frame(width: 100, height: 100)
            }
        }
    }
}
