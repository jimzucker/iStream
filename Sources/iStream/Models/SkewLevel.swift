import Foundation

public enum SkewLevel: String, CaseIterable, Codable, Sendable, Identifiable {
    case none = "None"
    case mild = "Mild"
    case heavy = "Heavy"

    public var id: String { rawValue }

    public var description: String {
        switch self {
        case .none:  return "Roughly uniform across keys"
        case .mild:  return "Top 20% of keys carry ~50% of volume"
        case .heavy: return "Top 1% of keys carry >50% of volume"
        }
    }
}
