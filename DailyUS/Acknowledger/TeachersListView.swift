//
//  TeachersListView.swift
//  Acknowledger
//
//  Created by Assistant on 2025/11/4.
//

import SwiftUI

struct TeachersListView: View {
    // The course title to focus on
    let courseTitle: String
    // All notes (from which we’ll pick those belonging to the course)
    let notes: [Note]
    
    // Notes filtered to the selected course
    private var notesForCourse: [Note] {
        let key = courseTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return notes.filter { $0.title.trimmingCharacters(in: .whitespacesAndNewlines) == key }
    }
    
    // Within the course, group by speaker to make pages
    private var pages: [(speaker: String, notes: [Note])] {
        let grouped = Dictionary(grouping: notesForCourse, by: { $0.speaker.trimmingCharacters(in: .whitespacesAndNewlines) })
        return grouped
            .map { (key: String, value: [Note]) in
                // Optional: sort within a speaker by subtitle for nicer order
                let sortedNotes = value.sorted { $0.subtitle < $1.subtitle }
                return (speaker: key, notes: sortedNotes)
            }
            .sorted { $0.speaker < $1.speaker }
    }
    
    var body: some View {
        TabView {
            ForEach(Array(pages.enumerated()), id: \.offset) { _, page in
                CourseListView(
                    teacherName: page.speaker, // reuse to show speaker on page
                    notes: page.notes
                )
                .navigationTitle("\(courseTitle) - \(page.speaker)")
                .navigationBarTitleDisplayMode(.inline)
                .background(Color.clear)
            }
        }
        .tabViewStyle(.page)
        .indexViewStyle(.page(backgroundDisplayMode: .automatic))
        .navigationTitle(courseTitle) // outer title shows the course
    }
}
