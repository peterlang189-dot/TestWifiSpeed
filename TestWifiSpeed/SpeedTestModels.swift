import Foundation

enum SpeedTestStage: String, CaseIterable, Identifiable {
    case idle
    case latency
    case download
    case upload
    case complete

    var id: String { rawValue }
}

enum NetworkGrade: String, CaseIterable {
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

struct SpeedTestResult: Identifiable, Equatable {
    let id = UUID()
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
        if downloadMbps >= 100, uploadMbps >= 30, latencyMs <= 35 {
            return .excellent
        }
        if downloadMbps >= 50, uploadMbps >= 15, latencyMs <= 70 {
            return .good
        }
        if downloadMbps >= 15, uploadMbps >= 5, latencyMs <= 120 {
            return .fair
        }
        return .poor
    }
}
