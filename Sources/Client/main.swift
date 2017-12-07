import Foundation
import Models
import Contracts
import Extensions
import KituraKit
import KituraContracts
import KituraKitExtensions

let order = Order(id: 1234, name: "myorder")


let client = KituraKit(baseURL: "http://localhost:8080")!

let group = DispatchGroup()

group.enter()

/// Should fail becuase it is unauthorized
client.post("/orders", data: order) { (order: Order?, error: RequestError?) in
  assert(error != nil)
  print("\nUnauthorized should fail: ", error!)
  group.leave()
}

group.enter()

/// Should pass because it is authorized -- the authorize method at the moment saves the authorization globally. So it is not required to be called again from here
client.authorize(user: "john", password: "pwd1").post("/orders", data: order) { (order: Order?, error: RequestError?) in
  guard let order = order else {
    print(error!)
    return
  }
  print("\nNon Symmetric Auth API\nOrder Received: \(order)")
  group.leave()
}


group.enter()

/// An example Symmetric Api
client.authorize(user: "john", password: "pwd1").get("/orders") { (user: AuthUser?, order: [Order]?, error: RequestError?) in
  print("\nAuthorized Symmetric", "\nUser: ", user ?? "nil", "\nOrders: ", order ?? "nil", "\nError: ", error ?? "nil")
  assert(user != nil)
  assert(order != nil)
  assert(error == nil)
  group.leave()
}

group.enter()

/// This will fail because the endpoint is not returning a user object. Definitely a problem.
client.get("/basic") { (user: AuthUser?, users: [Order]?, error: RequestError?) in
  print("\nAuthorized API Should Fail with non symmetric server route", "\nError: ", error ?? "nil")
  assert(error != nil)
}

group.wait()

