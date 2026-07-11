import SwiftUI
import UIKit

struct ContentView: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appLanguage") private var languageCode = AppLanguage.english.rawValue
    @AppStorage("appearanceMode") private var appearanceCode = AppearanceMode.system.rawValue
    @StateObject private var viewModel = SpeedTestViewModel()
    @State private var showingSettings = false
    @State private var showingClearHistoryConfirmation = false

    private var language: AppLanguage {
        AppLanguage(rawValue: languageCode) ?? .english
    }

    var body: some View {
        NavigationStack {
            ZStack {
                background

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        header
                        speedometerPanel
                        networkWarning
                        smartWiFiEntry
                        metricGrid
                        history
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 14)
                    .padding(.bottom, 28)
                }
            }
            .navigationTitle(L10n.text("app.title", language: language))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(colorScheme, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.headline)
                    }
                    .tint(.primary)
                    .accessibilityLabel(L10n.text("action.settings", language: language))
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(
                    languageCode: $languageCode,
                    appearanceCode: $appearanceCode,
                    language: language
                )
                .presentationDetents([.medium, .large])
            }
            .confirmationDialog(
                L10n.text("history.clear.confirm.title", language: language),
                isPresented: $showingClearHistoryConfirmation,
                titleVisibility: .visible
            ) {
                Button(L10n.text("history.clear", language: language), role: .destructive) {
                    viewModel.clearHistory()
                }
                Button(L10n.text("action.cancel", language: language), role: .cancel) {}
            } message: {
                Text(L10n.text("history.clear.confirm.message", language: language))
            }
        }
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            AppTheme.pageBackground(for: colorScheme)

            LinearGradient(
                colors: [
                    Color(red: 0.0, green: 0.64, blue: 0.78).opacity(colorScheme == .dark ? 0.30 : 0.15),
                    Color(red: 0.56, green: 0.20, blue: 0.76).opacity(colorScheme == .dark ? 0.16 : 0.08),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [
                    Color.clear,
                    Color(red: 0.93, green: 0.45, blue: 0.18).opacity(colorScheme == .dark ? 0.10 : 0.055)
                ],
                startPoint: .center,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Label(viewModel.statusTitle(language: language), systemImage: statusIcon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(statusColor)
                Text(L10n.text("app.title", language: language))
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
            }

            Spacer()

            GradeBadge(result: viewModel.primaryResult(), language: language)
        }
    }

    // MARK: - Speedometer Panel

    private var speedometerPanel: some View {
        let result = viewModel.primaryResult()
        let speedValue = result?.downloadMbps
        let displayValue = speedValue?.formatted(.number.precision(.fractionLength(1))) ?? "--"
        let speedFraction = min(max((speedValue ?? 0) / SpeedTestThreshold.speedometerMaxMbps, 0), 1)
        let progress = viewModel.isRunning ? viewModel.progressValue() : speedFraction

        return VStack(spacing: 16) {
            SpeedometerView(
                value: displayValue,
                unit: L10n.text("unit.mbps", language: language),
                caption: viewModel.progressMessage(language: language),
                progress: progress,
                isRunning: viewModel.isRunning
            )
            .frame(height: 292)

            Button {
                viewModel.isRunning ? viewModel.cancel() : viewModel.start()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: viewModel.isRunning ? "xmark" : "power")
                    Text(viewModel.isRunning ? L10n.text("action.cancel", language: language) : L10n.text("action.start", language: language))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(startButtonBackground, in: RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(.white.opacity(0.14), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(viewModel.isRunning ? L10n.text("action.cancel", language: language) : L10n.text("action.start", language: language))
        }
        .padding(18)
        .background(panelBackground, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppTheme.border(for: colorScheme), lineWidth: 1)
        }
    }

    // MARK: - Network Warning

    @ViewBuilder
    private var networkWarning: some View {
        if !viewModel.isNetworkAvailable {
            Label(L10n.text("network.offline", language: language), systemImage: "wifi.slash")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.orange)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(
                    Color.orange.opacity(0.14),
                    in: RoundedRectangle(cornerRadius: 8)
                )
        }
    }

    // MARK: - Metrics

    private var metricGrid: some View {
        let result = viewModel.primaryResult()
        return LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
            MetricCard(
                title: L10n.text("metric.download", language: language),
                value: result?.downloadMbps.formatted(.number.precision(.fractionLength(1))) ?? "--",
                unit: L10n.text("unit.mbps", language: language),
                icon: "arrow.down.circle.fill",
                color: .cyan
            )
            MetricCard(
                title: L10n.text("metric.upload", language: language),
                value: result?.uploadMbps.formatted(.number.precision(.fractionLength(1))) ?? "--",
                unit: L10n.text("unit.mbps", language: language),
                icon: "arrow.up.circle.fill",
                color: .green
            )
            MetricCard(
                title: L10n.text("metric.latency", language: language),
                value: result?.latencyMs.formatted(.number.precision(.fractionLength(0))) ?? "--",
                unit: L10n.text("unit.ms", language: language),
                icon: "timer",
                color: .orange
            )
            MetricCard(
                title: L10n.text("metric.jitter", language: language),
                value: result?.jitterMs.formatted(.number.precision(.fractionLength(0))) ?? "--",
                unit: L10n.text("unit.ms", language: language),
                icon: "waveform.path.ecg",
                color: .pink
            )
        }
    }

    // MARK: - Smart Wi-Fi Entry

    private var smartWiFiEntry: some View {
        NavigationLink {
            SmartWiFiView(language: language)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "sparkles")
                    .font(.title3)
                    .foregroundStyle(.black)
                    .frame(width: 42, height: 42)
                    .background(.white, in: RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.text("smart.title", language: language))
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(L10n.text("smart.entry.subtitle", language: language))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [
                        Color.green.opacity(0.26),
                        Color.cyan.opacity(0.16),
                        colorScheme == .dark ? Color.white.opacity(0.055) : Color.white.opacity(0.72)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 8)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppTheme.border(for: colorScheme), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.text("smart.title", language: language))
        .accessibilityHint(L10n.text("smart.entry.subtitle", language: language))
    }

    // MARK: - History

    private var history: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L10n.text("history.title", language: language))
                    .font(.title3.bold())
                    .foregroundStyle(.primary)

                Spacer()

                if !viewModel.history.isEmpty {
                    Button(L10n.text("history.clear", language: language)) {
                        showingClearHistoryConfirmation = true
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.red)
                    .accessibilityHint(L10n.text("history.clear.hint", language: language))
                }
            }

            if viewModel.history.isEmpty {
                Text(L10n.text("history.empty", language: language))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(panelBackground, in: RoundedRectangle(cornerRadius: 8))
            } else {
                ForEach(viewModel.history) { result in
                    HistoryRow(result: result, language: language)
                }
            }
        }
    }

    // MARK: - Computed Helpers

    private var statusIcon: String {
        switch viewModel.state {
        case .idle:
            return "wifi"
        case .running:
            return "dot.radiowaves.left.and.right"
        case .completed:
            return "checkmark.seal.fill"
        case .failed:
            return "exclamationmark.triangle.fill"
        }
    }

    private var statusColor: Color {
        switch viewModel.state {
        case .idle:
            return .cyan
        case .running:
            return .orange
        case .completed:
            return .green
        case .failed:
            return .red
        }
    }

    private var startButtonBackground: LinearGradient {
        LinearGradient(
            colors: viewModel.isRunning
                ? [Color.red, Color.orange]
                : [Color(red: 0.0, green: 0.74, blue: 0.82), Color(red: 0.0, green: 0.44, blue: 0.95)],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var panelBackground: LinearGradient {
        AppTheme.panelBackground(for: colorScheme)
    }
}

#if DEBUG
#Preview {
    ContentView()
}
#endif
