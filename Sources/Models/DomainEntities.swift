import Foundation

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

public struct Test: Codable {
    public let name: String
    public init(name: String) {
        self.name = name
    }
}


