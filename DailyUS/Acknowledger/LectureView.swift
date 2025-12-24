//
//  LectureView.swift
//  Acknowledger
//
//  Created by 林嘉誠 on 2025/11/3.
//

import SwiftUI

struct LectureView: View {
    let note: Note
    
    var body: some View {
        ScrollView{
            VStack(alignment: .leading) {
                Text(note.subtitle)
                    .font(.title)
                note.image
                    .resizable()
                    .scaledToFit()
                Text(note.content)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .navigationTitle(note.title)
        }
    }
}

#Preview {
    NavigationStack {
        LectureView(
            note: Note(
                image: Image("E1"),
                title: "專業人才溝通術",
                subtitle:" Course 1: Course Introduction",
                speaker: "Lily",
                content: """
            ❓What is Professionalism?
            📖”The combination of all the qualities that are connected with trained and skilled people.” - 《Cambridge Dictionary》
            
            💡Core values of “Professionalism”
            🔴 Skill Competence
            🟠 Ethical Behavior
            🟡 Professional Appearance
            🟢 Communication Skills
            🔵 Teamwork
            🟣 Reliability
            🟤 Accountability
            
            ✔️Success for “professionalism”
            🤏5%: Academic credentials
            🤏15%: Professional experiences
            🔆80%: Communication skills
            
            💡課後心得
            每學期逼自己要上一堂英文課，這學期選了「專業人才溝通術」，是一堂三位老師和授的課程Lily, Freddy, Angela三位老師，分別帶領著”Elevator pitch”, “conference networking connection”, and “response to reviewers and editor”三個部分，都是我覺得很有幫助的部分，而且感覺課程的負擔不會太大，上課人數也不會太多，應該可以有很多互動，很期待這學期的課程~
            
            一開始讓我們想一個心中覺得「專業」的人，然後彼此分享為什麼覺得他專業的原因，然後從字典、核心價值、數據統計分析如何變的專業，帶入到溝通技巧的重要性，也切入到這學期的課程內容與重點，更期待能夠透過這樣一步步的學習變得更加專業的自己了~
            """
            )
        )
    }
}
