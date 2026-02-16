import SwiftUI

struct AnimatedSectionBackground: View {
    let accent: Color
    var baseTop: Color = .white
    var baseBottom: Color = Color(.systemGray6)
    var duration: Double = 14

    @State private var animate = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [baseTop, baseBottom],
                startPoint: animate ? .topLeading : .bottomLeading,
                endPoint: animate ? .bottomTrailing : .topTrailing
            )
            RadialGradient(
                colors: [accent.opacity(0.28), Color.clear],
                center: animate ? .topLeading : .bottomTrailing,
                startRadius: 20,
                endRadius: 420
            )
            RadialGradient(
                colors: [accent.opacity(0.38), Color.clear],
                center: animate ? .bottomTrailing : .topLeading,
                startRadius: 20,
                endRadius: 520
            )
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}

