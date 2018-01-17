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
struct MyOrder: Codable {
    let id: Int
    let ingredients: [Ingredient]
}

struct Ingredient: Codable {
    let id: Int
    let name: String
}

let orders = [1: MyOrder(id: 1, ingredients: [Ingredient(id: 0, name: "pesto"),
                                              Ingredient(id: 1, name: "pasta"),
                                              Ingredient(id: 2, name: "chicken")])
             ]

func handler(id: Int, respondWith: (MyOrder?, RequestError?) -> Void) {
    print("Handler: MyOrder \(orders[id]!)")
    respondWith(orders[id], nil)
}

func handler2(order: MyOrder, respondWith: ([Ingredient]?, RequestError?) -> Void) {
    print("Handler2: MyOrder \(order)")
    respondWith(order.ingredients, nil)
}

func handler3(id: Int, order: MyOrder, respondWith: (Ingredient?, RequestError?) -> Void) {
    print("Handler3: MyOrder \(order)")
    respondWith(order.ingredients.filter { $0.id == id }.first, nil)
}

router.chainedGet("/pipe_order/:id", handler: handler)

router.chainedGet("/pipe_order/:id/ingredients", handler: handler2)

router.chainedGet("/pipe_order/:id0/ingredients/:id1", handler: handler3)

////
/// Instantiate your Params Object
//  Since we do not have a way to look at the field types before instantiate we need a user to instantiate a default version for us.
//  How should optional params work?
//
struct Parameters: Params {

    let int: Int
    let string: String
    let stringArray: [String]

}

// 0
// Mike's initial prototype
//
//
// Likes
//  - We return a codable object
//  - Our params are binded to that object
//  - The route construction is more easily accessible that 1a and 1b
// Dislikes
//  - You aren't required to use all the values in the params object, which will potentially make it fail on initialization or be wrongfully instantiated to avoid it.
// - Id really like create the route without have to specifiy 'literal'. I haven't been able to find a solution to this.
//
/// users/:string/blog/:id
router.get(.literal("users"), .stringParam(\MyParams.name), .literal("blog"), .intParam(\MyParams.id)) { (params: MyParams, respondWith: (Int?, RequestError?) -> Void) in
    print("Mike's:", params)
}

// 1a.
// http://localhost:8080/int/3233/string/my_string/stringArray/str1/str2/str3/orders
// A possible implementation for multiple URL route params using codable
// This approach abstracts the parameter definitions from the user. It autogenerates the route url.
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

// 1b.
// Route Definition with internal route customization
struct MyRouteParameters: Params {
    let startofroute: Literal // Could be replaced with a string/identifier _startofroute or optional BaseRoute
    let int: Int?
    let middleofroute: Literal
    let string: String
    let stringArray: [String]
    let endofroute: Literal
}

// Enables internal customization of routes with all the benifits provided by 1a.
router.get { (params: MyRouteParameters, respondWith: ([Order]?, RequestError?) -> Void) in
    print("GET on /orders with inferred route parameters")
    print("parameters: \(params)")
    respondWith([], nil)
}

// 1c.

// Enables internal customization of routes with all the benifits provided by 1a.
router.get("literal", .int(\.int)) { (params: Parameters, respondWith: ([Order]?, RequestError?) -> Void) in
    print("GET on /orders with inferred route parameters")
    print("parameters: \(params)")
    respondWith([], nil)
}

// 2a
// A possible implementation for multiple URL route params - codable
// Developer does not need to specify the identifiers for each entity in the path
// Instead, we infer them - assumption is that because it is a codable route then identifiers should be assigned/generated for each entity
// We can infer that the last element in the route does require an identifier because the respondWidth closure receives a single Codable object.
// localhost:8080/customers/1/orders/1
router.get("/two/orders") { (identifiers: [Int], respondWith: (Order?, RequestError?) -> Void) in
    let order = orderStore[identifiers[1]]
    respondWith(order, nil)
}

// 2b
// A possible implementation for multiple URL route params - codable. This goes in hand with the sample above.
// Developer does not need to specify the identifiers for each entity in the path
// Instead, we infer them - assumption is that because it is a codable route then identifiers should be assigned/generated for each entity, except the last
// one. The last identity in this case is plural, hence no identifier.
// We can infer that the last element in the route does NOT require an identifier because the respondWidth closure receives an array of Codable objects.
// localhost:8080/guests/1/orders
router.get("/two/orders") { (identifiers: [Int], respondWith: ([Order]?, RequestError?) -> Void) in
     print("GET on /orders with inferred route parameters")
     // In this case, we should have ONLY one identifier in the array...
     print("identifiers: \(identifiers)")
     respondWith(orderStore.map({ $0.value }), nil)
}

// 3 - Non type - safe. Vapor style
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

/// 4.
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


//// 5
/// An implementation of RouteParams that utilizes a Dictionary wrapper
/// The route api is interchangable, so the key difference here is the dicitonary wrapper
/// it will take the string parameter name and the user can then specify the overrided type
//// http://localhost:8080/five/1/test/testString
extension String: SafeString {}
public enum Prms: SafeString {
    case five
    case test
    
    public var description: String {
        switch self {
        case .five: return "five"
        case .test: return "test"
        }
    }
}


router.get(Prms.five, Int.parameter, Prms.test, String.parameter) { (params: RouteParameters, respondWith: ([Order]?, RequestError?) -> Void) in
    guard let int: Int = params[Prms.five],
          let string: String = params[Prms.test] else {
            
            respondWith(nil, .badRequest)
            return
    }
    
    print("MyInt", int)
    print("MyString", string)
    
    respondWith(orderStore.map({ $0.value }), nil)
}





/// 6

router.get(.int("seven"), .string("test"), .path("orders")) { (params: RouteParameters, respondWith: ([Order]?, RequestError?) -> Void) in
    if let int: Int = params["int"] {
        print("Int", int)
    }
    if let string: String = params["string"] {
        print("String", string)
    }
    respondWith(orderStore.map({ $0.value }), nil)
}

/// 9

/*
router.get(RouteParam.int("eight"), RouteParam.string("test"), "orders") { (params: RouteParameters, respondWith: ([Order]?, RequestError?) -> Void) in
    if let int: String = params["int"] {
        print("Int", int)
    }
    if let string: String = params["string"] {
        print("String", string)
    }
    respondWith(orderStore.map({ $0.value }), nil)
}
*/

//// APIs

/// Top Level
// 1. router.get("/orders") { params: User
// 2. router.get { params: UserWithPaths
// 3. router.get("/customers/*/orders")
// 4. router.get("/customers/:customer/orders/:orders")
// 5. router.get("six", Int.parameter, "test", String.parameter)
// 6. router.get(.intParam("seven"), .stringParam("test"), "orders")

/// Internal
// 1. params.integerParam
// 2. let id = identifiers[1]
// 3. let int = routeParams.next(Int.self)
// 4. let string = params["string1"]?.string
// 5. let string: String = params["string"]

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


// Add an HTTP server and connect it to the router
Kitura.addHTTPServer(onPort: 8080, with: router)

// Start the Kitura runloop (this call never returns)
Kitura.run()
