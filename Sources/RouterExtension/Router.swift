import Kitura
import KituraContracts
import LoggerAPI
import Foundation
import Contracts

public protocol Params: Codable {
    // For simplicity, we need a default init method to work with reflection/encoders. There are ways of constructing default objects, but that requires a lot of resources/bloat. We could have an additional reflection package that gets imported. Then when swift addresses this problem we'll be able to remove it.
    init()
}

extension Params {
    /**
     Method to create the route parameter string for the user
     We cannot use an Encoder because you cannot encode optional objects differently than non-optional. Unlike the decoder, the encoder's encodeIfPresent method has a guard statement that only checks if its nil or not. There is no additional configuration that we could get around. I think its possible for us to essentially override all of those 
     There might be way around this.
     
     Do optional params even make sense?
     
     
    */
    public static func createRoute() -> String {
        
        let emptyQuery = self.init()

        var route = ""
       
        let queryMirror = Mirror(reflecting: emptyQuery)
        for (name, value) in queryMirror.children {
            guard let name = name else { continue }
            Log.verbose("\(name): \(type(of: value)) = '\(value)'")
            let itemType = type(of: value)
            switch itemType {
            case is String.Type                     : route = route + "/" + "\(name)/:\(name)"
            case is Optional<String>.Type           : route = route + "/" + "\(name)/:\(name)?"
            case is Array<String>.Type              : route = route + "/" + "\(name)/:\(name)+"
            case is Optional<Array<String>>.Type    : route = "/" + "\(name)/:\(name)*"
            case is Int.Type                        : route = route + "/" + "\(name)/:\(name)(\\d+)"
            case is Optional<Int>.Type              : route = route + "/" + "\(name)/:\(name)(\\d+)?"
            case is Array<Int>.Type                 : route = route + "/" + "\(name)/:\(name)(\\d+)+"
            case is Optional<Array<Int>>.Type       : route = route + "/" + "\(name)/:\(name)(\\d+)*"
            default: print("NOOOO")
            }
        }
        return route
    }
}
extension Router {

    /**
     get("/orders") { Params, ([Object]?, RequestError?) -> Void in
     
     
     }
    */
    
    public func get<P: Params, O: Codable>(_ route: String, handler: @escaping  (P, ([O]?, RequestError?) -> Void) -> Void) {
        getSafely(route, handler: handler)
    }

    public func getSafely<P: Params, O: Codable>(_ route: String, handler: @escaping (P, ([O]?, RequestError?) -> Void) -> Void) {
        // Construct parameter route for the user
        let actual_route = P.createRoute() + route

        get(actual_route) { request, response, next in
            // Make param arrays compatible with query arrays
            let transformedParams = request.parameters.mapValues { $0.replacingOccurrences(of: "/", with: ",") }
            print(transformedParams)
            
            let resultHandler: CodableArrayResultClosure<O> = { result, error in
                do {
                    if let err = error {
                        let status = self.httpStatusCode(from: err)
                        response.status(status)
                    } else {
                        let encoded = try JSONEncoder().encode(result)
                        response.status(.OK)
                        response.send(data: encoded)
                    }
                } catch {
                    // Http 500 error
                    response.status(.internalServerError)
                }
                next()
            }
    
            /// We can share the decoder as long as we map fixup the values a little bit
            let params: P = try QueryDecoder(dictionary: transformedParams).decode(P.self)
            handler(params, resultHandler)
        }
    }

    public func get<O: Codable>(_ route: String, handler: (String..., ([O]?, RequestError?) -> Void) -> Void) {
        //getSafely(route, handler: handler)
    }

    /// router.get("users", Int.parameter, "orders", String.parameter) { (routeParams: RouteParams, queryParams: QueryParams, respondWith: ([Order]?, RequestError?) -> Void) in
    public func get<O: Codable>(_ routes: String..., handler: @escaping (RouteParams, QueryParams, ([O]?, RequestError?) -> Void) -> Void) {

        let route: String = routes.enumerated().map{ $0.element.first == ":" ? $0.element.insert(offset: $0.offset) : $0.element }.joined(separator: "/")
        Log.verbose("Computed route is: \(route)")

        get(route) { request, response, next in
            // Define result handler
            let resultHandler: CodableArrayResultClosure<O> = { result, error in
                do {
                    if let err = error {
                        let status = self.httpStatusCode(from: err)
                        response.status(status)
                    } else {
                        let encoded = try JSONEncoder().encode(result)
                        response.status(.OK)
                        response.send(data: encoded)
                    }
                } catch {
                    // Http 500 error
                    response.status(.internalServerError)
                }
                next()
            }
            Log.verbose("queryParameters: \(request.queryParameters)")
            let queryParameters = QueryParams(request.queryParameters)
            let routeParamKeys = Router.extractParams(from: route)
            let routeParams = RouteParams(keys: routeParamKeys, dict: request.parameters)
            handler(routeParams, queryParameters, resultHandler)
        }
    }

