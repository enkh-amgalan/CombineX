import Foundation
import Nimble
import Semver

public extension Expectation {
    
    func to(_ predicate: Predicate<T>, minimalVersion: XcodeVersion, description: String? = nil) {
        toVersioning([minimalVersion: predicate], description: description)
    }
    
    func toVersioning(_ predicates: [XcodeVersion: Predicate<T>], description: String? = nil) {
        precondition(!predicates.isEmpty)
        let versions = predicates.keys.sorted(by: >)
        #if USE_COMBINE
        let osVersion = ProcessInfo.processInfo.operatingSystemSemanticVersion
        guard let targetVersion = versions.first(where: { osVersion >= $0.systemVersion }) else {
            // no available predicate for current system version
            // should we fail here?
            return
        }
        #else
        let targetVersion = versions.first!
        #endif
        let predicate = predicates[targetVersion]!
        to(predicate, description: description)
    }
}

// assume combine change its behaviour with xcode release, along with system update.
public enum XcodeVersion: Comparable {
    
    case v11_0
    case v11_1
    case v11_2
    case v11_3
    
    #if canImport(Darwin)
    var systemVersion: Semver {
        #if os(macOS)
        return macOSVersion
        #elseif os(iOS)
        return iOSVersion
        #elseif os(tvOS)
        return tvOSVersion
        #elseif os(watchOS)
        return watchOSVersion
        #endif
    }
    #endif
    
    var macOSVersion: Semver {
        switch self {
        case .v11_0: return "10.15.0"
        case .v11_1: return "10.15.0"
        case .v11_2: return "10.15.1"
        case .v11_3: return "10.15.2"
        }
    }
    
    var iOSVersion: Semver {
        switch self {
        case .v11_0: return "13.0.0"
        case .v11_1: return "13.1.0"
        case .v11_2: return "13.2.0"
        case .v11_3: return "13.3.0"
        }
    }
    
    var tvOSVersion: Semver {
        switch self {
        case .v11_0: return "13.0.0"
        case .v11_1: return "13.0.0"
        case .v11_2: return "13.2.0"
        case .v11_3: return "13.3.0"
        }
    }
    
    var watchOSVersion: Semver {
        switch self {
        case .v11_0: return "6.0.0"
        case .v11_1: return "6.0.0"
        case .v11_2: return "6.1.0"
        case .v11_3: return "6.1.1"
        }
    }
    
    var version: Semver {
        switch self {
        case .v11_0: return "11.0.0"
        case .v11_1: return "11.1.0"
        case .v11_2: return "11.2.0"
        case .v11_3: return "11.3.0"
        }
    }
    
    public static func < (lhs: XcodeVersion, rhs: XcodeVersion) -> Bool {
        return lhs.version < rhs.version
    }
}
