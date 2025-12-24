//
//  LectureRow.swift
//  Acknowledger
//
//  Created by 林嘉誠 on 2025/11/5.
//

import SwiftUI

struct LectureRow: View {
    let note: Note
    
    var body: some View {
        HStack {
            note.image
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipShape(.rect)
            Text(note.subtitle)
                .foregroundStyle(.orange)
                .font(.headline)
            Spacer()
        }
    }
}

#Preview (traits: .sizeThatFitsLayout) {
    NavigationStack {
        LectureRow(
            note: Note(
                image: Image("E1"),
                title: "專業人才溝通術",
                subtitle:" Course 1: Course Introduction",
                speaker: "Lily",
                content: """
            not important
            """
            )
        )
    }
}
