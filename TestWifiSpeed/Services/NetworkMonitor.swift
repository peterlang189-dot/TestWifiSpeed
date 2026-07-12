import Network
import Combine

final class NetworkMonitor: ObservableObject {
    @Published private(set) var isConnected = true
    @Published private(set) var connectionType: ConnectionType = .unknown

    enum ConnectionType: String {
        case wifi
        case cellular
        case wired
        case unknown
    }

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.wifispeed.networkmonitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.isConnected = path.status == .satisfied
                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self?.connectionType = .wired
                } else {
                    self?.connectionType = .unknown
                }
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}

enum SpeedTestStartRequirement: Equatable {
    case allowed
    case disclosure
    case cellularDisclosure
    case offline
}

enum SpeedTestStartPolicy {
    static func requirement(
        isNetworkAvailable: Bool,
        connectionType: NetworkMonitor.ConnectionType,
        hasAcknowledgedDisclosure: Bool
    ) -> SpeedTestStartRequirement {
        guard isNetworkAvailable else { return .offline }
        if connectionType == .cellular { return .cellularDisclosure }
        if !hasAcknowledgedDisclosure { return .disclosure }
        return .allowed
    }
}
