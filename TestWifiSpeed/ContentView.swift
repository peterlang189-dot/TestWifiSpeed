import SwiftUI
import UIKit

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
            ZStack {
                background

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        header
                        speedometerPanel
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
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.headline)
                    }
                    .tint(.white)
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
        ZStack {
            Color(red: 0.035, green: 0.045, blue: 0.07)

            LinearGradient(
                colors: [
                    Color(red: 0.0, green: 0.64, blue: 0.78).opacity(0.30),
                    Color(red: 0.56, green: 0.20, blue: 0.76).opacity(0.16),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            LinearGradient(
                colors: [
                    Color.clear,
                    Color(red: 0.93, green: 0.45, blue: 0.18).opacity(0.10)
                ],
                startPoint: .center,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Label(viewModel.statusTitle(language: language), systemImage: statusIcon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(statusColor)
                Text(L10n.text("app.title", language: language))
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
            }

            Spacer()

            GradeBadge(result: viewModel.primaryResult(), language: language)
        }
    }

    private var speedometerPanel: some View {
        let result = viewModel.primaryResult()
        let speedValue = result?.downloadMbps
        let displayValue = speedValue?.formatted(.number.precision(.fractionLength(1))) ?? "--"
        let speedFraction = min(max((speedValue ?? 0) / 200, 0), 1)
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
                .stroke(.white.opacity(0.12), lineWidth: 1)
        }
    }

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
                        .foregroundStyle(.white)
                    Text(L10n.text("smart.entry.subtitle", language: language))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.62))
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white.opacity(0.54))
            }
            .padding(16)
            .background(
                LinearGradient(
                    colors: [
                        Color.green.opacity(0.26),
                        Color.cyan.opacity(0.16),
                        Color.white.opacity(0.055)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 8)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.white.opacity(0.12), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var history: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.text("history.title", language: language))
                .font(.title3.bold())
                .foregroundStyle(.white)

            if viewModel.history.isEmpty {
                Text(L10n.text("history.empty", language: language))
                    .foregroundStyle(.white.opacity(0.62))
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

@MainActor
private final class SmartWiFiAdvisor: ObservableObject {
    enum State {
        case idle
        case running(SpeedTestProgress?)
        case completed(SpeedTestResult, SmartWiFiRecommendation)
        case failed(String)
    }

    @Published private(set) var state: State = .idle

    private let runner = SpeedTestRunner()
    private var task: Task<Void, Never>?

    var isRunning: Bool {
        if case .running = state { return true }
        return false
    }

    func start() {
        guard !isRunning else { return }
        state = .running(nil)
        task = Task {
            do {
                let result = try await runner.run { [weak self] progress in
                    self?.state = .running(progress)
                }
                state = .completed(result, SmartWiFiRecommendation(result: result))
            } catch is CancellationError {
                state = .idle
            } catch {
                state = .failed(error.localizedDescription)
            }
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
        state = .idle
    }

    func progressValue() -> Double {
        switch state {
        case .running(let progress):
            return progress?.fraction ?? 0.05
        case .completed:
            return 1
        default:
            return 0
        }
    }

    func statusText(language: AppLanguage) -> String {
        switch state {
        case .idle:
            return L10n.text("smart.ready", language: language)
        case .running(let progress):
            return L10n.text(progress?.messageKey ?? "smart.scanning", language: language)
        case .completed(_, let recommendation):
            return recommendation.title(language: language)
        case .failed(let message):
            return message.isEmpty ? L10n.text("error.generic", language: language) : message
        }
    }
}

private enum SmartWiFiRecommendation {
    case keep
    case switchSoon
    case switchNow

    init(result: SpeedTestResult) {
        if result.downloadMbps >= 50, result.uploadMbps >= 15, result.latencyMs <= 70, result.jitterMs <= 25 {
            self = .keep
        } else if result.downloadMbps >= 15, result.uploadMbps >= 5, result.latencyMs <= 120 {
            self = .switchSoon
        } else {
            self = .switchNow
        }
    }

    var icon: String {
        switch self {
        case .keep:
            return "checkmark.seal.fill"
        case .switchSoon:
            return "arrow.triangle.2.circlepath"
        case .switchNow:
            return "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .keep:
            return .green
        case .switchSoon:
            return .orange
        case .switchNow:
            return .red
        }
    }

    func title(language: AppLanguage) -> String {
        switch self {
        case .keep:
            return L10n.text("smart.recommend.keep", language: language)
        case .switchSoon:
            return L10n.text("smart.recommend.switchSoon", language: language)
        case .switchNow:
            return L10n.text("smart.recommend.switchNow", language: language)
        }
    }

    func detail(language: AppLanguage) -> String {
        switch self {
        case .keep:
            return L10n.text("smart.detail.keep", language: language)
        case .switchSoon:
            return L10n.text("smart.detail.switchSoon", language: language)
        case .switchNow:
            return L10n.text("smart.detail.switchNow", language: language)
        }
    }
}

private struct SmartWiFiView: View {
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

private struct SmartWiFiBackground: View {
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

private struct SmartPanelBackground: View {
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

private struct SpeedometerView: View {
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
                    .stroke(.white.opacity(0.10), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
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
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Text(unit)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.62))
                    Text(caption)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.white.opacity(0.72))
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
    }
}

private struct GaugeTicks: View {
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
                        .fill(lit ? Color.white.opacity(0.82) : Color.white.opacity(0.18))
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

private struct GaugeArc: Shape {
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

private struct MetricCard: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                Spacer()
            }
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.62))
            HStack(alignment: .lastTextBaseline, spacing: 5) {
                Text(value)
                    .font(.system(size: 31, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.58)
                Text(unit)
                    .font(.caption.bold())
                    .foregroundStyle(.white.opacity(0.48))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 122, alignment: .leading)
        .padding(16)
        .background(
            LinearGradient(
                colors: [
                    color.opacity(0.22),
                    Color.white.opacity(0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        }
    }
}

private struct GradeBadge: View {
    let result: SpeedTestResult?
    let language: AppLanguage

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: "gauge.with.dots.needle.67percent")
                .font(.title3)
            Text(result?.grade.title(language: language) ?? "--")
                .font(.caption.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(.white)
        .frame(width: 82, height: 66)
        .background(gradeColor, in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        }
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
                .font(.headline)
                .foregroundStyle(.cyan)
                .frame(width: 30, height: 30)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 4) {
                Text(result.measuredAt, style: .time)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("\(L10n.text("metric.download", language: language)) \(result.downloadMbps.formatted(.number.precision(.fractionLength(1)))) \(L10n.text("unit.mbps", language: language))")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.58))
            }
            Spacer()
            Text(result.grade.title(language: language))
                .font(.caption.bold())
                .foregroundStyle(.white)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(gradeColor.opacity(0.78), in: Capsule())
        }
        .padding()
        .background(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.12),
                    Color.white.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 8)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.10), lineWidth: 1)
        }
    }

    private var gradeColor: Color {
        switch result.grade {
        case .excellent:
            return .green
        case .good:
            return .cyan
        case .fair:
            return .orange
        case .poor:
            return .red
        }
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
