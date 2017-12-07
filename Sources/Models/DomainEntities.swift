import Foundation
import Contracts
import Credentials
import CredentialsHTTP

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

public class AuthUser: UserProfile, AuthenticatedUser {
    required convenience public init(_ profile: UserProfile) {
      self.init(id: profile.id, displayName: profile.displayName,
                provider: profile.provider, name: profile.name,
                emails: profile.emails, photos: profile.photos,
                extendedProperties: profile.extendedProperties)
    }
  
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
