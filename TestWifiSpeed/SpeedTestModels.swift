import Foundation

// MARK: - Speed Test Thresholds

enum SpeedTestThreshold {
    /// Maximum Mbps displayed on the speedometer (used to normalize the gauge).
    static let speedometerMaxMbps: Double = 200

    /// Maximum number of history entries kept locally.
    static let maxHistoryCount = 8

    /// Grade thresholds.
    static let excellentDownload: Double = 100
    static let excellentUpload: Double = 30
    static let excellentLatency: Double = 35
    static let goodDownload: Double = 50
    static let goodUpload: Double = 15
    static let goodLatency: Double = 70
    static let fairDownload: Double = 15
    static let fairUpload: Double = 5
    static let fairLatency: Double = 120

    /// Smart Wi-Fi recommendation thresholds.
    static let smartKeepDownload: Double = 50
    static let smartKeepUpload: Double = 15
    static let smartKeepLatency: Double = 70
    static let smartKeepJitter: Double = 25
    static let smartSwitchDownload: Double = 15
    static let smartSwitchUpload: Double = 5
    static let smartSwitchLatency: Double = 120
}

// MARK: - Run Coordination

/// Coordinates speed tests across screens so only one measurement runs at a
/// time. Concurrent tests would compete for bandwidth and skew both results.
@MainActor
final class SpeedTestRunGate {
    private(set) var activeRunID: UUID?

    /// All state is mutated only through the main-actor-isolated methods, so
    /// construction is safe from any isolation context (e.g. default
    /// arguments and view initializers).
    nonisolated init() {}

    func acquire(runID: UUID) -> Bool {
        guard activeRunID == nil else { return false }
        activeRunID = runID
        return true
    }

    func release(runID: UUID) {
        guard activeRunID == runID else { return }
        activeRunID = nil
    }
}

// MARK: - Stage & Grade

enum SpeedTestStage: String, CaseIterable, Identifiable {
    case idle
    case latency
    case download
    case upload
    case complete

    var id: String { rawValue }
}

enum NetworkGrade: String, CaseIterable, Codable {
    case excellent
    case good
    case fair
    case poor
}

struct TransferMeasurement: Equatable {
    let bytes: Int
    let duration: TimeInterval

    var megabitsPerSecond: Double {
        SpeedMath.megabitsPerSecond(bytes: bytes, duration: duration)
    }
}

struct SpeedTestProgress: Equatable {
    let stage: SpeedTestStage
    let fraction: Double
    let messageKey: String
}

struct SpeedTestResult: Identifiable, Equatable, Codable {
    var id = UUID()
    let measuredAt: Date
    let latencyMs: Double
    let jitterMs: Double
    let downloadMbps: Double
    let uploadMbps: Double
    let grade: NetworkGrade
}

struct SpeedTestConfiguration: Equatable {
    var latencyURL: URL
    var downloadURL: URL
    var uploadURL: URL
    var latencySampleCount: Int
    var uploadBytes: Int

    static let appDefault = SpeedTestConfiguration(
        latencyURL: URL(string: "https://speed.cloudflare.com/cdn-cgi/trace")!,
        downloadURL: URL(string: "https://speed.cloudflare.com/__down?bytes=25000000")!,
        uploadURL: URL(string: "https://speed.cloudflare.com/__up")!,
        latencySampleCount: 5,
        uploadBytes: 4_000_000
    )
}

enum SpeedMath {
    static func megabitsPerSecond(bytes: Int, duration: TimeInterval) -> Double {
        guard bytes > 0, duration > 0 else { return 0 }
        return (Double(bytes) * 8) / duration / 1_000_000
    }

    static func average(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }

    static func jitter(from latencies: [Double]) -> Double {
        guard latencies.count > 1 else { return 0 }
        let deltas = zip(latencies, latencies.dropFirst()).map { abs($1 - $0) }
        return average(deltas)
    }

    static func grade(downloadMbps: Double, uploadMbps: Double, latencyMs: Double) -> NetworkGrade {
        if downloadMbps >= SpeedTestThreshold.excellentDownload,
           uploadMbps >= SpeedTestThreshold.excellentUpload,
           latencyMs <= SpeedTestThreshold.excellentLatency {
            return .excellent
        }
        if downloadMbps >= SpeedTestThreshold.goodDownload,
           uploadMbps >= SpeedTestThreshold.goodUpload,
           latencyMs <= SpeedTestThreshold.goodLatency {
            return .good
        }
        if downloadMbps >= SpeedTestThreshold.fairDownload,
           uploadMbps >= SpeedTestThreshold.fairUpload,
           latencyMs <= SpeedTestThreshold.fairLatency {
            return .fair
        }
        return .poor
    }
}
