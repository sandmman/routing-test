import Foundation
import Contracts
import Credentials
import CredentialsHTTP

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
        self.init(category: nil, date: nil, weight: nil, start: nil, end: nil) 
    }

    public init(category: String? = nil, date: Date? = nil, weight: Float? = nil, start: Int? = nil, end: Int? = nil) {
        self.category = category
        self.date = date
        self.weight = weight
        self.start = start
        self.end = end
    }
}

public class AuthUser: UserProfile, AuthenticatedUser {
    public static func createCredentials() -> Credentials {
        // Configuration of Credentials object would go here
        let credentials = Credentials()
        let users = ["john" : "pwd1", "mary" : "pwd2"]
        let basicCredentials = CredentialsHTTPBasic(verifyPassword: { userId, password, callback in
            print("Checking authentication credentials...")
            print("userId: \(userId), password: \(password)")
            if let storedPassword = users[userId], storedPassword == password {
                print("Valid credentials... creating UserProfile.")
                callback(UserProfile(id: userId, displayName: userId, provider: "HTTPBasic"))
            } else {
                print("Invalid credentials!")
                callback(nil)
            }
        })
        credentials.register(plugin: basicCredentials)
        return credentials
    }

    // Child extension (via inheritance)
    public var xyz: String? {
        return extendedProperties["xyz"] as? String
    }

    public var abc: Int? {
        return extendedProperties["abc"] as? Int
    }

}
