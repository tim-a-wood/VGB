import SwiftUI

/// A full-screen confetti celebration shown when a game is marked as Completed.
struct CelebrationOverlay: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var showBanner = false

    private let colors: [Color] = [.green, .blue, .purple, .orange, .yellow, .pink, .mint, .indigo]

    var body: some View {
        ZStack {
            // Confetti particles
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .opacity(particle.opacity)
            }

            // Congratulations banner
            if showBanner {
                VStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.yellow)

                    Text("Game Completed!")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 20)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .transition(.scale.combined(with: .opacity))
            }
        }
        .ignoresSafeArea()
        .onAppear {
            spawnConfetti()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showBanner = true
            }
            // Fade out banner
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                withAnimation(.easeOut(duration: 0.5)) {
                    showBanner = false
                }
            }
        }
    }

    private func spawnConfetti() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        for i in 0..<40 {
            let startX = CGFloat.random(in: 0...screenWidth)
            let startY = CGFloat.random(in: -50...(-10))
            let endY = screenHeight + 50
            let size = CGFloat.random(in: 6...12)
            let color = colors.randomElement() ?? .green
            let delay = Double.random(in: 0...0.6)
            let duration = Double.random(in: 1.5...2.5)
            let drift = CGFloat.random(in: -60...60)

            let particle = ConfettiParticle(
                id: i,
                color: color,
                size: size,
                position: CGPoint(x: startX, y: startY),
                opacity: 1.0
            )
            particles.append(particle)

            // Animate falling
            withAnimation(.easeIn(duration: duration).delay(delay)) {
                if let idx = particles.firstIndex(where: { $0.id == i }) {
                    particles[idx].position = CGPoint(x: startX + drift, y: endY)
                    particles[idx].opacity = 0
                }
            }
        }
    }
}

private struct ConfettiParticle: Identifiable {
    let id: Int
    let color: Color
    let size: CGFloat
    var position: CGPoint
    var opacity: Double
}

#Preview {
    CelebrationOverlay()
}
