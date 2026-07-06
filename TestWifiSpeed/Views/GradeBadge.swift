import SwiftUI

struct GradeBadge: View {
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
        .accessibilityLabel(result?.grade.title(language: language) ?? "No result")
        .accessibilityAddTraits(.isStaticText)
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
