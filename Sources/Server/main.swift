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
router.get("/basic/:id+") { request, response, error in
    print(request.parameters)
  let orders: [Order] = orderStore.map { return $1 }
  try? response.send(orders)
  try? response.end()
}

///////////
///
// URL Route Params
///
//////////

/// what if we automatically created sub-routes that passed on the object
// localhost:8080/customers/3233/orders/1432
// customers route
// orders route

/**
 /// Stored somehow in a vtable. We have some way to recursively map to other closures
 [
 "customer" : (id, respondWith(Customer, RequestError)),
 "order": (id, "customer", respondWith(Order, RequestError)),
 ]
 
 // 1. this is route itself..
 router.get("customer") { Identifier, respondWith(Customer, RequestError) in
 
 }
 
 // 2. this is chained to route 1. This takes its respondWith checks for an error underneath and passes the custom on if it exists
 /// Problem...How do we guarantee the customer route exists
 router.get("order", for: "customer") { customer: Customer, respondWith(Order, RequestError) in

}
 
 // 3. this is chained to route 1. This takes its respondWith checks for an error underneath and passes the custom on if it exists
 /// Problem...How do we guarantee the customer route exists
 router.get("order", for: "customer") { Identifier, Customer, respondWith(Order, RequestError) in
 
 }
 */

////
/// Instantiate your Params Object
//  Since we do not have a way to look at the field types before instantiate we need a user to instantiate a default version for us.
//  How should optional params work?
//
struct Parameters: Params {
    let int: Int? //
    let string: String
    let stringArray: [String]

    init() {
        self.int = nil
        self.string = ""
        self.stringArray = []
    }
    
    static let excluded: [String] = []
 }

// 1
// http://localhost:8080/int/3233/string/my_string/stringArray/str1/str2/str3/orders
// A possible implementation for multiple URL route params using codable
// This approach abstracts the parameter definitions from the user. It autogenerates the route url leaving the user to
// add an end route as was a hole in #2 or nothing.
//
// The hole in this approach is that the Developer must implement a default constructor, so we can easily construct
// an instance to use our encoder on. There are packages I have seen that we could leverage or create or own to
// auto instantiate codable objects, but this would require essentially writing a reflection library ourselves.
//
// How should we handle optional params?
// 1. Exclude preliminary tag "/string/:string/stringArray/:stringArray+/orders" --> /string/:string/orders
// 2. Keep tag and simply use * identifier "/string/:string/stringArray/:stringArray*/orders" --> /string/:string/orders
// I lean towards the second, but would like input
//
// "/int/:int(\\d+)/string/:string/stringArray/:stringArray+/orders"
 router.get("/orders") { (params: Parameters, respondWith: ([Order]?, RequestError?) -> Void) in
    print("GET on /orders with inferred route parameters")
    print("parameters: \(params)")
    respondWith([], nil)
 }

// 2 - Identifier style with flaws
// A possible implementation for multiple URL route params - codable
// Developer does not need to specify the identifiers for each entity in the path
// Instead, we infer them - assumption is that because it is a codable route then identifiers should be assigned/generated for each entity
// Though these is a hole in this approach... it assumes that an identifier is needed for the last element in the path... which may or may not be the case
// dependending on the use case :-/
// Additional hole: How do you decide if its a route paramter list or not ?, +, *
// localhost:8080/customers/3233/orders/1432
router.get("/customers/*/orders") { (identifiers: [Int], respondWith: (Order?, RequestError?) -> Void) in
    print("GET on /orders with inferred route parameters")
    print("identifiers: \(identifiers)")
    let order = orderStore[identifiers[1]]
    respondWith(order, nil)
}

// 3 - Non type - safe. Vapor style
// Another possible implementation for multiple URL route params - codable
// See the identifiers array and its type
// localhost:8080/customers/3233/orders/1
// router.get("/customers/:id1/orders/:id2") { (identifiers: [Int], respondWith: (Order?, RequestError?) -> Void) in
//     print("GET on /orders with query parameters")
//     print("identifiers: \(identifiers)")
//     let order = orderStore[identifiers[1]]
//     respondWith(order, nil)
// }

// Another possible approach for URL route parameters & codable
// We could also provide route params and query params as this: Params.route, Params.query
// Now... if we were to take this approach, I am then thinking  we should change the new codable API we just released... so that the route is specified in the same
// way we do below...
// localhost:8080/users/1234/orders/1VZXY3/entity/4398/entity2/234r234 - think more from an API perspecitve as opposed to thinking of it in terms of URL
router.get("users", Int.parameter, "orders", String.parameter) { (routeParams: RouteParams, queryParams: QueryParams, respondWith: ([Order]?, RequestError?) -> Void) in
    if let param1 = routeParams.next(Int.self) {
        print("route param1 (int): \(param1)")
    }
    if let param2 = routeParams.next(String.self) {
        print("route param2 (str): \(param2)")
    }
    
    respondWith(orderStore.map({ $0.value }), nil)
}


///////////
///
// Authorization
///
//////////

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
