import Foundation

enum BatteryPowerState: Equatable {
    case unknown
    case unplugged
    case charging
    case full
}

struct BatterySnapshot: Equatable {
    let level: Int?
    let state: BatteryPowerState

    static let unavailable = BatterySnapshot(level: nil, state: .unknown)

    init(level: Int?, state: BatteryPowerState) {
        self.level = level.map { min(max($0, 0), 100) }
        self.state = state
    }
}

enum ChargeLimitDecision: Equatable {
    case none
    case limitReached(level: Int)
}

struct ChargeLimitPolicy {
    static let defaultThreshold = 90
    static let allowedThresholds = 50...100

    static func normalizedThreshold(_ value: Int) -> Int {
        min(max(value, allowedThresholds.lowerBound), allowedThresholds.upperBound)
    }
}

struct ChargeLimitStateMachine {
    private(set) var isArmed = true

    mutating func reset() {
        isArmed = true
    }

    mutating func process(
        snapshot: BatterySnapshot,
        isEnabled: Bool,
        threshold: Int
    ) -> ChargeLimitDecision {
        guard isEnabled else {
            isArmed = true
            return .none
        }

        guard let level = snapshot.level else {
            return .none
        }

        switch snapshot.state {
        case .unplugged:
            // A new charging session should be able to alert again, even if the
            // device was unplugged while still above the configured threshold.
            isArmed = true
            return .none
        case .unknown:
            return .none
        case .charging, .full:
            guard level >= ChargeLimitPolicy.normalizedThreshold(threshold) else {
                isArmed = true
                return .none
            }
            guard isArmed else {
                return .none
            }
            isArmed = false
            return .limitReached(level: level)
        }
    }
}

enum BatterySimulationEvent: Equatable {
    case idle(level: Int)
    case charging(level: Int)
    case stoppedAtLimit(level: Int)
    case full
}

struct BatteryChargeSimulation: Equatable {
    private(set) var level: Int
    private(set) var isCharging: Bool
    private(set) var event: BatterySimulationEvent

    init(level: Int = 70, isCharging: Bool = false) {
        let safeLevel = min(max(level, 0), 100)
        self.level = safeLevel
        self.isCharging = isCharging && safeLevel < 100
        self.event = self.isCharging ? .charging(level: safeLevel) : .idle(level: safeLevel)
    }

    mutating func begin(at level: Int) {
        let safeLevel = min(max(level, 0), 99)
        self.level = safeLevel
        isCharging = true
        event = .charging(level: safeLevel)
    }

    @discardableResult
    mutating func advance(
        percentagePoints: Int = 1,
        limitEnabled: Bool,
        threshold: Int
    ) -> BatterySimulationEvent {
        guard isCharging else {
            return event
        }

        let safeIncrement = max(percentagePoints, 1)
        let limit = ChargeLimitPolicy.normalizedThreshold(threshold)
        let nextLevel = min(level + safeIncrement, 100)

        if limitEnabled, nextLevel >= limit {
            level = limit
            isCharging = false
            event = .stoppedAtLimit(level: limit)
        } else if nextLevel >= 100 {
            level = 100
            isCharging = false
            event = .full
        } else {
            level = nextLevel
            event = .charging(level: level)
        }

        return event
    }
}
