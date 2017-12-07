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

client.authorize(user: "john", password: "pwd1").post("/orders", data: order) { (order: Order?, error: RequestError?) in
  guard let order = order else {
    print(1, error!)
    return
  }

  print("Order: \(order)")
  group.leave()
}

group.enter()

/// Should fail
client.post("/orders", data: order) { (order: Order?, error: RequestError?) in
  guard let order = order else {
    print(2, error!)
    return
  }
  
  print("Order2: \(order)")
  group.leave()
}

group.enter()

client.authorize(user: "john", password: "pwd1").get("/orders") { (user: AuthUser?, order: [Order]?, error: RequestError?) in
  print("")
  print("Authorized Symmetric")
  print("User: ", user ?? "nil")
  print("Orders: ", order ?? "nil")
  print("Error: ", error ?? "nil")
}

group.wait()

