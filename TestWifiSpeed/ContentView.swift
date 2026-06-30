import SwiftUI

struct ContentView: View {
    @AppStorage("appLanguage") private var languageCode = AppLanguage.english.rawValue
    @AppStorage("appearanceMode") private var appearanceCode = AppearanceMode.system.rawValue
    @StateObject private var viewModel = SpeedTestViewModel()
    @State private var showingSettings = false

    private var language: AppLanguage {
        AppLanguage(rawValue: languageCode) ?? .english
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    hero
                    metricGrid
                    history
                }
                .padding(20)
            }
            .background(background)
            .navigationTitle(L10n.text("app.title", language: language))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
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
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color(.secondarySystemBackground),
                Color(.systemTeal).opacity(0.16)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Label(viewModel.statusTitle(language: language), systemImage: "wifi")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text(L10n.text("app.title", language: language))
                        .font(.largeTitle.bold())
                        .lineLimit(2)
                        .minimumScaleFactor(0.72)
                    Text(viewModel.progressMessage(language: language))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                GradeBadge(result: viewModel.primaryResult(), language: language)
            }

            ProgressView(value: viewModel.progressValue())
                .tint(.teal)

            Button {
                viewModel.isRunning ? viewModel.cancel() : viewModel.start()
            } label: {
                Label(
                    viewModel.isRunning ? L10n.text("action.cancel", language: language) : L10n.text("action.start", language: language),
                    systemImage: viewModel.isRunning ? "xmark.circle.fill" : "play.fill"
                )
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(viewModel.isRunning ? .red : .teal)
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var metricGrid: some View {
        let result = viewModel.primaryResult()
        return LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
            MetricCard(
                title: L10n.text("metric.download", language: language),
                value: result?.downloadMbps.formatted(.number.precision(.fractionLength(1))) ?? "--",
                unit: L10n.text("unit.mbps", language: language),
                icon: "arrow.down.circle.fill",
                color: .blue
            )
            MetricCard(
                title: L10n.text("metric.upload", language: language),
                value: result?.uploadMbps.formatted(.number.precision(.fractionLength(1))) ?? "--",
                unit: L10n.text("unit.mbps", language: language),
                icon: "arrow.up.circle.fill",
                color: .indigo
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

    private var history: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.text("history.title", language: language))
                .font(.title3.bold())

            if viewModel.history.isEmpty {
                Text(L10n.text("history.empty", language: language))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
            } else {
                ForEach(viewModel.history) { result in
                    HistoryRow(result: result, language: language)
                }
            }
        }
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(alignment: .lastTextBaseline, spacing: 5) {
                Text(value)
                    .font(.system(size: 31, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.58)
                Text(unit)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 122, alignment: .leading)
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct GradeBadge: View {
    let result: SpeedTestResult?
    let language: AppLanguage

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "gauge.with.dots.needle.67percent")
                .font(.title2)
            Text(result?.grade.title(language: language) ?? "--")
                .font(.caption.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(.white)
        .frame(width: 86, height: 70)
        .background(gradeColor, in: RoundedRectangle(cornerRadius: 8))
    }

    private var gradeColor: Color {
        switch result?.grade {
        case .excellent:
            return .green
        case .good:
            return .teal
        case .fair:
            return .orange
        case .poor:
            return .red
        case nil:
            return .gray
        }
    }
}

private struct HistoryRow: View {
    let result: SpeedTestResult
    let language: AppLanguage

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundStyle(.teal)
            VStack(alignment: .leading, spacing: 4) {
                Text(result.measuredAt, style: .time)
                    .font(.headline)
                Text("\(L10n.text("metric.download", language: language)) \(result.downloadMbps.formatted(.number.precision(.fractionLength(1)))) \(L10n.text("unit.mbps", language: language))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(result.grade.title(language: language))
                .font(.caption.bold())
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(.thinMaterial, in: Capsule())
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct SettingsView: View {
    @Binding var languageCode: String
    @Binding var appearanceCode: String
    let language: AppLanguage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section(L10n.text("settings.language", language: language)) {
                    Picker(L10n.text("settings.language", language: language), selection: $languageCode) {
                        ForEach(AppLanguage.allCases) { option in
                            Text(option.displayName).tag(option.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(L10n.text("settings.appearance", language: language)) {
                    Picker(L10n.text("settings.appearance", language: language), selection: $appearanceCode) {
                        ForEach(AppearanceMode.allCases) { option in
                            Text(title(for: option)).tag(option.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section(L10n.text("privacy.title", language: language)) {
                    Text(L10n.text("privacy.body", language: language))
                }

                Section(L10n.text("review.title", language: language)) {
                    Text(L10n.text("review.body", language: language))
                }
            }
            .navigationTitle(L10n.text("settings.title", language: language))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(L10n.text("action.done", language: language)) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func title(for mode: AppearanceMode) -> String {
        switch mode {
        case .system:
            return L10n.text("appearance.system", language: language)
        case .light:
            return L10n.text("appearance.light", language: language)
        case .dark:
            return L10n.text("appearance.dark", language: language)
        }
    }
}

#Preview {
    ContentView()
}
