import SwiftUI
import CoreMotion

struct ParallaxMotionModifier: ViewModifier {
    let manager = CMMotionManager()
    var amount: CGFloat

    @State private var x: CGFloat = 0
    @State private var y: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(x: x, y: y)
            .onAppear {
                manager.startDeviceMotionUpdates(to: .main) { motion, _ in
                    guard let m = motion else { return }

                    withAnimation(.easeOut(duration: 0.2)) {
                        x = CGFloat(m.gravity.x) * amount
                        y = CGFloat(m.gravity.y) * amount
                    }
                }
            }
    }
}

#Preview {
    Text("Parallax Preview")
        .padding()
        .modifier(ParallaxMotionModifier(amount: 12))
}
