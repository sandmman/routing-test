import Foundation
import Kitura
import KituraContracts
import RouterExtension
import Models
import LoggerAPI
import HeliumLogger
import Credentials
import CredentialsHTTP

// HeliumLogger disables all buffering on stdout
HeliumLogger.use(LoggerMessageType.verbose)

var userStore: [Int: User] = [1: User(id: 1, name: "Mike"),
                              2: User(id: 2, name: "Chris"),
                              3: User(id: 3, name: "Ricardo")]

// Dictionary of Order entities
var orderStore: [Int: Order] = [1: Order(id: 1, name: "order1"),
                                2: Order(id: 2, name: "order2"),
                                3: Order(id: 3, name: "order3")]

let router = Router()

/// This is the current standard route. By default this doesn't return the user profile/request object pair so symmetric auth requests will fail during jsondecoding
router.get("/basic") { request, response, error in
  let orders: [Order] = orderStore.map { return $1 }
  response.send(orders)
  try? response.end()
}

// A codable approach for authentication (inspired by code from cbailey @ https://github.com/seabaylea/CodableAuth)
// john:pwd1@localhost:8080/orders
router.post("/orders") { (authUser: AuthUser, order: Order, respondWith: (Order?, RequestError?) -> Void) in
    print("Valid credentials must have been provided if we see this output.")
    print("UserProfile.id: \(authUser.id)")
    print("UserProfile.provider: \(authUser.provider)")
    print("UserProfile.displayName: \(authUser.displayName)")
    print("extendend properties: \(String(describing: authUser.xyz))")
    print("Order: \(order)")
    respondWith(order, nil)
}

/// Symmetric Auth handler
/// A codable approach to authentication. It passes both the auth user and the [order] array back to the user
router.get("/orders") { (authUser: AuthUser, respondWith: ([Order]?, RequestError?) -> Void) in
  print("Valid credentials must have been provided if we see this output.")
  print("UserProfile.id: \(authUser.id)")
  print("UserProfile.provider: \(authUser.provider)")
  print("UserProfile.displayName: \(authUser.displayName)")
  print("extendend properties: \(String(describing: authUser.xyz))")
  let orders: [Order] = orderStore.map { return $1}
  respondWith(orders, nil)
}

// Add an HTTP server and connect it to the router
Kitura.addHTTPServer(onPort: 8080, with: router)

// Start the Kitura runloop (this call never returns)
Kitura.run()
