import Kitura
import KituraContracts
import RouterExtension
import Models

// Dictionay of Employee entities
var employeeStore: [Int: Employee] = [:]
var userStore: [Int: User] = [1: User(id: 1, name: "Mike"), 2: User(id: 2, name: "Chris"), 3: User(id: 3, name: "Ricardo")]
var orderStore: [Int: Order] = [1: Order(id: 1, name: "order1"), 2: Order(id: 2, name: "order2"), 3: Order(id: 3, name: "order3")]

let router = Router()

router.get("/test") { (request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) in
    response.status(.OK)
    next()
}

router.get("/users") { (queryParams: QueryParams, respondWith: ([User]?, RequestError?) -> Void) in
    print("GET on /orders with query parameters")

    if let v1: String = queryParams["k1"].string {
        print("k1(str): \(v1)")
    }

    if let v1: Int = queryParams["k1"].int {
        print("k1(int): \(v1)")
    }

    if let v1: [String] = queryParams["k1"].stringArray {
        print("k1(strs): \(v1)")
    }

    if let v1: [Int] = queryParams["k1"].intArray {
        print("k1(ints): \(v1)")
    }

    if let v1: Test = queryParams["k1"].codable(Test.self) {
        print("k1(codable): \(v1)")
    }

    if let start = queryParams["start"].int, let end = queryParams["end"].int {
        print("start: \(start), end: \(end)")
    }

    respondWith(userStore.map({ $0.value }), nil)
}

router.get("/customers/:id1/orders/:id2") { (identifiers: [Int], respondWith: (Order?, RequestError?) -> Void) in
    print("GET on /orders with query parameters")
    print("identifiers: \(identifiers)")
    let order = orderStore[identifiers[1]]
    respondWith(order, nil)
}

// A possible approach for providing query params... though it seems cleaner to me to use QueryParams
router.get("route") { (queryParams: String..., respondWith: ([User]?, RequestError?) -> Void) in
    respondWith(userStore.map({ $0.value }), nil)
}

// A possible approach for URL parameters & codable
router.get("path1", Int.parameter, "path2", String.parameter) { (queryParams: QueryParams, respondWith: ([User]?, RequestError?) -> Void) in
    respondWith(userStore.map({ $0.value }), nil)
}

// Besides what we see above, we would also need an additional API method to address the need where we have
// queryParams and multiple identifiers...
// router.get("/objs1/:id1/objs2:id2") { (queryParams: QueryParams, identifiers: [Int], respondWith: ([O]?, RequestError?) -> Void) in

// Add an HTTP server and connect it to the router
Kitura.addHTTPServer(onPort: 8080, with: router)

// Start the Kitura runloop (this call never returns)
Kitura.run()
