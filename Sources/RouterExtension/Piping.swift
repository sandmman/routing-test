//
//  Piping.swift
//  RouterExtension
//
//  Created by Aaron Liberatore on 1/15/18.
//

import Kitura
import KituraContracts
import LoggerAPI
import Foundation
import Contracts

// This works to a depth of 2
/*
public typealias CodableResultClosure<O: Codable> = (O?, String?) -> Void

public typealias CodableClosure<I: Codable, O: Codable> = (I, @escaping CodableResultClosure<O>) -> Void

class Pipe<I: Codable, O: Codable> {

  let parent: Pipe<String, I>?

  let closure: CodableClosure<I, O>

  let pattern: String

  func response(id: I, respondWith: @escaping (O?, String?) -> Void) {
    closure(id, respondWith)
  }

  init(pattern: String, parent: Pipe<String, I>? = nil, closure: @escaping CodableClosure<I, O>) {
    self.parent = parent
    self.closure = closure
    self.pattern = pattern
  }
}

var pipes = [String: Any]()

func codableResultClosure<O: Codable>() -> CodableResultClosure<O> {
  return { output, error in
    print("Sending", output, error)
  }
}

func get<O: Codable>(_ route: String, id: String, handler: @escaping CodableClosure<String, O>) {
  let respondWith: CodableResultClosure<O> = codableResultClosure()
  let pipe = Pipe(pattern: route, closure: handler)
  pipes[route] = pipe

  /// Below this is inside the router.get()
  handler(id, respondWith)
}

//"users/:id0/blog/:id1"
func get<I: Codable, O: Codable>(_ route: String, handler: @escaping CodableClosure<I, O>) {

  // Create a new pipe
  pipes[route] = Pipe(pattern: route, closure: handler)

  // Get subroute
  let route = route.split(separator: "/").dropLast(2).joined(separator: "/")

  /// Below this is inside the router.get()

  /// Take this from route parameters
  let id = "Aaron"
  let respondWith: CodableResultClosure<O> = codableResultClosure()

  if let pipe = pipes[route] as? Pipe<String, I> {

    pipe.response(id: id) { (input: I?, error: String?) in
      if let i = input {
        handler(i, respondWith)
      } else {
        respondWith(nil, "ERROR: Could not get input")
      }
    }

  } else {
    respondWith(nil, "ERROR: No input object")
  }
}

struct Blog: Codable {
  let name: String
  let author: String
}
struct User: Codable  {
  let name: String
}

let users: [User] = [User(name: "Aaron"), User(name: "Carl"), User(name: "Gelerah")]
let blogs: [Blog] = [Blog(name: "Dino Blog", author: "Gelareh"),
                     Blog(name: "Swift Blog", author: "Carl"),
                     Blog(name: "Runners World", author: "Aaron")]

get("users/:id0", id: "Aaron") { (id: String, respondWith: (User?, String?) -> Void) in
  let u = users.first { $0.name == id }
  respondWith(u, nil)
}

get("users/:id0/blog/:id1") { (user: User, respondWith: (Blog?, String?) -> Void) in
  let blog = blogs.first { $0.author == user.name }
  respondWith(blog, nil)
}

get("users/:id0/blog/:id1/pages/:id2") { (blog: Blog, respondWith: (String?, String?) -> Void) in
  let name = blog.name
  respondWith(name, nil)
}
*/
