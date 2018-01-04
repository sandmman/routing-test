import Foundation
import Kitura
import KituraContracts
import Contracts
import RouterExtension
import Models
import LoggerAPI
import HeliumLogger
import Credentials
import CredentialsHTTP
import SwiftKuery
import SwiftKueryPostgreSQL

let connection = PostgreSQLConnection(host: "", port: 8080, options: nil)
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
 
 // 1. this is a route itself..
 router.get("customer") { Identifier, respondWith(Customer, RequestError) in
 
 }
 
 // 2. this is chained to route 1. This takes its respondWith checks for an error underneath and passes the custom on if it exists
 /// Problem...How do we guarantee the customer route exists
 router.get("orders", for: "customer") { customer: Customer, respondWith([Order], RequestError) in

}
 
 // 3. this is chained to route 1. This takes its respondWith checks for an error underneath and passes the custom on if it exists
 /// Problem...How do we guarantee the customer route exists
 router.get("order", for: "customer") { Identifier, Customer, respondWith(Order, RequestError) in
 
 }
 */
router.get("/user") { (id: Int, respondWith: (User?, RequestError?) -> Void) in
    print("users")
    respondWith(userStore[1], nil)
}

// Could be interesting, but its likely limited and I'm not sure how this could be done.
router.get("/orders", from: "user") { (user: User, respondWith: ([Order]?, RequestError?) -> Void) in
    print("orders")
    respondWith([], nil)
}

////
/// Instantiate your Params Object
//  Since we do not have a way to look at the field types before instantiate we need a user to instantiate a default version for us.
//  How should optional params work?
//
struct Parameters: Params {

    let int: Int?
    let string: String
    let stringArray: [String]

    init() {
        self.int = nil
        self.string = ""
        self.stringArray = []
    }
}

// 1a.
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
// Arrays:
// 1. Exclude preliminary tag "/string/:string/stringArray/:stringArray+/orders" --> /string/:string/orders
// 2. Keep tag and simply use * identifier "/string/:string/stringArray/:stringArray*/orders" --> /string/:string/orders
// I lean towards the second, but would like input
// Non-Arrays
// 1. Exclude preliinary tag in the middle? Lots of weird edge cases
//
//
//// Less clarity in a way
//
// "/int/:int(\\d+)?/string/:string/stringArray/:stringArray+/orders"
//  localhost:8080/int/1/string/string/stringArray/abc/def/ghi/orders
//  localhost:8080/int/string/string/stringArray/abc/def/ghi/orders
 router.get("/orders") { (params: Parameters, respondWith: ([Order]?, RequestError?) -> Void) in
    print("GET on /orders with inferred route parameters")
    print("parameters: \(params)")
    respondWith([], nil)
 }

//// 1b. Route Definition with internal route customization
struct MyRoute: Route {
    let startofroute: BaseRoute // Could be replaced with a string/identifier _startofroute or optional BaseRoute
    let int: Int?
    let middleofroute: BaseRoute
    let string: String
    let stringArray: [String]
    let endofroute: BaseRoute
    
    init() {
        self.int = nil
        self.string = ""
        self.stringArray = []
        (startofroute, middleofroute, endofroute) = (BaseRoute(), BaseRoute(), BaseRoute())
    }
}

//// 1b. Enables internal customization of routes with all the benifits provided by 1a.
router.get { (route: MyRoute, /* queryParams: MyQuery,*/ respondWith: ([Order]?, RequestError?) -> Void) in
    print("GET on /orders with inferred route parameters")
    print("parameters: \(route)")
    respondWith([], nil)
}

// 2 - Identifier style with flaws
// A possible implementation for multiple URL route params - codable
// Developer does not need to specify the identifiers for each entity in the path
// Instead, we infer them - assumption is that because it is a codable route then identifiers should be assigned/generated for each entity
// Though these is a hole in this approach... it assumes that an identifier is needed for the last element in the path... which may or may not be the case
// dependending on the use case :-/ -- We can get around this by defining some symbol that the user must use. Perhaps if the last path component ends in a /
// then that has an id. Otherwise, it doesn't
//
// This should be improved to enable ?, +, *, :id
// We could be explicit "/customers/*/orders/:" --> "/customers/:id0*/orders/:id1"
//                      "/customers/*/orders" --> "/customers/:id0*/orders"
// Partially inferred   "/customers*/orders/" --> "/customers/:id0*/orders/:id1"
//                      "/customers*/orders" --> "/customers/:id0*/orders"
//
// This uses the explicit method
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

// 4 - Non type - safe. Vapor style
// Another possible approach for URL route parameters & codable
// We could also provide route params and query params as this: Params.route, Params.query
// Now... if we were to take this approach, I am then thinking  we should change the new codable API we just released... so that the route is specified in the same
// way we do below...
// localhost:8080/users/1234/orders/1VZXY3/entity/4398/entity2/234r234 - think more from an API perspecitve as opposed to thinking of it in terms of URL
router.get("users", [Int].parameter, "orders", String.parameter) { (routeParams: RouteParams, queryParams: QueryParams, respondWith: ([Order]?, RequestError?) -> Void) in
    if let param1 = routeParams.next(Int.self) {
        print("route param1 (int): \(param1)")
    }
    if let param2 = routeParams.next(String.self) {
        print("route param2 (str): \(param2)")
    }
    
    respondWith(orderStore.map({ $0.value }), nil)
}

