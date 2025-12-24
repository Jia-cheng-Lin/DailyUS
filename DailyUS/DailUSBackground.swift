import SwiftUI

struct Background: View {
    let image: Image

    var body: some View {
        image
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
    }
}

#Preview {
    Background(image: Image("Back_1"))
}
