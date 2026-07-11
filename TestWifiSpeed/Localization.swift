import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case simplifiedChinese = "zh-Hans"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .simplifiedChinese:
            return "简体中文"
        }
    }
}

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

enum AppTheme {
    static func pageBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? Color(red: 0.035, green: 0.045, blue: 0.07)
            : Color(red: 0.94, green: 0.965, blue: 0.99)
    }

    static func panelBackground(for colorScheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: colorScheme == .dark
                ? [Color.white.opacity(0.13), Color.white.opacity(0.055)]
                : [Color.white.opacity(0.96), Color.white.opacity(0.72)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func border(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.10)
    }

    static func subtleFill(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.055)
    }

    static func gaugeTrack(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white.opacity(0.10) : Color.black.opacity(0.10)
    }

    static func gaugeTick(isLit: Bool, colorScheme: ColorScheme) -> Color {
        if colorScheme == .dark {
            return Color.white.opacity(isLit ? 0.82 : 0.18)
        }
        return Color.black.opacity(isLit ? 0.70 : 0.16)
    }
}

enum L10n {
    static func text(_ key: String, language: AppLanguage) -> String {
        strings[key]?[language] ?? strings[key]?[.english] ?? key
    }

    private static let strings: [String: [AppLanguage: String]] = [
        "app.title": [.english: "Test WiFi Speed", .simplifiedChinese: "WiFi 网络测试"],
        "app.subtitle": [.english: "Measure latency, download, upload, and jitter.", .simplifiedChinese: "测试延迟、下载、上传和抖动。"],
        "action.start": [.english: "Start test", .simplifiedChinese: "开始测试"],
        "action.cancel": [.english: "Cancel", .simplifiedChinese: "取消"],
        "action.settings": [.english: "Settings", .simplifiedChinese: "设置"],
        "action.done": [.english: "Done", .simplifiedChinese: "完成"],
        "smart.title": [.english: "Smart Wi-Fi", .simplifiedChinese: "智能 Wi-Fi"],
        "smart.entry.subtitle": [.english: "Find whether a faster, lower-latency Wi-Fi is worth choosing.", .simplifiedChinese: "自动评估是否应选择更快、延迟更低的 Wi-Fi。"],
        "smart.badge": [.english: "Automatic recommendation", .simplifiedChinese: "自动优选建议"],
        "smart.hero.title": [.english: "Choose the better connection", .simplifiedChinese: "选择更优网络连接"],
        "smart.hero.body": [
            .english: "Run a focused speed and latency check. The app scores the current connection and tells you when switching Wi-Fi should improve the experience.",
            .simplifiedChinese: "运行一次速度和延迟检测，App 会评估当前连接，并在切换 Wi-Fi 可能更流畅时给出建议。"
        ],
        "smart.ready": [.english: "Ready to optimize", .simplifiedChinese: "准备开始优选"],
        "smart.scanning": [.english: "Checking Wi-Fi quality", .simplifiedChinese: "正在检测 Wi-Fi 质量"],
        "smart.idle.detail": [.english: "Tap optimize to measure the active connection.", .simplifiedChinese: "点击开始优选，检测当前连接表现。"],
        "smart.running.detail": [.english: "Measuring download speed, upload speed, latency, and jitter.", .simplifiedChinese: "正在检测下载、上传、延迟和抖动。"],
        "smart.action.optimize": [.english: "Auto optimize Wi-Fi", .simplifiedChinese: "自动优选 Wi-Fi"],
        "smart.system.note": [
            .english: "iOS requires changing Wi-Fi manually in the Settings app. This screen only recommends the best action and does not use private Wi-Fi scanning APIs.",
            .simplifiedChinese: "iOS 要求用户在系统设置中手动更换 Wi-Fi。本页只提供优选建议，不使用私有扫网或静默切网 API。"
        ],
        "smart.recommend.keep": [.english: "Current Wi-Fi is strong", .simplifiedChinese: "当前 Wi-Fi 表现良好"],
        "smart.recommend.switchSoon": [.english: "A better Wi-Fi may help", .simplifiedChinese: "可尝试切换更优 Wi-Fi"],
        "smart.recommend.switchNow": [.english: "Switch Wi-Fi recommended", .simplifiedChinese: "建议切换 Wi-Fi"],
        "smart.detail.keep": [
            .english: "Speed and latency are already good. Staying on this Wi-Fi is recommended.",
            .simplifiedChinese: "当前速度和延迟表现较好，建议继续使用这个 Wi-Fi。"
        ],
        "smart.detail.switchSoon": [
            .english: "This connection is usable, but a stronger nearby Wi-Fi may reduce buffering and lag.",
            .simplifiedChinese: "当前连接可用，但切换到信号更强的 Wi-Fi 可能降低卡顿和延迟。"
        ],
        "smart.detail.switchNow": [
            .english: "The current connection is slow or unstable. Choose a faster, lower-latency Wi-Fi in Settings.",
            .simplifiedChinese: "当前连接较慢或不稳定，请在系统设置中选择速度更快、延迟更低的 Wi-Fi。"
        ],
        "status.ready": [.english: "Ready", .simplifiedChinese: "准备就绪"],
        "status.running": [.english: "Testing", .simplifiedChinese: "测试中"],
        "status.finished": [.english: "Completed", .simplifiedChinese: "已完成"],
        "status.failed": [.english: "Test failed", .simplifiedChinese: "测试失败"],
        "metric.download": [.english: "Download", .simplifiedChinese: "下载"],
        "metric.upload": [.english: "Upload", .simplifiedChinese: "上传"],
        "metric.latency": [.english: "Latency", .simplifiedChinese: "延迟"],
        "metric.jitter": [.english: "Jitter", .simplifiedChinese: "抖动"],
        "metric.grade": [.english: "Quality", .simplifiedChinese: "质量"],
        "unit.mbps": [.english: "Mbps", .simplifiedChinese: "Mbps"],
        "unit.ms": [.english: "ms", .simplifiedChinese: "毫秒"],
        "history.title": [.english: "Recent tests", .simplifiedChinese: "最近测试"],
        "history.empty": [.english: "Run a test to build local history.", .simplifiedChinese: "运行一次测试后会显示本地历史。"],
        "history.clear": [.english: "Clear", .simplifiedChinese: "清除"],
        "history.clear.hint": [.english: "Deletes all locally stored speed test results.", .simplifiedChinese: "删除保存在本机的全部测速结果。"],
        "history.clear.confirm.title": [.english: "Clear test history?", .simplifiedChinese: "清除测速历史？"],
        "history.clear.confirm.message": [
            .english: "This permanently deletes all speed test results stored on this device.",
            .simplifiedChinese: "这会永久删除保存在本机的全部测速结果。"
        ],
        "settings.title": [.english: "Settings", .simplifiedChinese: "设置"],
        "settings.language": [.english: "Language", .simplifiedChinese: "语言"],
        "settings.appearance": [.english: "Appearance", .simplifiedChinese: "外观"],
        "appearance.system": [.english: "System", .simplifiedChinese: "跟随系统"],
        "appearance.light": [.english: "Light", .simplifiedChinese: "浅色"],
        "appearance.dark": [.english: "Dark", .simplifiedChinese: "深色"],
        "privacy.title": [.english: "Privacy", .simplifiedChinese: "隐私"],
        "privacy.body": [
            .english: "This app does not collect personal data, does not track you, and stores test history only on this device. Speed tests contact public HTTPS endpoints to measure transfer performance.",
            .simplifiedChinese: "本 App 不收集个人数据、不跟踪用户，测速历史仅保存在本机。测速时会连接公开 HTTPS 端点以测量传输性能。"
        ],
        "review.title": [.english: "App Store readiness", .simplifiedChinese: "上架准备"],
        "review.body": [
            .english: "Uses public APIs, avoids restricted Wi-Fi identifiers, includes a privacy manifest, and presents a complete user-facing feature set.",
            .simplifiedChinese: "使用公开 API，避免受限 Wi-Fi 标识符，包含隐私清单，并提供完整的用户功能。"
        ],
        "progress.latency": [.english: "Checking latency", .simplifiedChinese: "正在检测延迟"],
        "progress.download": [.english: "Measuring download speed", .simplifiedChinese: "正在测试下载速度"],
        "progress.upload": [.english: "Measuring upload speed", .simplifiedChinese: "正在测试上传速度"],
        "progress.complete": [.english: "Finishing test", .simplifiedChinese: "正在完成测试"],
        "grade.excellent": [.english: "Excellent", .simplifiedChinese: "极佳"],
        "grade.good": [.english: "Good", .simplifiedChinese: "良好"],
        "grade.fair": [.english: "Fair", .simplifiedChinese: "一般"],
        "grade.poor": [.english: "Poor", .simplifiedChinese: "较差"],
        "error.generic": [.english: "Please check your connection and try again.", .simplifiedChinese: "请检查网络连接后重试。"],
        "network.offline": [.english: "No network connection available.", .simplifiedChinese: "当前无网络连接。"],
    ]
}

extension NetworkGrade {
    func title(language: AppLanguage) -> String {
        L10n.text("grade.\(rawValue)", language: language)
    }
}
