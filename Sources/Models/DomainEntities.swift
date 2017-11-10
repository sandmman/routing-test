import Foundation
import Contracts

public struct Employee: Codable {
    public let serial: Int
    public let name: String
    public init(serial: Int, name: String) {
        self.serial = serial
        self.name = name
    }
}

public struct User: Codable {
    public let id: Int
    public let name: String
    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}

public struct Order: Codable {
    public let id: Int
    public let name: String
    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}

public struct Test: Codable {
    public let name: String
    public init(name: String) {
        self.name = name
    }
}

public struct UserQuery: Query {
    public let category: String?
	public let date: Date?
	public let weight: Float?
	public let start: Int?
	public let end: Int?

    public init() {
        category = nil
        date = nil
        weight = nil
        start = nil
        end = nil 
    }
}

public struct QueryTest: Query {
    public let id: Int?
    public let name: String?
    public let counts: [Int]?
    public init() {
        id = nil
        name = nil
        counts = nil
    }
 }

