import Foundation
import Models
import Contracts
import Extensions
//import LoggerAPI

print("This is just a playground for trying things out...")

func xyz(input: Codable) {
    print("----------")
    print(input.self)
    print("----------")
}

func abc<I: Codable>(input: I) {
    print("----------")
    print(I.self)
    print("----------")
}

let user = User(id: 1234, name: "name")
print("----------")
print(user.self)
print("----------")
xyz(input: user)
abc(input: user)

let closure1: (_ p1: String, _ p2: Int) -> Void = { (p1, p2) -> Void in
    print("in closure... \(p1)")
}

let closure2 = { (p1: String, p2: Int) -> Void in
    print("in closure... \(p1)")
}

let closure3 = { (p1: String, p2: Int...) -> Void in
    print("in closure... \(p1)")
}

closure2("hello", 22)
closure3("hello", 22, 272, 2892)

func test(a1: String..., b1: Int, c1: Float) {
    //empty method
}

test(a1: "", "", "", b1: 1, c1: 2.3)
let routes: [String] = ["users", ":int", "orders", ":string"]
let route = "/" + routes.joined(separator: "/")
print("route: \(route)")

let json = """
{
 "name": "John Doe",
}
""".data(using: .utf8)! // our data in native (JSON) format

let testObj: Test = try! JSONDecoder().decode(Test.self, from: json)
print("testObj: \(testObj)")
 

//https://stackoverflow.com/questions/46327302/init-an-object-conforming-to-codable-with-a-dictionary-array/46327303#46327303
//https://makeitnew.io/reflection-in-swift-68a06ba0cf0e
//https://stackoverflow.com/questions/33776699/how-to-get-a-mirror-in-swift-without-creating-an-instance


func createQuery<Q: Query>(from rawParams: [String : String], queryType: Q.Type) throws -> Q {
    var transformedDictionary: [String : Any] = [:]
    let emptyQuery = queryType.init()
    let queryMirror = Mirror(reflecting: emptyQuery)
    for (name, value) in queryMirror.children {
        guard let name = name else { continue }
        guard let itemValue = rawParams[name] else { continue }
        print("\(name): \(type(of: value)) = '\(value)'")
        let itemType = type(of: value)
        switch itemType {
            // Ints
            case is Int.Type, is Optional<Int>.Type:
                transformedDictionary[name] = Int(itemValue)
            case is Array<Int>.Type, is Optional<Array<Int>>.Type:
                if let ints = itemValue.intArray {
                    transformedDictionary[name] = ints
                }
                // log warning
            // Strings
            case is String.Type, is Optional<String>.Type:
                transformedDictionary[name] = itemValue
            case is Array<String>.Type, is Optional<Array<String>>.Type:
                transformedDictionary[name] = itemValue.stringArray
            // Floats
            case is Float.Type, is Optional<Float>.Type:
                transformedDictionary[name] = Float(itemValue)
            case is Array<Float>.Type, is Optional<Array<Float>>.Type:
                if let floats = itemValue.floatArray {
                    transformedDictionary[name] = floats
                }
                // log warning
            // Doubles
            case is Double.Type, is Optional<Double>.Type:
                transformedDictionary[name] = Double(itemValue)
            case is Array<Double>.Type, is Optional<Array<Double>>.Type:
                if let doubles = itemValue.doubleArray {
                    transformedDictionary[name] = doubles
                }
                // log warning
            default:
                // log warning
                print("default: \(itemType)")
                transformedDictionary[name] = itemValue
        }
    }

    print("transformed dictionary: \(transformedDictionary)")
    if transformedDictionary.count != rawParams.count {
        print("warning.... query parameters provided to the route were not used...")
    }
    let jsonData: Data = try JSONSerialization.data(withJSONObject: transformedDictionary)
    let query: Q = try JSONDecoder().decode(Q.self, from: jsonData)
    return query
}

let rawParams: [String : String] = ["id" : "71791791", "name" : "john doe", "counts": "3,4,5,6,7"]
let query: QueryTest = try createQuery(from: rawParams, queryType: QueryTest.self)
print("query: \(query)")