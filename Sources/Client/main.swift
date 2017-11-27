import Foundation
import Models
import Contracts
import Extensions

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

let testObj1: Test = try! JSONDecoder().decode(Test.self, from: json)
print("testObj1: \(testObj1)")

let testOb2: Test = Test(name: "testName")
let testType = type(of: testOb2)
let testObj3: Test = try! JSONDecoder().decode(testType.self, from: json)
print("testObj3: \(testObj3)")

//let anyType = testType as Any.Type
//let testObj4: Test = try! JSONDecoder().decode(anyType.self, from: json) // does not compile :-/
// http://inessential.com/2015/07/20/swift_diary_1_class_or_struct_from_str :-/
let clazz: AnyClass? = NSClassFromString("Models.AuthUser")
print("clazz = \(clazz!)")

let encoder = JSONEncoder()
struct Foo : Encodable {
    let date: Date
    let name: String = "fooName"
}

let foo = Foo(date: Date())
let data = try! encoder.encode(foo)
print("data: \(data)")
print("data: \(data)")

//A few points from my end.
//Let's take a look at the following code:

func func3(param: String) { }
func func4<A: CustomStringConvertible>(param: A) { 
    //print("size: \(param.count)") // this line won't compile as expected
}
func func5<A: CustomStringConvertible>(param: [A]) { print("size: \(param.count)") }
let a: [String] = ["h1", "h2", "h3"]
//func3(param: a)   // this won't compile, as expected (we are passing an array)
func4(param: a)     // this compiles, which I found it odd... I was expecting this to not compile
func5(param: a)     // this compiles as expected

// Let's now also look at this

// aliases
public typealias CodableResultClosure<O: Codable> = (O?, Error?) -> Void
public typealias CodableArrayResultClosure<O: Codable> = ([O]?, Error?) -> Void

// sample usage
func func1<O: Codable>(param1: String, closure: @escaping CodableResultClosure<O>) { }


func func2<O: Codable>(param1: String, closure: @escaping CodableArrayResultClosure<O>) { }

let closureA: (User?, Error?) -> Void = { (user, error) -> Void in
    // the code does not compile, as expected
    // if let users = users {
    //     print(users.count)
    // }
}

let closureB: ([User]?, Error?) -> Void = { (users, error) -> Void in
    // the code below compiles without having to cast to an array (as expected)
    if let users = users {
        print(users.count)
    }
}

func1(param1: "a string", closure: closureA)
func2(param1: "a string", closure: closureB)
//func2(param1: "a string", closure: closureA)  // this does not not compile, as expected
func1(param1: "a string", closure: closureB)    //this compiles (as the above example), which I find odd.


class MyTest {
    func get<O: Codable>(param1: String, closure: @escaping CodableResultClosure<O>) { }
    func get<O: Codable>(param1: String, closure: @escaping CodableArrayResultClosure<O>) { }
}

let myTest = MyTest()
myTest.get(param1: "", closure: closureA)
myTest.get(param1: "", closure: closureB)

let closureMirror = Mirror(reflecting: closureB)
print("closureMirror: \(closureMirror)")
print("closureMirror.children: \(closureMirror.children)")
//print("closureMirror.displayStyle: \(closureMirror.displayStyle)")
print("closureMirror.subjectType: \(closureMirror.subjectType)")

let url = URL(string: "http://user:password@localhost:8080")
print("url: \(url!)")
print("url: \(url!.user!)")
print("url: \(url!.password!)")

let userQuery = UserQuery(category: "category1", date: Date(), weight: 23.39, start: 10, end: 15)
let rawDict = userQuery.rawDictionary
print("rawDict: \(rawDict)")
print("string: \(userQuery.string)")
let blah: Any? = nil



struct MyQuery: Codable {
    let intField: Int
    let optionalIntField: Int?
    let stringField: String
    let intArray: [Int]
    let dateField: Date
    let optionalDateField: Date?
    let nested: Nested
}

struct Nested: Codable {
    let nestedIntField: Int
    let nestedStringField: String
}

// extension orm {
//     static func bing() {

//         let bing = self.CodingKeys.init(intValue: 10)
//         print(bing)
//     }
// }

// let nested = Nested(nestedIntField: 100, nestedStringField: "NestedString")
// let obj = orm(intField: 10, stringField: "String", nested: nested)

// print("==========Encoding==========")
// let data = try! MyEncoder().encode(obj)
// print("==========Decoding==========")
// let data2 = Data()
// let obj2 = try! MyDecoder.decode(orm.self, data: data2)
// print("============Done============")
// print(obj2.stringField)

let intArray: [Int] = [1,2,3]
let t = type(of: intArray)
print(t)

print("==========Decoding with dictionary (instead of data) ==========")
let dict: [String : String] = ["optionalIntField": "282", "intField": "23", "stringField": "a string", "intArray" : "1,2,3", "dateField" : "2017-10-31T16:15:56+0000", "optionalDateField" : "2017-10-31T16:15:56+0000", "nested": "{\"nestedIntField\":333,\"nestedStringField\":\"nested string\"}" ]
let obj3 = try! QueryDecoder.decode(MyQuery.self, dictionary: dict)
print("============Done============")
print(obj3)
print(obj3.intField)
print(obj3.stringField)
print(obj3.intArray)
print(obj3.dateField)
print(obj3.optionalDateField!)
print(obj3.optionalIntField!)
print(obj3.nested)

print("==========Encoding query object to dictionary ==========")
let retVal = try QueryEncoder().encode(obj3)
print("retVal (encoded): \(retVal)")
//QueryEncoder.xyz(obj3)
print("============Done============")