    // Simply pass the [String : String] dictionary in. Not type safe.
    public func get<O: Codable>(_ route: String, handler: @escaping ([String:String], ([O]?, RequestError?) -> Void) -> Void) {
        get(route) { request, response, next in
            Log.verbose("Received GET (plural) type-safe request")
            // Define result handler
            let resultHandler: CodableArrayResultClosure<O> = { result, error in
                do {
                    if let err = error {
                        let status = self.httpStatusCode(from: err)
                        response.status(status)
                    } else {
                        let encoded = try JSONEncoder().encode(result)
                        response.status(.OK)
                        response.send(data: encoded)
                    }
                } catch {
                    // Http 500 error
                    response.status(.internalServerError)
                }
                next()
            }
            handler(request.queryParameters, resultHandler)
        }
    }

    /// Identifier list
    public func get<Id: Identifier, O: Codable>(_ route: String, handler: @escaping ([Id], (O?, RequestError?) -> Void) -> Void) {
        
        let symbols = [":", "*", "+", "?"]

        // Separate into path components
        var components = route.components(separatedBy: "/").filter { !$0.isEmpty }
        var lastPathComponentExists: String? = nil
        
        // Last path component should be an :id
        if let last = route.last, !symbols.contains(String(last)) { lastPathComponentExists = components.popLast() }

        /// Param to type mapping
        var entities: [String: String] = [:]
        
        /// Map param to symbol
        for i in stride(from: 0, to: components.count, by: 2) {
            guard symbols.contains(components[i + 1]) else {
                Log.verbose("Invalid Component expected one of \(symbols) received '\(components[i + 1])'")
                return
            }
            entities[components[i]] = components[i + 1]
        }

        /// Create params
        let params = (0...(entities.count-1)).map({ (index: Int) -> String in
            return "id\(index)"
        })

        /// Combine into route
        let routeComponents = entities.enumerated().map { zip in
            return "\(zip.element.key)/:id\(zip.offset)\(zip.element.value != ":" ? zip.element.value : "")"
        }

        /// Join Routes
        var routeWithIds = "/" + routeComponents.joined(separator: "/")

        // Last path component is not an :ID
        if let component = lastPathComponentExists { routeWithIds += "/\(component)" }

        Log.verbose("routeWithIds: \(routeWithIds)")

        get(routeWithIds) { request, response, next in
            Log.verbose("HERE!!!! Received GET (plural) type-safe request")
            // Define result handler
            let resultHandler: CodableResultClosure<O> = { result, error in
                do {
                    if let err = error {
                        let status = self.httpStatusCode(from: err)
                        response.status(status)
                    } else {
                        let encoded = try JSONEncoder().encode(result)
                        response.status(.OK)
                        response.send(data: encoded)
                    }
                } catch {
                    // Http 500 error
                    response.status(.internalServerError)
                }
                next()
            }

            let identifiers: [Id] = params.map { request.parameters[$0]! }.map { try? Id(value: $0) }.filter { $0 != nil }.map { $0! }
            handler(identifiers, resultHandler)
        }
    }

    public func get<O: Codable, Q: Codable>(_ route: String, handler: @escaping (Q, ([O]?, RequestError?) -> Void) -> Void) {
        get(route) { request, response, next in
            Log.verbose("Received GET (plural) type-safe request")
            // Define result handler
            let resultHandler: CodableArrayResultClosure<O> = { result, error in
                do {
                    if let err = error {
                        let status = self.httpStatusCode(from: err)
                        response.status(status)
                    } else {
                        let encoded = try JSONEncoder().encode(result)
                        response.status(.OK)
                        response.send(data: encoded)
                    }
                } catch {
                    // Http 500 error
                    response.status(.internalServerError)
                }
                next()
            }
            Log.verbose("queryParameters: \(request.queryParameters)")
            //todo: add do try block
            let query: Q = try QueryDecoder(dictionary: request.queryParameters).decode(Q.self)
            handler(query, resultHandler)
        }
    }

    private static func extractParams(from route: String) -> [String] {
        //https://code.tutsplus.com/tutorials/swift-and-regular-expressions-swift--cms-26626
        let pattern = "/:([^/]*)(?:/|\\z)"
        // pattern is valid; hence we force unwrap next value
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let matches = regex.matches(in: route, options: [], range: NSRange(location: 0, length: route.count))
        let parameters: [String] = matches.map({ (value: NSTextCheckingResult) -> String in
            let range = value.range(at: 1)
            let start = route.index(route.startIndex, offsetBy: range.location)
            let end = route.index(start, offsetBy: range.length)
            // let parameter = String(route[start..<end])
            // let value = request.parameters[parameter] ?? ""
            // let identifier = try! Id(value: value)
            // return identifier
            //let _ = try! Id(value:value)
            return String(route[start..<end])
        })
        return parameters
    }
}

public class QueryParams {
    private let params: [String : String]
    public var count: Int {
        get { return params.count } 
    }
    public subscript(key: String) -> String? {
        let value: String? = params[key]
        return value
    }
    public init(_ params: [String : String]) {
        self.params = params
    }
}

public class RouteParams {
    private var iterator: IndexingIterator<Array<String>>

    init(keys: [String], dict: [String : String]) {
        let values = keys.map { dict[$0]! }
        self.iterator = values.makeIterator()
    }

    public func next<Id: Identifier>(_ type: Id.Type) -> Id? {
        guard let item = iterator.next() else {
            return nil
        }
        return try? Id(value: item)
    }
}

