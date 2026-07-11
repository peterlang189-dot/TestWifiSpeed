import SwiftUI

struct SpeedometerView: View {
    @Environment(\.colorScheme) private var colorScheme
    let value: String
    let unit: String
    let caption: String
    let progress: Double
    let isRunning: Bool

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let lineWidth = max(14, size * 0.055)

            ZStack {
                GaugeTicks(progress: progress)
                    .frame(width: size * 0.92, height: size * 0.92)

                GaugeArc(progress: 1)
                    .stroke(AppTheme.gaugeTrack(for: colorScheme), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                    .frame(width: size * 0.82, height: size * 0.82)

                GaugeArc(progress: progress)
                    .stroke(
                        AngularGradient(
                            colors: [.cyan, .green, .yellow, .orange, .pink],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                    )
                    .frame(width: size * 0.82, height: size * 0.82)
                    .shadow(color: .cyan.opacity(isRunning ? 0.46 : 0.22), radius: isRunning ? 18 : 8)

                VStack(spacing: 8) {
                    Text(value)
                        .font(.system(size: min(72, size * 0.23), weight: .black, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Text(unit)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(caption)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                        .padding(.horizontal, 18)
                }
                .frame(width: size * 0.64)
                .offset(y: size * 0.04)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.spring(response: 0.7, dampingFraction: 0.82), value: progress)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(value) \(unit)")
        .accessibilityValue(caption)
    }
}

struct GaugeTicks: View {
    @Environment(\.colorScheme) private var colorScheme
    let progress: Double
    private let tickCount = 43

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let radius = size * 0.44
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)

            ZStack {
                ForEach(0..<tickCount, id: \.self) { index in
                    let fraction = Double(index) / Double(tickCount - 1)
                    let angle = Angle.degrees(140 + 260 * fraction)
                    let isMajor = index % 7 == 0
                    let lit = fraction <= progress

                    Capsule()
                        .fill(AppTheme.gaugeTick(isLit: lit, colorScheme: colorScheme))
                        .frame(width: isMajor ? 3 : 2, height: isMajor ? 18 : 10)
                        .position(
                            x: center.x + cos(angle.radians) * radius,
                            y: center.y + sin(angle.radians) * radius
                        )
                        .rotationEffect(angle + .degrees(90))
                }
            }
        }
    }
}

struct GaugeArc: Shape {
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let clampedProgress = min(max(progress, 0), 1)
        let start = Angle.degrees(140)
        let end = Angle.degrees(140 + 260 * clampedProgress)
        let radius = min(rect.width, rect.height) / 2
        let center = CGPoint(x: rect.midX, y: rect.midY)

        path.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: false)
        return path
    }
}
