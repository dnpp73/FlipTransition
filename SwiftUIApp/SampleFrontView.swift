import SwiftUI

struct SampleFrontView: View {
    let onTapFlipToBack: () -> Void

    init(onTapFlipToBack: (() -> Void)? = nil) {
        if let onTapFlipToBack {
            self.onTapFlipToBack = onTapFlipToBack
        } else {
            self.onTapFlipToBack = {}
        }
    }

    var body: some View {
        TabView {
            NavigationStack {
                List {
                    Text("Flip to Back")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onTapGesture {
                            onTapFlipToBack()
                        }
                }
                .listStyle(.insetGrouped)
                .navigationTitle("Front Side")
                .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label(title: { Text("Front Side") }, icon: { Image(systemName: "plus") })
            }
            .border(.green.opacity(0.5), width: 2)
        }
        .border(.red.opacity(0.5), width: 2)
    }
}

#Preview {
    SampleFrontView()
}
