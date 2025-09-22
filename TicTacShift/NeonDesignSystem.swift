import SwiftUI

struct NeonBackground: View {
    var animate: Bool
    @State private var glowShift = false
    @State private var ripple = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.03, blue: 0.12),
                    Color(red: 0.08, green: 0.10, blue: 0.26),
                    Color(red: 0.01, green: 0.25, blue: 0.35)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            if !reduceMotion {
                GeometryReader { _ in
                    Canvas { context, size in
                        let gradient = Gradient(colors: [
                            Color.neonMagenta.opacity(0.9),
                            Color.neonCyan.opacity(0.8),
                            Color.neonYellow.opacity(0.75)
                        ])

                        var path = Path()
                        path.addRoundedRect(in: CGRect(origin: .zero, size: size), cornerSize: CGSize(width: size.width * 0.4, height: size.height * 0.4))

                        context.addFilter(.blur(radius: 120))
                        context.draw(
                            .linearGradient(
                                LinearGradient(
                                    gradient: gradient,
                                    startPoint: CGPoint(x: 0, y: reduceMotion ? size.height * 0.25 : glowShift ? size.height * 0.7 : size.height * 0.3),
                                    endPoint: CGPoint(x: size.width, y: reduceMotion ? size.height * 0.75 : glowShift ? size.height * 0.2 : size.height * 0.9)
                                ),
                                start: CGPoint(x: -size.width * 0.3, y: -size.height * 0.2),
                                end: CGPoint(x: size.width * 1.3, y: size.height * 1.2)
                            ),
                            in: path
                        )
                    }
                }
                .ignoresSafeArea()
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 1.2)
                        .scaleEffect(ripple ? 1.6 : 1.1)
                        .blur(radius: 6)
                        .animation(.easeInOut(duration: 4.2).repeatForever(autoreverses: true), value: ripple)
                        .padding(-120)
                )
            }
        }
        .onChange(of: animate) { newValue in
            guard newValue, !reduceMotion else { return }
            glowShift = true
            ripple = true
        }
        .onAppear {
            guard animate, !reduceMotion else { return }
            glowShift = true
            ripple = true
        }
    }
}

struct NeonGlass<Content: View>: View {
    var cornerRadius: CGFloat = 28
    var strokeOpacity: Double = 0.25
    var shadowColor: Color = .white.opacity(0.25)
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(strokeOpacity), lineWidth: 1.2)
                    )
                    .shadow(color: shadowColor, radius: 24, y: 18)
            )
    }
}

struct NeonCapsule: View {
    let title: String
    let systemImage: String
    var colors: [Color] = [Color.neonCyan, Color.neonMagenta]

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
        }
        .foregroundColor(.white.opacity(0.9))
        .padding(.vertical, 8)
        .padding(.horizontal, 14)
        .background(
            LinearGradient(
                colors: colors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(Capsule())
        .shadow(color: colors.last?.opacity(0.5) ?? .black.opacity(0.4), radius: 10, y: 6)
    }
}

struct NeonButtonStyle: ButtonStyle {
    var gradient: LinearGradient
    var foreground: Color = .white
    var scale: CGFloat = 0.97

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(foreground)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(gradient)
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: foreground.opacity(0.25), radius: 18, y: 10)
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

extension Color {
    static let neonMagenta = Color(red: 0.84, green: 0.21, blue: 0.75)
    static let neonCyan = Color(red: 0.01, green: 0.82, blue: 0.89)
    static let neonYellow = Color(red: 0.97, green: 0.82, blue: 0.33)
    static let neonBlue = Color(red: 0.13, green: 0.41, blue: 0.94)
    static let neonBackground = Color(red: 0.03, green: 0.05, blue: 0.16)
}
