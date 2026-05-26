import Foundation

public enum FieldType: String, CaseIterable, Codable, Sendable {
    case string
    case int
    case long
    case double
    case decimal
    case timestamp
    case boolean
    case bytes
}

public struct Field: Identifiable, Hashable, Codable, Sendable {
    public var id: UUID
    public var name: String
    public var type: FieldType

    public init(id: UUID = UUID(), name: String, type: FieldType) {
        self.id = id
        self.name = name
        self.type = type
    }
}
