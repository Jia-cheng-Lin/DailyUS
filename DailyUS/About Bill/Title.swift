//
//  Title.swift
//  AboutMe
//
//  Created by 林嘉誠 on 2025/9/26.
//

import Foundation
import SwiftUI

struct Title: View{
    var body: some View {
        Text(
            """
            Hello, I'm
            Jia-Cheng Lin~
            """
        )
        .font(.custom("Nagurigaki-Crayon", size: 40))
        .multilineTextAlignment(.leading)
        .lineSpacing(10)
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .topLeading
        )
    }
}
 

#Preview {
    Title()
}
