import SwiftUI

struct TilesBackground: View {
    var body: some View {
        GeometryReader { geometry in
            Image("back")
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
        }
        .background(Color.black)
        .ignoresSafeArea()
    }
}
