//
//  template.swift
//  AboutMe
//
//  Created by 林嘉誠 on 2025/9/26.
//

import Foundation
import SwiftUI

struct Bottom: View{
    var body: some View {
        Text("也可以叫我Bill")
            .font(.custom("Nagurigaki-Crayon", size: 30))
            .multilineTextAlignment(.center)
            .lineSpacing(10)
            .shadow(color: .orange, radius: 4)
            .textCase(.uppercase)
            .padding([.trailing, .bottom], 24)  // 右、下各縮 24pt
          
    }
}
 

#Preview {
    Bottom()
}
