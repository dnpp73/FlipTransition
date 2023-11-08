import SwiftUI

struct FlipTransition<FrontContent, BackContent>: View where FrontContent: View, BackContent: View {

    @Binding var isFlipped: Bool // = false

    init(isFlipped: Binding<Bool>, backgroundColor: Color? = nil, duration: TimeInterval? = nil, @ViewBuilder front: @escaping () -> FrontContent, @ViewBuilder back: @escaping () -> BackContent) {
        self._isFlipped = isFlipped
        if let backgroundColor {
            self.backgroundColor = backgroundColor
        } else {
            self.backgroundColor = .black
        }
        if let duration {
            self.duration = duration
        } else {
            self.duration = 0.6
        }
        self._isFrontShowing = State(wrappedValue: !isFlipped.wrappedValue)
        self._isBackShowing = State(wrappedValue: isFlipped.wrappedValue)
        self._zindexFront = State(wrappedValue: !isFlipped.wrappedValue ? 1.0 : 0.0)
        self._zindexBack = State(wrappedValue: !isFlipped.wrappedValue ? 0.0 : 1.0)
        self.front = front
        self.back = back
    }

    private let backgroundColor: Color // = Color.black
    private let duration: TimeInterval // = 0.6

    @State private var isFrontShowing: Bool // = true
    @State private var isBackShowing: Bool // = false

    @State private var zindexFront: Double // = 1.0
    @State private var zindexBack: Double // = 0.0

    private let front: () -> FrontContent
    private let back: () -> BackContent

    @State private var allowsTighteningContent = true

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
                .allowsTightening(false)

            ZStack {
                if isFrontShowing {
                    front()
                        .allowsTightening(allowsTighteningContent)
                        .zIndex(zindexFront)
                        .transition(.flipFront)
                }
                if isBackShowing {
                    back()
                        .allowsTightening(allowsTighteningContent)
                        .zIndex(zindexBack)
                        .transition(.flipBack)
                }
            }
            .onChange(of: isFlipped) { new in
                allowsTighteningContent = false
                let p1x: Double = 0.15
                let p1y: Double = 0.0
                let p2xy: Double = 0.7
                let p3xy: Double = 1.0 - p2xy
                let p4x: Double = 1.0 - p1x
                let p4y: Double = 1.0 - p1y
                withAnimation(.timingCurve(p1x, p1y, p2xy, p2xy, duration: duration / 2.0)) {
                    if new {
                        isFrontShowing = false
                    } else {
                        isBackShowing = false
                    }
                }
                withAnimation(.timingCurve(p3xy, p3xy, p4x, p4y, duration: duration / 2.0).delay(duration / 2.0)) {
                    if new {
                        isBackShowing = true
                    } else {
                        isFrontShowing = true
                    }
                }
                Task {
                    try await Task.sleep(nanoseconds: UInt64(duration * Double(1000_000_000)))
                    if new {
                        zindexFront = 0.0
                        zindexBack  = 1.0
                    } else {
                        zindexFront = 1.0
                        zindexBack  = 0.0
                    }
                    allowsTighteningContent = true
                }
            }
        }
    }
}

// MARK: -

private enum FlipDirection {
    case trailing
    case leading

    var anchor: UnitPoint {
        switch self {
        case .trailing: .trailing
        case .leading: .leading
        }
    }

    var opposite: UnitPoint {
        switch self {
        case .trailing: .leading
        case .leading: .trailing
        }
    }

    func degrees(progress: Double) -> Angle {
        if progress == 0.0 {
            return .zero
        }
        switch self {
        case .trailing: return .degrees(-90)
        case .leading: return .degrees(90)
        }
    }

    func offset(for width: Double, progress: Double) -> Double {
        switch self {
        case .trailing: width * progress * -0.5
        case .leading: width * progress * 0.5
        }
    }
}

private struct FlipModifier: ViewModifier {
    let direction: FlipDirection
    let progress: Double

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .overlay(
                    LinearGradient(colors: [.black.opacity(0.3), .clear], startPoint: direction.opposite, endPoint: direction.anchor)
                        .opacity(progress)
                        .allowsHitTesting(false)
                )
                .rotation3DEffect(
                    direction.degrees(progress: progress),
                    axis: (0.0, 1.0, 0.0),
                    anchor: direction.anchor,
                    anchorZ: 1.0,
                    perspective: 1.0
                )
                .offset(x: direction.offset(for: geometry.size.width, progress: progress))
        }
    }
}

// MARK: -

extension AnyTransition {
    fileprivate static let flipFront = AnyTransition.modifier(active: FlipModifier(direction: .trailing, progress: 1.0), identity: FlipModifier(direction: .trailing, progress: 0.0))
    fileprivate static let flipBack  = AnyTransition.modifier(active: FlipModifier(direction: .leading,  progress: 1.0), identity: FlipModifier(direction: .leading,  progress: 0.0))
}

#Preview {
    struct FlipPreview: View {
        @State var isFlipped = true
        var body: some View {
            FlipTransition(isFlipped: $isFlipped, backgroundColor: .gray, duration: 1.0, front: {
                SampleFrontView(onTapFlipToBack: { isFlipped = true })
            }, back: {
                SampleBackView(onTapFlipToFront: { isFlipped = false })
            })
            .ignoresSafeArea()
        }
    }
    return FlipPreview()
}
