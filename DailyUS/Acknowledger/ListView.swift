//
//  List.swift
//  Acknowledger
//
//  Created by 林嘉誠 on 2025/11/5.
//

import SwiftUI

struct ListView: View {
    
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Lecture") {
                    List {
                        NavigationLink("學術英文論文與寫作") {
                            TeachersListView(courseTitle: "學術英文論文與寫作", notes: lectures1)
                                .navigationTitle("學術英文論文與寫作")
                        }
                        
                        NavigationLink("專業人才溝通術") {
                            // 導向精簡的老師清單頁（避免多層 List 巢狀）
                            TeachersListView(courseTitle:"專業人才溝通術",notes: lectures1)
                                .navigationTitle("專業人才溝通術")
                        }
                    }
                    .navigationTitle("Lecture note")
                }
                
                NavigationLink("Speech") {
                    List {
                        NavigationLink("專題討論") {
                            TeachersListView(courseTitle: "專題討論", notes: speeches)
                                .navigationTitle("專題討論")
                        }
                        
                        NavigationLink("專題演講") {
                            TeachersListView(courseTitle: "專題演講", notes: speeches)
                            .navigationTitle("專題演講")
                        }
                    }
                    .navigationTitle("Speech sharing")
                }
                NavigationLink("AI tool") {
                    TeachersListView(courseTitle: "AI Tools Sharing", notes: ai)
                        .navigationTitle("AI Tools Sharing")
                }
                NavigationLink("Event") {
                    TeachersListView(courseTitle: "其他活動", notes: others)
                        .navigationTitle("Event")
                }
            }
            .navigationTitle("Acknowledger")
        }
    }
}

#Preview {
    ListView()
}