// 4 - Non type - safe. Vapor style
// Another possible approach for URL route parameters & codable
// We could also provide route params and query params as this: Params.route, Params.query
// Now... if we were to take this approach, I am then thinking  we should change the new codable API we just released... so that the route is specified in the same
// way we do below...
// localhost:8080/users/1234/orders/1VZXY3/entity/4398/entity2/234r234 - think more from an API perspecitve as opposed to thinking of it in terms of URL
/*
 router.get() { (users: Int, orders: String, entity: String, respondWith: ([Order]?, RequestError?) -> Void) in
    respondWith(orderStore.map({ $0.value }), nil)
}
*/


/// 5.
/// We can do something like this..
/// I did this real quick, but the real version could use the actual parameter name :testing, :orders etc.
router.get("testing", Int.parameter, "orders", String.parameter) { (params: [String: Param], respondWith: ([Order]?, RequestError?) -> Void) in
    if let int = params["int0"]?.int {
        print("Int", int)
    }
    if let string = params["string1"]?.string {
        print("String", string)
    }
    respondWith(orderStore.map({ $0.value }), nil)
}


//// 6

router.get("six", Int.parameter, "test", String.parameter) { (params: RouteParamDict, respondWith: ([Order]?, RequestError?) -> Void) in
    print("Six")
    if let int: Int = params["int0"] {
        print("Int", int)
    }
    if let string: String = params["string1"] {
        print("String", string)
    }
    respondWith(orderStore.map({ $0.value }), nil)
}

