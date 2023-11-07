import SwiftUI

struct ContentView: View {
    var body: some View {
        CustomModifierTwoStepsTransitionView()
            .ignoresSafeArea()
    }
}

struct ConditionalSwitchView: View {
    @State private var isFlipped = false
    var body: some View {
        if isFlipped == false {
            SampleFrontView(onTapFlipToBack: { isFlipped = true })
        } else {
            SampleBackView(onTapFlipToFront: { isFlipped = false })
        }
    }
}

struct ZStackOpacityToggleView: View {
    @State private var isFlipped = false
    var body: some View {
        ZStack {
            SampleFrontView(onTapFlipToBack: { isFlipped = true })
                .opacity(isFlipped ? 0.0 : 1.0)

            SampleBackView(onTapFlipToFront: { isFlipped = false })
                .opacity(isFlipped ? 1.0 : 0.0)
        }
    }
}

struct BasicOpacityTransitionView: View {
    @State private var isFlipped = false
    var body: some View {
        if isFlipped == false {
            SampleFrontView(onTapFlipToBack: { isFlipped = true })
            .transition(
                .opacity
                    .animation(.default)
            )
        } else {
            SampleBackView(onTapFlipToFront: { isFlipped = false })
            .transition(
                .opacity
                    .animation(.default)
            )
        }
    }
}

struct CombinedTransitionView: View {
    @State private var isFlipped = false
    var body: some View {
        if isFlipped == false {
            SampleFrontView(onTapFlipToBack: {
                withAnimation {
                    isFlipped = true
                }
            })
            .transition(
                .move(edge: .leading)
                .combined(with: .opacity)
            )
        } else {
            SampleBackView(onTapFlipToFront: {
                withAnimation {
                    isFlipped = false
                }
            })
            .transition(
                .move(edge: .trailing)
                .combined(with: .opacity)
            )
        }
    }
}

struct CustomModifierTransitionView: View {
    private struct FlipModifier: ViewModifier {
        let degrees: Double
        let anchor: UnitPoint
        func body(content: Content) -> some View {
            content
                .rotation3DEffect(
                    .degrees(degrees),
                    axis: (0.0, 1.0, 0.0),
                    anchor: anchor,
                    anchorZ: 1.0,
                    perspective: 1.0
                )
        }
    }

    @State private var isFlipped = false

    private let backgroundColor = Color.gray
    private let duration: TimeInterval = 1.0

    var body: some View {
        VStack {
            if isFlipped == false {
                SampleFrontView(onTapFlipToBack: {
                    withAnimation(.linear(duration: duration)) {
                        isFlipped = true
                    }
                })
                .transition(
                    .modifier(active: FlipModifier(degrees: -180, anchor: .trailing), identity: FlipModifier(degrees: 0, anchor: .trailing))
                    .combined(with: .move(edge: .leading))
                    .combined(with: .opacity)
                )
            } else {
                SampleBackView(onTapFlipToFront: {
                    withAnimation(.linear(duration: duration)) {
                        isFlipped = false
                    }
                })
                .transition(
                    .modifier(active: FlipModifier(degrees: 180, anchor: .leading), identity: FlipModifier(degrees: 0, anchor: .leading))
                    .combined(with: .move(edge: .trailing))
                    .combined(with: .opacity)
                )
            }
        }
        .background(backgroundColor)
    }
}

struct CustomModifierTwoStepsTransitionView: View {

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

    @State private var isFlipped = false

    @State private var isFrontShowing = true
    @State private var isBackShowing = false

    private let backgroundColor = Color.gray
    private let duration: TimeInterval = 1.0

