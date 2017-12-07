//
//  KituraKit.swift
//  Kitura-Next
//
//  Created by Aaron Liberatore on 12/6/17.
//

import Foundation
import Models
import KituraKit
import SwiftyRequest
import KituraContracts
import Credentials
import CredentialsHTTP

// Auth - extension
extension KituraKit {
  
  public struct Digest {
    let username: String
    let password: String
  }
}

extension KituraKit {
  public func get<U: AuthenticatedUser, O: Codable>(_ route: String, respondWith: @escaping CodableAuthArrayResultClosure<U, O>) {
    let url = baseURL.appendingPathComponent(route)
    let request = RestRequest(url: url.absoluteString)
    request.credentials = self.authorization
    
    
    request.responseData { response in
      switch response.result {
      case .success(let data):
        guard let authObj = try? JSONDecoder().decode(AuthenticatedObject<U, [O]>.self, from: data) else {
          respondWith(nil, nil, RequestError.clientDeserializationError)
          return
        }

        respondWith(authObj.user, authObj.object, nil)
      case .failure(let error):
        if let restError = error as? RestError {
          respondWith(nil, nil, RequestError(restError: restError))
        } else {
          respondWith(nil, nil, .clientErrorUnknown)
        }
      }
    }
  }
}

/** Possible Request-by-request initializers
 
 Usage:
  client.authorize(user: "Aaron", password: "Password).get("/") { (returnedArray: [O]?, error: Error?) -> Void in
    print(returnedArray)
  }

  client.authorize(using: .digest(user: "aaron", password: "password)).get("/") { (returnedArray: [O]?, error: Error?) -> Void in
    print(returnedArray)
  }
 */
extension KituraKit {
  
  /// Mark - Authorization by request methods

  /// Basic auth direct
  public func authorize(user: String, password: String) -> KituraKit {
    self.authorization = Credentials.basicAuthentication(username: user, password: password)
    return self
  }

  /// Basic or digest? through enum
  /// We have to be explicit here because of the `import Credentials` library
  public func authorize(using credentials: SwiftyRequest.Credentials) -> KituraKit {
    self.authorization = credentials
    return self
  }

  /// Other
  public func authorize(using digest: Digest) -> KituraKit {
    self.authorization = Credentials.basicAuthentication(username: digest.username, password: digest.password)
    return self
  }
}

/** Possible Basic Authorizaiton initializers
 
 Usage:
    let client= KituraKit(baseURL: "https://localhost:8080", username: "Aaron", password: "password)
 
    let credentials = Credentials.basicAuthorizaiton(user: "Aaron", password: "password"
    let client1 = KituraKit(baseURL: "https://localhost:8080", credentials: credentials)

    let credentials = apiKey(key: "adskfnkjads")
    let client2 = KituraKit(baseURL: "https://localhost:8080", credentials: credentials)
*/
extension KituraKit {

  /// Direct basic auth
  public convenience init?(baseURL: String, username: String, password: String) {
    //if necessary, trim extra back slash
    let noSlashUrl: String = baseURL.last == "/" ? String(baseURL.dropLast()) : baseURL
    let checkedUrl = checkMistypedProtocol(inputURL: noSlashUrl)
    guard let url = URL(string: checkedUrl) else {
      return nil
    }
    
    /// Create Credentials
    let credentials = Credentials.basicAuthentication(username: username, password: password)
    self.init(baseURL: url, credentials: credentials)
  }

  /// Auth Enum
  public convenience init?(baseURL: String, credentials: SwiftyRequest.Credentials) {
    //if necessary, trim extra back slash
    let noSlashUrl: String = baseURL.last == "/" ? String(baseURL.dropLast()) : baseURL
    let checkedUrl = checkMistypedProtocol(inputURL: noSlashUrl)
    guard let url = URL(string: checkedUrl) else {
      return nil
    }

    self.init(baseURL: url, credentials: credentials)
  }
}
