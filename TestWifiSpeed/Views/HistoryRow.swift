import SwiftUI

struct HistoryRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let result: SpeedTestResult
    let language: AppLanguage

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.headline)
                .foregroundStyle(.cyan)
                .frame(width: 30, height: 30)
                .background(AppTheme.subtleFill(for: colorScheme), in: RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 4) {
                Text(result.measuredAt, style: .time)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("\(L10n.text("metric.download", language: language)) \(result.downloadMbps.formatted(.number.precision(.fractionLength(1)))) \(L10n.text("unit.mbps", language: language))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
                    colorScheme == .dark ? Color.white.opacity(0.12) : Color.white.opacity(0.94),
                    colorScheme == .dark ? Color.white.opacity(0.05) : Color.white.opacity(0.70)
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(result.grade.title(language: language)): \(result.downloadMbps.formatted(.number.precision(.fractionLength(1)))) \(L10n.text("unit.mbps", language: language))")
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
