import SwiftUI

struct SampleBackView: View {
    private let onTapFlipToFront: () -> Void

    init(onTapFlipToFront: (() -> Void)? = nil) {
        if let onTapFlipToFront {
            self.onTapFlipToFront = onTapFlipToFront
        } else {
            self.onTapFlipToFront = {}
        }
    }

    var body: some View {
        TabView {
            NavigationView {
                VStack {
                    Text("Flip to Front")
                        .frame(maxWidth: 200, maxHeight: 200)
                        .background(.cyan)
                        .onTapGesture {
                            onTapFlipToFront()
                        }
                }
                .listStyle(.plain)
                .navigationTitle("Back Side")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
            }
            .tabItem {
                Label(title: { Text("Back Side") }, icon: { Image(systemName: "minus") })
            }
            .border(.green.opacity(0.5), width: 2)
        }
        .border(.red.opacity(0.5), width: 2)
    }
}

#Preview {
    SampleBackView()
}
