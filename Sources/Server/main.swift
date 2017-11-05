import Kitura
import KituraContracts
import RouterExtension
import Models

// Dictionay of Employee entities
var employeeStore: [Int: Employee] = [:]
var userStore: [Int: User] = [1: User(id: 1, name: "Mike"), 2: User(id: 2, name: "Chris"), 3: User(id: 3, name: "Ricardo")]

let router = Router()

router.get("/test") { (request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) in
    let p = request.queryParameters
    let t = type(of: p)
    print(t)
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

    respondWith(userStore.map({ $0.value }), nil)
}

router.get("/customers/:id1/orders/:id2") { (identifiers: [Int], respondWith: (Order?, RequestError?) -> Void) in
    print("GET on /orders with query parameters")
    print("identifiers: \(identifiers)")
    let order = Order(id: identifiers[1])
    respondWith(order, nil)
}

// Add an HTTP server and connect it to the router
Kitura.addHTTPServer(onPort: 8080, with: router)

// Start the Kitura runloop (this call never returns)
Kitura.run()
