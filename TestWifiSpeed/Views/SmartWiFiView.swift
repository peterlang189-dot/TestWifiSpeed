import SwiftUI

struct SmartWiFiView: View {
    let language: AppLanguage

    @StateObject private var advisor = SmartWiFiAdvisor()
    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack {
            SmartWiFiBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    hero
                    recommendationPanel
                    metricsPanel
                    actionPanel
                }
                .padding(.horizontal, 18)
                .padding(.top, 14)
                .padding(.bottom, 28)
            }
        }
        .navigationTitle(L10n.text("smart.title", language: language))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(L10n.text("smart.badge", language: language), systemImage: "wifi.router.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.cyan)
            Text(L10n.text("smart.hero.title", language: language))
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.74)
            Text(L10n.text("smart.hero.body", language: language))
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.64))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var recommendationPanel: some View {
        let display = displayState

        return VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(display.color.opacity(0.16))
                    .frame(width: 126, height: 126)
                Circle()
                    .stroke(display.color.opacity(0.42), lineWidth: 10)
                    .frame(width: 126, height: 126)
                Image(systemName: display.icon)
                    .font(.system(size: 42, weight: .bold))
                    .foregroundStyle(display.color)
            }
            .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text(advisor.statusText(language: language))
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                Text(display.detail)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.66))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            ProgressView(value: advisor.progressValue())
                .tint(display.color)
                .accessibilityLabel("Progress")
                .accessibilityValue("\(Int(advisor.progressValue() * 100))%")
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background {
            SmartPanelBackground()
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(advisor.statusText(language: language))
    }

    @ViewBuilder
    private var metricsPanel: some View {
        if case .completed(let result, _) = advisor.state {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                MetricCard(
                    title: L10n.text("metric.download", language: language),
                    value: result.downloadMbps.formatted(.number.precision(.fractionLength(1))),
                    unit: L10n.text("unit.mbps", language: language),
                    icon: "arrow.down.circle.fill",
                    color: .cyan
                )
                MetricCard(
                    title: L10n.text("metric.latency", language: language),
                    value: result.latencyMs.formatted(.number.precision(.fractionLength(0))),
                    unit: L10n.text("unit.ms", language: language),
                    icon: "timer",
                    color: .orange
                )
            }
        }
    }

    private var actionPanel: some View {
        VStack(spacing: 12) {
            Button {
                advisor.isRunning ? advisor.cancel() : advisor.start()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: advisor.isRunning ? "xmark" : "wand.and.stars")
                    Text(advisor.isRunning ? L10n.text("action.cancel", language: language) : L10n.text("smart.action.optimize", language: language))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(actionGradient, in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(advisor.isRunning ? L10n.text("action.cancel", language: language) : L10n.text("smart.action.optimize", language: language))

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            } label: {
                Label(L10n.text("smart.action.settings", language: language), systemImage: "gearshape.fill")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(.white.opacity(0.12), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.text("smart.action.settings", language: language))

            Text(L10n.text("smart.system.note", language: language))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.54))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background {
            SmartPanelBackground()
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private var displayState: (icon: String, color: Color, detail: String) {
        switch advisor.state {
        case .idle:
            return ("sparkles", .cyan, L10n.text("smart.idle.detail", language: language))
        case .running:
            return ("antenna.radiowaves.left.and.right", .orange, L10n.text("smart.running.detail", language: language))
        case .completed(_, let recommendation):
            return (recommendation.icon, recommendation.color, recommendation.detail(language: language))
        case .failed:
            return ("exclamationmark.triangle.fill", .red, L10n.text("error.generic", language: language))
        }
    }

    private var actionGradient: LinearGradient {
        LinearGradient(
            colors: advisor.isRunning
                ? [Color.red, Color.orange]
                : [Color.green, Color.cyan],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Smart Wi-Fi Shared Backgrounds

struct SmartWiFiBackground: View {
    var body: some View {
        ZStack {
            Color(red: 0.035, green: 0.045, blue: 0.07)
            LinearGradient(
                colors: [
                    Color.green.opacity(0.24),
                    Color.cyan.opacity(0.18),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }
}

struct SmartPanelBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color.white.opacity(0.13),
                Color.white.opacity(0.055)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
