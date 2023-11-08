import SwiftUI

@main
struct FlipTransitionSampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State var isFlipped = false
    var body: some View {
        FlipTransition(isFlipped: $isFlipped) {
            SampleFrontView(onTapFlipToBack: { isFlipped = true })
        } back: {
            SampleBackView(onTapFlipToFront: { isFlipped = false })
        }
        .ignoresSafeArea()
    }
}
