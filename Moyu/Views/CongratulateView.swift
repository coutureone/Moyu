import SwiftUI
import AppKit

// MARK: - Congratulate View (恭喜页面)
struct CongratulateView: View {
    @EnvironmentObject var appState: AppState
    @State private var showConfetti = false
    @State private var isHovered = false
    
    var body: some View {
        ZStack {
            // 烟花效果
            if showConfetti {
                ConfettiView()
            }
            
            // 完成按钮
            Button(action: finishLearning) {
                Text(isHovered ? "回到首页 🎉" : "完成！")
                    .font(.system(size: 16))
                    .foregroundColor(Color(hex: "#3d5a80"))
                    .frame(width: isHovered ? 150 : 100, height: 35)
                    .background(Color.white)
                    .cornerRadius(5)
                    .shadow(color: .black.opacity(0.1), radius: 5, y: 5)
                    .animation(.easeInOut(duration: 0.3), value: isHovered)
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                isHovered = hovering
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
        }
        .onAppear {
            showConfetti = true
        }
    }
    
    private func finishLearning() {
        appState.reset()
    }
}

// MARK: - Confetti View (烟花效果)
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .opacity(particle.opacity)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                animateParticles()
            }
        }
    }
    
    private func createParticles(in size: CGSize) {
        particles = (0..<50).map { _ in
            ConfettiParticle(
                position: CGPoint(x: size.width / 2, y: size.height / 2),
                color: [Color.red, Color.orange, Color.yellow, Color.green, Color.blue, Color.purple].randomElement()!,
                size: CGFloat.random(in: 4...10),
                velocity: CGPoint(
                    x: CGFloat.random(in: -100...100),
                    y: CGFloat.random(in: -150...(-50))
                ),
                opacity: 1.0
            )
        }
    }
    
    private func animateParticles() {
        Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { timer in
            var allFaded = true
            
            for i in particles.indices {
                particles[i].position.x += particles[i].velocity.x * 0.016
                particles[i].position.y += particles[i].velocity.y * 0.016
                particles[i].velocity.y += 200 * 0.016 // 重力
                particles[i].opacity -= 0.02
                
                if particles[i].opacity > 0 {
                    allFaded = false
                }
            }
            
            if allFaded {
                timer.invalidate()
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    let color: Color
    let size: CGFloat
    var velocity: CGPoint
    var opacity: Double
}

#Preview {
    CongratulateView()
        .environmentObject(AppState.shared)
        .frame(width: 300, height: 150)
        .background(Color(hex: "#d7e1ec"))
}
