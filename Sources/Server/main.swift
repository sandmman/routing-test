import Foundation
import Kitura
import KituraContracts
import RouterExtension
import Models
import LoggerAPI
import HeliumLogger

// HeliumLogger disables all buffering on stdout
HeliumLogger.use(LoggerMessageType.verbose)

// Dictionay of Employee entities
var employeeStore: [Int: Employee] = [1: Employee(serial: 1, name: "John"), 2: Employee(serial: 2, name: "Peter")]
var userStore: [Int: User] = [1: User(id: 1, name: "Mike"), 2: User(id: 2, name: "Chris"), 3: User(id: 3, name: "Ricardo")]
// Dictionary of Order entities
var orderStore: [Int: Order] = [1: Order(id: 1, name: "order1"), 2: Order(id: 2, name: "order2"), 3: Order(id: 3, name: "order3")]

let router = Router()

// Traditional routing style (nothing new here)
router.get("/basic") { (request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) in
    print("basic")
    response.status(.OK)
    next()
}

// A possible implementation for query params
// Codable routing with type-safe LIKE query parameters
// This even supports Codable as a value assigned to a key in a query parameter
// If we don't go with this approach for the Codable APIs, I am still thinking we should consider adding
// this QueryParams functionality to the traditional routing API (see next example below)
// localhost:8080/users?category=animal&percentage=65&tags=tag1&tags=tag2&weights=32&weights=34&object=%7B"name":"john"%7D&start=100&end=400
router.get("/users") { (queryParams: QueryParams, respondWith: ([User]?, RequestError?) -> Void) in
    print("GET on /orders with query parameters")

    if let category: String = queryParams["category"]?.string {
        print("category(str): \(category)")
    }

    if let percentage: Int = queryParams["percentage"]?.int {
        print("percentagek1(int): \(percentage)")
    }

    if let tags: [String] = queryParams["tags"]?.stringArray {
        print("tags(strs): \(tags)")
    }

    if let weights: [Int] = queryParams["weights"]?.intArray {
        print("weights(ints): \(weights)")
    }

    if let object: Test = queryParams["object"]?.codable(Test.self) {
        print("object(codable): \(object)")
    }

    if let start = queryParams["start"]?.int, let end = queryParams["end"]?.int {
        print("start: \(start), end: \(end)")
    }

    respondWith(userStore.map({ $0.value }), nil)
}

// Traditional routing style with enchancements to query parameters
// Very similar to approach as above but using non-codable API with new enhanced query parameters
// localhost:8080/employees?category=animal&percentage=65&tags=tag1&tags=tag2&weights=32&weights=34&object=%7B"name":"john"%7D&start=100&end=400
router.get("/employees") { (request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) in
    print("Traditional non-codable APIs with enhanced query parameters...")
    let queryParams = request.queryParameters
    if let category: String = queryParams["category"]?.string {
        print("category(str): \(category)")
    }

    if let percentage: Int = queryParams["percentage"]?.int {
        print("percentagek1(int): \(percentage)")
    }

    if let tags: [String] = queryParams["tags"]?.stringArray {
        print("tags(strs): \(tags)")
    }

    if let weights: [Int] = queryParams["weights"]?.intArray {
        print("weights(ints): \(weights)")
    }

    if let object: Test = queryParams["object"]?.codable(Test.self) {
        print("object(codable): \(object)")
    }

    if let start = queryParams["start"]?.int, let end = queryParams["end"]?.int {
        print("start: \(start), end: \(end)")
    }

    let employees = employeeStore.map({ $0.value })
    response.status(.OK).send(employees)
    next()
}

// Another possible approach for providing query params... though it seems cleaner to use QueryParams (see above).
// More than likely we won't take this route
router.get("route") { (queryParams: String..., respondWith: ([User]?, RequestError?) -> Void) in
    // FYI: this is not prototyped...
    respondWith(userStore.map({ $0.value }), nil)
}

// Another possible implementation for query params. This one uses a concrete type that the developer must implement.
// This concrete type must conform to the Query Protocol
// Thhis approach is closer to what we consider type-safe to be.
// However due to limitations in the reflection API in Swift, the developer must make all the fields in the 
// Query class optional. 
//localhost:8080/xyz?category=manager&weight=65&start=100&end=400&date=2017-10-31T16:15:56%2B0000
router.get("/xyz") { (query: UserQuery, respondWith: ([User]?, RequestError?) -> Void) in
    print("In xyz with UserQuery")
    if let category: String = query.category {
        print("category = \(category)")
    }
	
    if let date: Date = query.date {
        print("date = \(date)")
    }
	
    if let weight: Float = query.weight {
        print("weight = \(weight)")
    } 

    if let start: Int = query.start {
        print("start = \(start)")
    }

    if let end: Int = query.end {
        print("end = \(end)")
    }

    respondWith(userStore.map({ $0.value }), nil)
}

// A possible implementation for multiple URL route params - codable
// Developer does not need to specify the identifiers for each entity in the path
// Instead, we infer them - assumption is that because it is a codable route then identifiers should be assigned/generated for each entity
// localhost:8080/customers/3233/orders/1432
router.get("/customers/orders") { (identifiers: [Int], respondWith: (Order?, RequestError?) -> Void) in
    print("GET on /orders with inferred route parameters")
    print("identifiers: \(identifiers)")
    let order = orderStore[identifiers[1]]
    respondWith(order, nil)
}

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

// Note for self: Besides what we see above, we would also need an additional API method to address the need where we have queryParams and multiple identifiers...
// router.get("/objs1/:id1/objs2:id2") { (queryParams: QueryParams, identifiers: [Int], respondWith: ([O]?, RequestError?) -> Void) in

// A codable approach for authentication (inspired by code from cbailey @ https://github.com/seabaylea/CodableAuth)
// john:pwd1@localhost:8080/authenticatedPost
router.post("/authenticatedPost") { (authUser: AuthUser, order: Order, respondWith: (Order?, RequestError?) -> Void) in
    print("Valid credentials must have been provided if we see this output.")
    print("UserProfile.id: \(authUser.id)")
    print("UserProfile.provider: \(authUser.provider)")
    print("UserProfile.displayName: \(authUser.displayName)")
    print("extendend properties: \(String(describing: authUser.xyz))")
    print("Order: \(order)")
    respondWith(order, nil)
}

// Add an HTTP server and connect it to the router
Kitura.addHTTPServer(onPort: 8080, with: router)

// Start the Kitura runloop (this call never returns)
Kitura.run()
