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

enum AppLinks {
    static let privacyPolicy = URL(string: "https://github.com/peterlang189-dot/TestWifiSpeed/blob/main/PRIVACY.md")!
    static let support = URL(string: "https://github.com/peterlang189-dot/TestWifiSpeed/blob/main/SUPPORT.md")!
    static let cloudflarePrivacy = URL(string: "https://www.cloudflare.com/policies/privacy/")!
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
        "battery.title": [.english: "Healthy Charging", .simplifiedChinese: "健康充电"],
        "battery.entry.subtitle": [
            .english: "Monitor charging and remind me at %d%%.",
            .simplifiedChinese: "监测充电，并在达到 %d%% 时提醒断电。"
        ],
        "battery.current": [.english: "Current charge", .simplifiedChinese: "当前电量"],
        "battery.unavailable": [.english: "Battery unavailable", .simplifiedChinese: "无法读取电量"],
        "battery.state.unknown": [.english: "Battery status unavailable", .simplifiedChinese: "无法获取电池状态"],
        "battery.state.unplugged": [.english: "Not charging", .simplifiedChinese: "未在充电"],
        "battery.state.charging": [.english: "Charging", .simplifiedChinese: "正在充电"],
        "battery.state.full": [.english: "Fully charged", .simplifiedChinese: "电量已充满"],
        "battery.limit.toggle": [.english: "Charge-limit reminder", .simplifiedChinese: "充电上限提醒"],
        "battery.limit.threshold": [.english: "Reminder level", .simplifiedChinese: "提醒电量"],
        "battery.limit.reached.title": [.english: "Charge limit reached", .simplifiedChinese: "已达到充电上限"],
        "battery.limit.reached.unplug": [
            .english: "Battery is at %d%% (limit %d%%). iOS does not allow this app to stop charging, so unplug the charger now.",
            .simplifiedChinese: "当前电量 %d%%（上限 %d%%）。iOS 不允许本 App 直接停止充电，请现在拔下充电器。"
        ],
        "battery.limit.reached.stopped": [
            .english: "The simulator stopped charging at %d%% (limit %d%%).",
            .simplifiedChinese: "仿真充电已在 %d%% 停止（上限 %d%%）。"
        ],
        "battery.platform.title": [.english: "iOS charging limitation", .simplifiedChinese: "iOS 充电控制限制"],
        "battery.platform.reminderonly": [
            .english: "Apple provides battery level and state monitoring, but no public API for third-party apps to cut charging power. This feature therefore alerts you at the limit instead of claiming to disconnect power.",
            .simplifiedChinese: "Apple 提供电量和充电状态监测，但没有允许第三方 App 切断充电电源的公开 API。因此本功能会在达到上限时立即提醒，而不会虚假显示已物理断电。"
        ],
        "battery.platform.canstop": [
            .english: "This control environment can stop simulated charging at the configured limit.",
            .simplifiedChinese: "当前控制环境可在设定上限停止仿真充电。"
        ],
        "battery.monitoring.note": [
            .english: "Monitoring works while the app is running. iOS may suspend apps in the background, so this is not a replacement for the system's Optimized Battery Charging feature.",
            .simplifiedChinese: "监测在 App 运行期间有效；iOS 可能暂停后台 App，因此本功能不能替代系统的“优化电池充电”。"
        ],
        "battery.notification.enable": [.english: "Allow charge-limit alerts", .simplifiedChinese: "允许充电上限通知"],
        "battery.notification.enabled": [.english: "Charge-limit alerts are allowed", .simplifiedChinese: "已允许充电上限通知"],
        "battery.notification.denied": [.english: "Notifications are off; in-app alerts still work", .simplifiedChinese: "通知未开启；App 内提醒仍然有效"],
        "battery.notification.title": [.english: "Time to unplug", .simplifiedChinese: "请停止充电"],
        "battery.notification.body": [
            .english: "Battery reached %d%% (your limit is %d%%). Unplug the charger to stop charging.",
            .simplifiedChinese: "电量已达到 %d%%（设定上限 %d%%），请拔下充电器以停止充电。"
        ],
        "battery.simulation.title": [.english: "Charging simulation", .simplifiedChinese: "充电仿真"],
        "battery.simulation.run": [.english: "Run simulation", .simplifiedChinese: "运行仿真"],
        "battery.simulation.idle": [.english: "Ready", .simplifiedChinese: "准备就绪"],
        "battery.simulation.charging": [.english: "Simulated charging", .simplifiedChinese: "仿真充电中"],
        "battery.simulation.stopped": [.english: "Stopped exactly at %d%%", .simplifiedChinese: "已精确停在 %d%%"],
        "battery.simulation.full": [.english: "Reached 100%", .simplifiedChinese: "已充至 100%"],
        "smart.title": [.english: "Connection Advisor", .simplifiedChinese: "网络分析"],
        "smart.entry.subtitle": [.english: "Analyze the active connection and get a clear quality recommendation.", .simplifiedChinese: "分析当前连接并获得清晰的网络质量建议。"],
        "smart.badge": [.english: "Connection recommendation", .simplifiedChinese: "网络质量建议"],
        "smart.hero.title": [.english: "Understand this connection", .simplifiedChinese: "了解当前网络连接"],
        "smart.hero.body": [
            .english: "Run a focused speed and latency check. The app scores the active connection and explains whether trying another network may improve the experience.",
            .simplifiedChinese: "运行速度和延迟检测，App 会评估当前连接，并说明尝试其他网络是否可能改善体验。"
        ],
        "smart.ready": [.english: "Ready to analyze", .simplifiedChinese: "准备开始分析"],
        "smart.scanning": [.english: "Checking connection quality", .simplifiedChinese: "正在检测网络质量"],
        "smart.idle.detail": [.english: "Tap analyze to measure the active connection.", .simplifiedChinese: "点击分析，检测当前连接表现。"],
        "smart.running.detail": [.english: "Measuring download speed, upload speed, latency, and jitter.", .simplifiedChinese: "正在检测下载、上传、延迟和抖动。"],
        "smart.action.optimize": [.english: "Analyze connection", .simplifiedChinese: "分析当前网络"],
        "smart.system.note": [
            .english: "This screen analyzes only the active connection. It does not scan for, select, or switch Wi-Fi networks.",
            .simplifiedChinese: "本页只分析当前连接，不会扫描、选择或切换 Wi-Fi 网络。"
        ],
        "smart.recommend.keep": [.english: "Current Wi-Fi is strong", .simplifiedChinese: "当前 Wi-Fi 表现良好"],
        "smart.recommend.switchSoon": [.english: "A better Wi-Fi may help", .simplifiedChinese: "可尝试切换更优 Wi-Fi"],
        "smart.recommend.switchNow": [.english: "Switch Wi-Fi recommended", .simplifiedChinese: "建议切换 Wi-Fi"],
        "smart.detail.keep": [
            .english: "Speed and latency are already good. Staying on this Wi-Fi is recommended.",
            .simplifiedChinese: "当前速度和延迟表现较好，建议继续使用这个 Wi-Fi。"
        ],
        "smart.detail.switchSoon": [
            .english: "This connection is usable, but trying another network may reduce buffering and lag.",
            .simplifiedChinese: "当前连接可用，但尝试其他网络可能减少缓冲和卡顿。"
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
            .english: "Test history and preferences stay on this device. A speed test sends requests to Cloudflare, which receives your IP address, estimates city/country and network ASN, and may share anonymized measurements for Internet research. The app has no ads and does not track you.",
            .simplifiedChinese: "测速历史和偏好设置仅保存在本机。测速请求会发送至 Cloudflare；Cloudflare 会接收 IP 地址、推断城市/国家和网络 ASN，并可能为互联网研究共享匿名测量数据。本 App 无广告且不跟踪用户。"
        ],
        "privacy.policy.link": [.english: "Privacy Policy", .simplifiedChinese: "隐私政策"],
        "privacy.cloudflare.link": [.english: "Cloudflare Privacy Policy", .simplifiedChinese: "Cloudflare 隐私政策"],
        "support.link": [.english: "Support and Contact", .simplifiedChinese: "支持与联系"],
        "speedtest.disclosure.title": [.english: "Before you start", .simplifiedChinese: "开始前须知"],
        "speedtest.disclosure.message": [
            .english: "A test uses about 29 MB of data. Requests go to Cloudflare, which receives your IP address and derives approximate location and network information. Continue only if you agree.",
            .simplifiedChinese: "一次测试约使用 29 MB 流量。请求会发送至 Cloudflare，后者会接收 IP 地址并推断大致位置和网络信息。请在同意后继续。"
        ],
        "speedtest.disclosure.continue": [.english: "Agree and start", .simplifiedChinese: "同意并开始"],
        "speedtest.cellular.title": [.english: "Using cellular data", .simplifiedChinese: "正在使用蜂窝数据"],
        "speedtest.cellular.message": [
            .english: "This will measure your cellular connection, not Wi-Fi, and use about 29 MB of cellular data. Cloudflare also receives the network information described in the Privacy Policy.",
            .simplifiedChinese: "本次将测量蜂窝网络而非 Wi-Fi，并使用约 29 MB 蜂窝流量。Cloudflare 也会接收隐私政策中说明的网络信息。"
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
        "network.cellular.warning": [.english: "Cellular connection detected. A test measures cellular—not Wi-Fi—and may use about 29 MB.", .simplifiedChinese: "检测到蜂窝网络。测速将测量蜂窝网络而非 Wi-Fi，并可能使用约 29 MB 流量。"],
    ]
}

extension NetworkGrade {
    func title(language: AppLanguage) -> String {
        L10n.text("grade.\(rawValue)", language: language)
    }
}
