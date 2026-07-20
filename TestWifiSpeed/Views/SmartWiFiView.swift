import SwiftUI

struct SmartWiFiView: View {
    let language: AppLanguage

    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("hasAcknowledgedSpeedTestDisclosure") private var hasAcknowledgedSpeedTestDisclosure = false
    @StateObject private var advisor: SmartWiFiAdvisor
    @StateObject private var networkMonitor = NetworkMonitor()
    @State private var showingSpeedTestDisclosure = false
    @State private var pendingStartRequirement: SpeedTestStartRequirement = .disclosure

    init(language: AppLanguage, runGate: SpeedTestRunGate) {
        self.language = language
        _advisor = StateObject(wrappedValue: SmartWiFiAdvisor(runGate: runGate))
    }

    var body: some View {
        ZStack {
            SmartWiFiBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    hero
                    networkNotice
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
        .toolbarColorScheme(colorScheme, for: .navigationBar)
        .alert(
            speedTestDisclosureTitle,
            isPresented: $showingSpeedTestDisclosure
        ) {
            Button(L10n.text("speedtest.disclosure.continue", language: language)) {
                hasAcknowledgedSpeedTestDisclosure = true
                advisor.start()
            }
            Button(L10n.text("action.cancel", language: language), role: .cancel) {}
        } message: {
            Text(speedTestDisclosureMessage)
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(L10n.text("smart.badge", language: language), systemImage: "wifi.router.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.cyan)
            Text(L10n.text("smart.hero.title", language: language))
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.74)
            Text(L10n.text("smart.hero.body", language: language))
                .font(.subheadline)
                .foregroundStyle(.secondary)
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
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.75)
                Text(display.detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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
                .stroke(AppTheme.border(for: colorScheme), lineWidth: 1)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(advisor.statusText(language: language))
    }

    @ViewBuilder
    private var networkNotice: some View {
        if !networkMonitor.isConnected {
            Label(L10n.text("network.offline", language: language), systemImage: "wifi.slash")
                .foregroundStyle(.orange)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.orange.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))
        } else if networkMonitor.connectionType == .cellular {
            Label(L10n.text("network.cellular.warning", language: language), systemImage: "antenna.radiowaves.left.and.right")
                .foregroundStyle(.orange)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.orange.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))
        }
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
                    title: L10n.text("metric.upload", language: language),
                    value: result.uploadMbps.formatted(.number.precision(.fractionLength(1))),
                    unit: L10n.text("unit.mbps", language: language),
                    icon: "arrow.up.circle.fill",
                    color: .green
                )
                MetricCard(
                    title: L10n.text("metric.latency", language: language),
                    value: result.latencyMs.formatted(.number.precision(.fractionLength(0))),
                    unit: L10n.text("unit.ms", language: language),
                    icon: "timer",
                    color: .orange
                )
                MetricCard(
                    title: L10n.text("metric.jitter", language: language),
                    value: result.jitterMs.formatted(.number.precision(.fractionLength(0))),
                    unit: L10n.text("unit.ms", language: language),
                    icon: "waveform.path.ecg",
                    color: .pink
                )
            }
        }
    }

    private var actionPanel: some View {
        VStack(spacing: 12) {
            Button {
                advisor.isRunning ? advisor.cancel() : requestSpeedTestStart()
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
            .disabled(!networkMonitor.isConnected && !advisor.isRunning)
            .opacity(!networkMonitor.isConnected && !advisor.isRunning ? 0.55 : 1)
            .accessibilityLabel(advisor.isRunning ? L10n.text("action.cancel", language: language) : L10n.text("smart.action.optimize", language: language))

            Label {
                Text(L10n.text("smart.system.note", language: language))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.cyan)
            }
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(AppTheme.subtleFill(for: colorScheme), in: RoundedRectangle(cornerRadius: 8))
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

    private var speedTestDisclosureTitle: String {
        let key = pendingStartRequirement == .cellularDisclosure
            ? "speedtest.cellular.title"
            : "speedtest.disclosure.title"
        return L10n.text(key, language: language)
    }

    private var speedTestDisclosureMessage: String {
        let key = pendingStartRequirement == .cellularDisclosure
            ? "speedtest.cellular.message"
            : "speedtest.disclosure.message"
        return L10n.text(key, language: language)
    }

    private func requestSpeedTestStart() {
        let requirement = SpeedTestStartPolicy.requirement(
            isNetworkAvailable: networkMonitor.isConnected,
            connectionType: networkMonitor.connectionType,
            hasAcknowledgedDisclosure: hasAcknowledgedSpeedTestDisclosure
        )

        switch requirement {
        case .allowed:
            advisor.start()
        case .disclosure, .cellularDisclosure:
            pendingStartRequirement = requirement
            showingSpeedTestDisclosure = true
        case .offline:
            break
        }
    }
}

// MARK: - Smart Wi-Fi Shared Backgrounds

struct SmartWiFiBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            AppTheme.pageBackground(for: colorScheme)
            LinearGradient(
                colors: [
                    Color.green.opacity(colorScheme == .dark ? 0.24 : 0.13),
                    Color.cyan.opacity(colorScheme == .dark ? 0.18 : 0.10),
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
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        AppTheme.panelBackground(for: colorScheme)
    }
}
