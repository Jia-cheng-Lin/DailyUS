//
//  Note.swift
//  Acknowledger
//
//  Created by 林嘉誠 on 2025/11/4.
//

import SwiftUI

struct Note: Identifiable {
    let id = UUID()
    let image: Image
    let title: String
    let subtitle: String
    let speaker: String
    let content: String
}
