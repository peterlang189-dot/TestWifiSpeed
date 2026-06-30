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
        "error.generic": [.english: "Please check your connection and try again.", .simplifiedChinese: "请检查网络连接后重试。"]
    ]
}

extension NetworkGrade {
    func title(language: AppLanguage) -> String {
        L10n.text("grade.\(rawValue)", language: language)
    }
}