    var body: some View {
        ZStack { // 一瞬両方の View が無くなって空になるタイミングが存在するため、背景の View を指定する場合はもう一段階更に外側に ZStack が必要
            backgroundColor
                .ignoresSafeArea()
                .allowsTightening(false)

            VStack {
                if isFrontShowing {
                    SampleFrontView(onTapFlipToBack: { isFlipped = true })
                        .transition(
                            .modifier(
                                active:   FlipModifier(direction: .trailing, progress: 1.0),
                                identity: FlipModifier(direction: .trailing, progress: 0.0)
                            )
                        )
                }
                if isBackShowing {
                    SampleBackView(onTapFlipToFront: { isFlipped = false })
                        .transition(
                            .modifier(
                                active:   FlipModifier(direction: .leading, progress: 1.0),
                                identity: FlipModifier(direction: .leading, progress: 0.0)
                            )
                        )
                }
            }
            .onChange(of: isFlipped) { new in
                Task {
                    withAnimation(.linear(duration: duration / 2.0)) {
                        if new {
                            isFrontShowing = false
                        } else {
                            isBackShowing = false
                        }
                    }

                    try await Task.sleep(nanoseconds: UInt64(duration / 2.0 * Double(1000_000_000)))

                    withAnimation(.linear(duration: duration / 2.0)) {
                        if new {
                            isBackShowing = true
                        } else {
                            isFrontShowing = true
                        }
                    }

                    try await Task.sleep(nanoseconds: UInt64(duration / 2.0 * Double(1000_000_000)))

                    // finish here
                }
            }
        }
    }
}

struct CustomModifierDelayedTransitionView: View {

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

    @State private var isFlipped = false

    @State private var isFrontShowing = true
    @State private var isBackShowing = false

    private let backgroundColor = Color.gray
    private let duration: TimeInterval = 1.0

    private let frontTransition = AnyTransition.modifier(active: FlipModifier(direction: .trailing, progress: 1.0), identity: FlipModifier(direction: .trailing, progress: 0.0))
    private let backTransition  = AnyTransition.modifier(active: FlipModifier(direction: .leading, progress: 1.0), identity: FlipModifier(direction: .leading, progress: 0.0))

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
                .allowsTightening(false)

            ZStack {
                if isFrontShowing {
                    SampleFrontView(onTapFlipToBack: {
                        isFlipped = true
                    })
                    // .id("front")
                    .transition(
                        .asymmetric(
                            insertion: frontTransition.animation(.linear(duration: duration / 2.0).delay(duration / 2.0)),
                            removal:   frontTransition.animation(.linear(duration: duration / 2.0).delay(0.0))
                        )
                    )
                }
                if isBackShowing {
                    SampleBackView(onTapFlipToFront: {
                        isFlipped = false
                    })
                    // .id("back")
                    .transition(
                        .asymmetric(
                            insertion: backTransition.animation(.linear(duration: duration / 2.0).delay(duration / 2.0)),
                            removal:   backTransition.animation(.linear(duration: duration / 2.0).delay(0.0))
                        )
                    )
                }
            }
            .onChange(of: isFlipped) { new in
                if new {
                    withAnimation(.linear(duration: duration / 2.0)) {
                        isFrontShowing = false
                    }
                    withAnimation(.linear(duration: duration / 2.0).delay(duration / 2.0)) {
                        isBackShowing = true
                    }
                } else {
                    withAnimation(.linear(duration: duration / 2.0)) {
                        isBackShowing = false
                    }
                    withAnimation(.linear(duration: duration / 2.0).delay(duration / 2.0)) {
                        isFrontShowing = true
                    }
                }
            }
        }
    }
}

#Preview("Conditional Switch") {
    ConditionalSwitchView()
        .ignoresSafeArea()
}

#Preview("ZStack Opacity Toggle") {
    ZStackOpacityToggleView()
        .ignoresSafeArea()
}

#Preview("Basic Opacity Transition") {
    BasicOpacityTransitionView()
        .ignoresSafeArea()
}

#Preview("Combined Transition") {
    CombinedTransitionView()
        .ignoresSafeArea()
}

#Preview("CustomModifier Flip") {
    CustomModifierTransitionView()
        .ignoresSafeArea()
}

#Preview("Two Steps Flip") {
    CustomModifierTwoStepsTransitionView()
        .ignoresSafeArea()
}

#Preview("Delayed Flip") {
    CustomModifierDelayedTransitionView()
        .ignoresSafeArea()
}
