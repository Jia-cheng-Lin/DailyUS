//
//  TemplateUS.swift
//  DailyUS
//
//  Created by 林嘉誠 on 2025/12/2.
//

import SwiftUI

struct User: View {
    let characters = ["Bill", "Sandy", "Peter"]
    
    @State private var selectedCharacter = "Bill"
    
    var body: some View {
        VStack {
            Picker("選擇角色", selection: $selectedCharacter) {
                ForEach(characters, id: \.self)
                { Character in
                        Text(Character)
                }
            }
            Text("要是能重來，我要選\(selectedCharacter)")
        }
    }
}

#Preview {
    User()
}
