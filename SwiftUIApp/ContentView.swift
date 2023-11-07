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
            SampleFrontView(onTapFlipToBack: {
                withAnimation {
                    isFlipped = true
                }
            })
            .transition(.opacity)
        } else {
            SampleBackView(onTapFlipToFront: {
                withAnimation {
                    isFlipped = false
                }
            })
            .transition(.opacity)
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
                .move(edge: .leading).combined(with: .opacity)
            )
        } else {
            SampleBackView(onTapFlipToFront: {
                withAnimation {
                    isFlipped = false
                }
            })
            .transition(
                .move(edge: .trailing).combined(with: .opacity)
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

    var body: some View {
        VStack {
            if isFlipped == false {
                SampleFrontView(onTapFlipToBack: {
                    withAnimation(.linear(duration: 1.0)) {
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
                    withAnimation(.linear(duration: 1.0)) {
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
        .background(.brown)
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

    private let backgroundColor = Color.black
    private let duration: TimeInterval = 0.6

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
                                active: FlipModifier(direction: .trailing, progress: 1.0),
                                identity: FlipModifier(direction: .trailing, progress: 0.0)
                            )
                        )
                }
                if isBackShowing {
                    SampleBackView(onTapFlipToFront: { isFlipped = false })
                        .transition(
                            .modifier(
                                active: FlipModifier(direction: .leading, progress: 1.0),
                                identity: FlipModifier(direction: .leading, progress: 0.0)
                            )
                        )
                }
            }
            .onChange(of: isFlipped) { (old, new) in
                withAnimation(.easeIn(duration: duration / 2.0), completionCriteria: .logicallyComplete) {
                    if new {
                        isFrontShowing = false
                    } else {
                        isBackShowing = false
                    }
                } completion: {
                    withAnimation(.easeOut(duration: duration / 2.0), completionCriteria: .logicallyComplete) {
                        if new {
                            isBackShowing = true
                        } else {
                            isFrontShowing = true
                        }
                    } completion: {
                        // nop
                    }
                }
            }

        }
    }
}

struct DelayedModifierTransitionView: View {

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
//                    .overlay(
//                        LinearGradient(colors: [.black.opacity(0.3), .clear], startPoint: direction.opposite, endPoint: direction.anchor)
//                            .opacity(progress)
//                            .allowsHitTesting(false)
//                    )
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

    var body: some View {
        ZStack {
            Color.brown
                .ignoresSafeArea()
                .allowsTightening(false)

            ZStack {
                if isFrontShowing {
                    SampleFrontView(onTapFlipToBack: {
                        isFlipped = true
                        withAnimation(.linear(duration: 0.5)) {
                            isFrontShowing = false
                        }
                        withAnimation(.linear(duration: 0.5).delay(0.5)) {
                            isBackShowing = true
                        }
                    })
                    .id("front")
                    .transition(
                        .asymmetric(
                            insertion:
                                    .modifier(active: FlipModifier(direction: .trailing, progress: 1.0), identity: FlipModifier(direction: .trailing, progress: 0.0))
                                    .animation(.linear(duration: 0.5).delay(0.5))
                            ,
                            removal:
                                    .modifier(active: FlipModifier(direction: .trailing, progress: 1.0), identity: FlipModifier(direction: .trailing, progress: 0.0))
                                    .animation(.linear(duration: 0.5).delay(0.0))
                        )
                    )
                }
                if isBackShowing {
                    SampleBackView(onTapFlipToFront: {
                        isFlipped = false
                        withAnimation(.linear(duration: 0.5)) {
                            isBackShowing = false
                        }
                        withAnimation(.linear(duration: 0.5).delay(0.5)) {
                            isFrontShowing = true
                        }
                    })
                    .id("back")
                    .transition(
                        .asymmetric(
                            insertion:
                                    .modifier(active: FlipModifier(direction: .leading, progress: 1.0), identity: FlipModifier(direction: .leading, progress: 0.0))
                                    .animation(.linear(duration: 0.5).delay(0.5))
                            ,
                            removal:
                                    .modifier(active: FlipModifier(direction: .leading, progress: 1.0), identity: FlipModifier(direction: .leading, progress: 0.0))
                                    .animation(.linear(duration: 0.5).delay(0.0))
                        )
                    )
                }
            }
        }
    }
}

#Preview("Delayed Modifier") {
    DelayedModifierTransitionView()
        .ignoresSafeArea()
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
