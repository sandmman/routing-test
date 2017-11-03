import Kitura
import KituraContracts
import RouterExtension
import Models

// Dictionay of Employee entities
var employeeStore: [Int: Employee] = [:]
var userStore: [Int: User] = [1: User(id: 1, name: "Mike"), 2: User(id: 2, name: "Chris"), 3: User(id: 3, name: "Ricardo")]

let router = Router()

router.get("/users") { (respondWith: ([User]?, RequestError?) -> Void) in
    print("GET on /users")
    respondWith(userStore.map({ $0.value }), nil)
}

router.get("/test") { (request: RouterRequest, response: RouterResponse, next: @escaping () -> Void) in
    let p = request.queryParameters
    let t = type(of: p)
    print(t)
}

router.get("/orders") { (queryParams: QueryParams, respondWith: ([User]?, RequestError?) -> Void) in
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


    // print("queryParams: \(queryParams)")
    // if let v1 = queryParams["t1"] {
    //     print("v1(str) = \(v1)")
    //     if let i = Int(v1) {
    //         print("i: \(i)")
    //     }
    // }
    // //queryParams["t1"]?.int
    // let t = String.self
    // let s = type(of: t)
    // print(s)
    respondWith(userStore.map({ $0.value }), nil)
}

// router.get("/users") { (queryParams: type, respondWith: ([User]?, RequestError?) -> Void) in
//     print("GET on /users")
//     respondWith(userStore.map({ $0.value }), nil)
// }

// Add an HTTP server and connect it to the router
Kitura.addHTTPServer(onPort: 8080, with: router)

// Start the Kitura runloop (this call never returns)
Kitura.run()
