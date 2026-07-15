import SwiftUI

struct BatteryHealthView: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var viewModel: BatteryHealthViewModel
    let language: AppLanguage

    var body: some View {
        ZStack {
            AppTheme.pageBackground(for: colorScheme).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    batteryStatusCard
                    chargeLimitCard
                    platformNotice

#if DEBUG && targetEnvironment(simulator)
                    BatteryChargeSimulationView(
                        language: language,
                        threshold: viewModel.threshold,
                        limitEnabled: viewModel.isEnabled
                    )
#endif
                }
                .padding(18)
            }
        }
        .navigationTitle(L10n.text("battery.title", language: language))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.updateLanguage(language)
        }
        .onChange(of: language) { _, newLanguage in
            viewModel.updateLanguage(newLanguage)
        }
    }

    private var batteryStatusCard: some View {
        VStack(spacing: 18) {
            Gauge(value: Double(viewModel.snapshot.level ?? 0), in: 0...100) {
                Text(L10n.text("battery.current", language: language))
            } currentValueLabel: {
                Text(viewModel.levelText(unavailable: "--"))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(batteryTint)
            .scaleEffect(1.45)
            .frame(height: 130)
            .accessibilityValue(viewModel.levelText(unavailable: L10n.text("battery.unavailable", language: language)))

            Label(powerStateText, systemImage: powerStateIcon)
                .font(.headline)
                .foregroundStyle(batteryTint)
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(AppTheme.panelBackground(for: colorScheme), in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.border(for: colorScheme), lineWidth: 1)
        }
    }

    private var chargeLimitCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Toggle(
                L10n.text("battery.limit.toggle", language: language),
                isOn: Binding(
                    get: { viewModel.isEnabled },
                    set: viewModel.setEnabled
                )
            )
            .font(.headline)
            .tint(.green)

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(L10n.text("battery.limit.threshold", language: language))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(viewModel.threshold)%")
                        .font(.title3.bold())
                        .monospacedDigit()
                        .foregroundStyle(.green)
                }

                Slider(
                    value: Binding(
                        get: { Double(viewModel.threshold) },
                        set: { viewModel.setThreshold(Int($0.rounded())) }
                    ),
                    in: Double(ChargeLimitPolicy.allowedThresholds.lowerBound)...Double(ChargeLimitPolicy.allowedThresholds.upperBound),
                    step: 1
                )
                .tint(.green)
                .disabled(!viewModel.isEnabled)
                .accessibilityValue("\(viewModel.threshold)%")

                HStack {
                    Text("50%")
                    Spacer()
                    Text("100%")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            if let granted = viewModel.notificationPermissionGranted {
                Label(
                    L10n.text(
                        granted ? "battery.notification.enabled" : "battery.notification.denied",
                        language: language
                    ),
                    systemImage: granted ? "bell.badge.fill" : "bell.slash.fill"
                )
                .font(.footnote)
                .foregroundStyle(granted ? .green : .orange)
            } else if viewModel.isEnabled {
                Button {
                    viewModel.requestNotificationPermission()
                } label: {
                    Label(L10n.text("battery.notification.enable", language: language), systemImage: "bell.badge")
                }
                .font(.subheadline.weight(.semibold))
            }
        }
        .padding(18)
        .background(AppTheme.panelBackground(for: colorScheme), in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.border(for: colorScheme), lineWidth: 1)
        }
    }

    private var platformNotice: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(
                L10n.text("battery.platform.title", language: language),
                systemImage: viewModel.canPhysicallyStopCharging ? "bolt.badge.checkmark" : "exclamationmark.shield.fill"
            )
            .font(.headline)
            .foregroundStyle(.orange)

            Text(
                L10n.text(
                    viewModel.canPhysicallyStopCharging
                        ? "battery.platform.canstop"
                        : "battery.platform.reminderonly",
                    language: language
                )
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Text(L10n.text("battery.monitoring.note", language: language))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }

    private var batteryTint: Color {
        guard let level = viewModel.snapshot.level else { return .secondary }
        if level >= viewModel.threshold, viewModel.isEnabled { return .orange }
        if level < 20 { return .red }
        return .green
    }

    private var powerStateText: String {
        let key: String
        switch viewModel.snapshot.state {
        case .unknown:
            key = "battery.state.unknown"
        case .unplugged:
            key = "battery.state.unplugged"
        case .charging:
            key = "battery.state.charging"
        case .full:
            key = "battery.state.full"
        }
        return L10n.text(key, language: language)
    }

    private var powerStateIcon: String {
        switch viewModel.snapshot.state {
        case .unknown:
            return "battery.0percent"
        case .unplugged:
            return "battery.50percent"
        case .charging:
            return "battery.100percent.bolt"
        case .full:
            return "battery.100percent"
        }
    }

}

#if DEBUG && targetEnvironment(simulator)
private struct BatteryChargeSimulationView: View {
    let language: AppLanguage
    let threshold: Int
    let limitEnabled: Bool

    @State private var simulation = BatteryChargeSimulation()
    @State private var simulationTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(L10n.text("battery.simulation.title", language: language), systemImage: "testtube.2")
                .font(.headline)

            ProgressView(value: Double(simulation.level), total: 100)
                .tint(simulation.isCharging ? .green : .orange)

            HStack {
                Text("\(simulation.level)%")
                    .font(.title2.bold())
                    .monospacedDigit()
                Spacer()
                Text(simulationStatus)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Button {
                runSimulation()
            } label: {
                Label(
                    L10n.text("battery.simulation.run", language: language),
                    systemImage: "play.fill"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
        .padding(18)
        .background(Color.green.opacity(0.11), in: RoundedRectangle(cornerRadius: 12))
        .onDisappear {
            simulationTask?.cancel()
        }
    }

    private var simulationStatus: String {
        switch simulation.event {
        case .idle:
            return L10n.text("battery.simulation.idle", language: language)
        case .charging:
            return L10n.text("battery.simulation.charging", language: language)
        case .stoppedAtLimit:
            return String(
                format: L10n.text("battery.simulation.stopped", language: language),
                threshold
            )
        case .full:
            return L10n.text("battery.simulation.full", language: language)
        }
    }

    private func runSimulation() {
        simulationTask?.cancel()
        simulation.begin(at: max(ChargeLimitPolicy.allowedThresholds.lowerBound, threshold - 12))
        simulationTask = Task { @MainActor in
            while !Task.isCancelled, simulation.isCharging {
                try? await Task.sleep(nanoseconds: 140_000_000)
                guard !Task.isCancelled else { return }
                simulation.advance(
                    percentagePoints: 2,
                    limitEnabled: limitEnabled,
                    threshold: threshold
                )
            }
        }
    }
}
#endif

#if DEBUG
#Preview {
    NavigationStack {
        BatteryHealthView(language: .simplifiedChinese)
    }
    .environmentObject(BatteryHealthViewModel())
}
#endif