router.get(.int("seven"), .string("test")) { (params: RouteParamDict, respondWith: ([Order]?, RequestError?) -> Void) in
    print("Seven")
    if let int: Int = params["int"] {
        print("Int", int)
    }
    if let string: String = params["string"] {
        print("String", string)
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

struct Test: Codable {
    let int: Int
}

 public func tester<T: Decodable>(_ type: T.Type) -> Bool {
    
    switch type {
    case is Test.Type: return true
    default: return false
    }
    
}
print(tester(Test.self))
///////////
///
// ORM Integration
///
//////////

/**
 
 Select(grades.course, round(avg(grades.grade), to: 1).as("average"), from: grades)
 .group(by: grades.course)
 .having(avg(grades.grade) > 90)
 .order(by: .ASC(avg(grades.grade)))
 
 */

/// Define Tables
public class GradesTable: Table {
    let tableName = "grades"
    let key = Column("key")
    let course = Column("course")
    let grade = Column("grade")
    let studentId = Column("studentId")
}


/// Instantiate Tables
let grades = GradesTable()

/// Standard Queries
public struct GradesQuery: KituraContracts.Query {
    public let minGrade: Int = 1
}

/// Define Routes

///
/// New API
///

/// This is how it would currently be used. The user defines their table and then in their route handler
/// takes the table query (query params) and inserts it into their query
router.get("/specialorders") { (params: GradesQuery, respondWith: ([Order]?, RequestError?) -> Void) in
    print("hello: retrieving special order: \(params.minGrade)")

    let query = Select(grades.course, grades.grade, from: grades).having(avg(grades.grade) > params.minGrade)

    connection.execute(query: query) { result in
    
    }
}

/// User Defined ORM Model
class Student: Model {
    /// Currently the ORM Model uses a string to mark the table
    //static var tableName = "table"
    
    /// If we change it to a specific type then we can ensure greater type safety
    static var tableName: GradesTable.Type = GradesTable.self
}

///
/// Newer API - ORM
///

/// Overarching Considerations
/**
    1. Is the Kordata Model actually the table or does it point to the table object. I would like the Model protocol to reference the Table object
        directly if possible, so the Query object and the ORM object can be guaranteed to be referencing the same one, but I suppose we can
        get close with strings if we keep the current state.
 
    2. API-wise, there are two paths: The reflection/encoder path where the ORM will figure out what the query object is actually
        looking for or the explicit definition/transform path where the ORM simply takes and transforms protocol definited values
        I'm not sure of the time complexity of reflection but its definitely slower.
 
    3. Readability vs. typesafety. In my examples, (hopefully they inspire better ideas) they range from high readability/usability to high safety, but neither is completely both. :(
 
    4. Where do these things live? If the model points to a Table.Type we might have an issue as Kitura/Swift Kuery become coupled. We'd have to consider the layout a little more closely.
 
    5. It seems to me as though there should be 2 Query Param protocols: something like a standard one `QueryParams` and for Kordata `TableQuery`.
        People not using swift kuery wont want the extra bloat and vice versa.
 
    Currently Example #2 below is my favorite.
 */


///
/// Example 1
///

/// Upsides
//  - Increased typesafety: assuming we can match tables and map to table fields
//  Downsides
//  - Personally, seeing the operation before its left/right operands is annoying
//  - The user has to define the whole query computed property separately. Could it be done in one step?
public struct Grades: TableQuery {
    
    public static let table: GradesTable = GradesTable()

    // Define the query fields
    public let minGrade: Int //.lessThan(minGrade, "grade")
    
    /// Developer defines relationships

    /// The String column denotion will be replaced by a field directly from the associated typed table. This requies making a bunch of
    /// stuff codable in SwiftKuery. I'm mildly worried about the default value Any that is stored in the Column
    /// In the future, it could simple be - .lessThan(Int, table.Field)
    // Django uses a Blog.objects.get(name__iexact='beatles blog')
    public var query: [WhereCondition] {
       return [.lessThan(minGrade, "grade"), .greaterThan(100, "highest")]
    }

}

// Problems:
// 1. I feel as though Grades and Student should be requried to point to the same table. They can't because Model.tableName is a string not usable in the method signature where clause. I've converted this to an associatedtype referencing the Table.Type. Now Grades/Student refer to the same table at compile time
// 2. Assuming point 1, in the TableQuery, the enum should map to the table fields directly .lessThan(70, table.grade). SwiftKuery Field has to be codable, but it currently isn't and will require lots of modifications.
router.get("/students") { (params: Grades, respondWith: ([Student]?, RequestError?) -> Void) in
    print("Retrieving grades for students where: \(params.query)")
    
    guard let students = try? Student.findAll(where: params) else {
        respondWith(nil, .internalServerError)
        return
    }
    
    respondWith(students, nil)
}

///
/// Example 2
///

/// We define a set of accepted operations
/// The field name of the Query object designates the table field
/// The type designates the operation
/// The value remains as the value

/// Upsides:
/// - It's by far the easiest to read and understand
/// - It's much safer than the django version (Example 4)
/// - The ORM filter can just ignore any unrecognized types (In the Encoder or while Reflecting)
/// Downsides:
/// - No guarantee that the field name exists in the table

/// Note: this requires modifying the Query Encoder and Decoder. Currently KueryDecoder.swift under contracts is what we'd need
public struct TypeAliasGrades: TableKuery {
    
    public static let table: GradesTable = GradesTable()
    
    // Define the query fields
    public let test: Int
    public let grade: GreaterThan<Int>
    public let highest: LessThan<String>
    
}

router.get("/typeAliasStudents") { (params: TypeAliasGrades, respondWith: ([Student]?, RequestError?) -> Void) in
    print("Retrieving grades for students where: \(params)")
    
    /// The ORM reflects/decodes the params object and converts to where clause. Boom.
    guard let students = try? Student.findAll(where: params) else {
        respondWith(nil, .internalServerError)
        return
    }
    
    respondWith(students, nil)
}

///
/// Example 3
///

// Still a work in progress. It has lots of flaws, so I moved on quickly
// This is what it might look like if we forget about directly mapping to a table. (Decreasing type safety)
// In the agnostic version. We can only guarantee the query and the orm model use the same table name
// but we can't be sure at compile time that they are using appropriate field names. (might not exist)
// the beneift thought is that kitura doesnt have it import swiftkuery or vice versa
public struct AgnosticGrades: AgnosticTableQuery {
    
    public static let table = "student"
    
    /// Something like this could be used
    /// no guarantee that grade is a part of table
    /// I stioll need to figure out how we could require .lessThan and "grade" and take the value from the url
    /// Seems to me that it would turn towards #2 style quickly
    public let minimumGrade: WhereCondition = .lessThan(70, "grade")
    
}

router.get("/agnosticStudents") { (params: AgnosticGrades, respondWith: ([Student]?, RequestError?) -> Void) in
    print("Retrieving grades for students where: \(params.minimumGrade)")
    
    guard let students = try? Student.findAll(where: params) else {
        respondWith(nil, .internalServerError)
        return
    }
    
    respondWith(students, nil)
}

///
/// Example 4 (Django Style)
///

/// In this style we discern the field name from the variables through reflection/decoder. Keywords after __ denote
/// the operation and of course the value is the value
/// I didn't fully implement this because it requires reworking the QueryDecoder, QueryDecoder
/// to recognize/ignore symbols after the __. Lots of work haha.
/// Upsides:
//     - Simplish to implement, to use, and is clear as anything
// Downsides
//      - Effectively 0 typesafety. We can perhaps guarantee the ORM and Query reference the same table, but the fields can be anything.
//        We can throw on bad extension names as well, but nothing is done at compile time
public struct DjangoGrades: DjangoTableQuery {
    
    public static let table = "student"
    
    public let grade__gt: Int
    public let grade__lt: Int
    
}


////
////
////
////
////

// Add an HTTP server and connect it to the router
Kitura.addHTTPServer(onPort: 8080, with: router)

// Start the Kitura runloop (this call never returns)
Kitura.run()
