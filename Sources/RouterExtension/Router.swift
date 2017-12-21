import Kitura
import KituraContracts
import LoggerAPI
import Foundation
import Contracts

public protocol Params: Codable {
    // For simplicity, we need a default init method to work with reflection/encoders. There are ways of constructing default objects, but that requires a lot of resources/bloat. We could have an additional reflection package that gets imported. Then when swift addresses this problem we'll be able to remove it.
    init()
}


let routes: [String: (Codable, (Codable?, RequestError?) -> Void) -> Void] = [:]

extension Router {
    ///
    /// Swift Kuery Conformance
    ///
    
    // We need where `Q.QueryTable == M.table` This is currently unimplemented in swift kuery.
    public func get<Q: TableQuery, M: Model>(_ route: String, handler: @escaping (Q, @escaping CodableArrayResultClosure<M>) -> Void)  {
        getSafely(route, handler: handler)
    }

    // Get w/Query Parameters
    fileprivate func getSafely<Q: TableQuery, M: Model>(_ route: String, handler: @escaping (Q, @escaping CodableArrayResultClosure<M>) -> Void) {
        get(route) { request, response, next in
            Log.verbose("Received GET (plural) type-safe request with Query Parameters")
            // Define result handler
            let resultHandler: CodableArrayResultClosure<M> = { result, error in
                do {
                    if let err = error {
                        let status = self.httpStatusCode(from: err)
                        response.status(status)
                    } else {
                        response.status(.OK)
                        try response.send(result)
                    }
                } catch {
                    // Http 500 error
                    response.status(.internalServerError)
                }
                next()
            }
            Log.verbose("Query Parameters: \(request.queryParameters)")
            do {
                let query: Q = try QueryDecoder(dictionary: request.queryParameters).decode(Q.self)
                handler(query, resultHandler)
            } catch {
                // Http 400 error
                response.status(.badRequest)
                next()
            }
        }
    }

    ///
    /// Swift Kuery Agnostic Conformance
    ///

    public func get<Q: AgnosticTableQuery, M: Model>(_ route: String, handler: @escaping (Q, @escaping CodableArrayResultClosure<M>) -> Void)  {
        getSafely(route, handler: handler)
    }
    
    // Get w/Query Parameters
    fileprivate func getSafely<Q: AgnosticTableQuery, M: Model>(_ route: String, handler: @escaping (Q, @escaping CodableArrayResultClosure<M>) -> Void) {
        get(route) { request, response, next in
            Log.verbose("Received GET (plural) type-safe request with Query Parameters")
            // Define result handler
            let resultHandler: CodableArrayResultClosure<M> = { result, error in
                do {
                    if let err = error {
                        let status = self.httpStatusCode(from: err)
                        response.status(status)
                    } else {
                        response.status(.OK)
                        try response.send(result)
                    }
                } catch {
                    // Http 500 error
                    response.status(.internalServerError)
                }
                next()
            }
            Log.verbose("Query Parameters: \(request.queryParameters)")
            do {
                let query: Q = try QueryDecoder(dictionary: request.queryParameters).decode(Q.self)
                handler(query, resultHandler)
            } catch {
                // Http 400 error
                response.status(.badRequest)
                next()
            }
        }
    }

    ///
    /// Piping
    ///

    public func get<T: Codable, O: Codable>(_ route: String, from: String, handler: @escaping  (T, (O?, RequestError?) -> Void) -> Void) {
        //getSafely(route, handler: handler)
        get("") { request, response, error in
            
        }
    }

    /**
     get("/orders") { Params, ([Object]?, RequestError?) -> Void in
     
     
     }
    */
    
    ///
    /// Params
    ///

    public func get<P: Params, O: Codable>(_ route: String, handler: @escaping  (P, ([O]?, RequestError?) -> Void) -> Void) {
        getSafely(route, handler: handler)
    }

    public func getSafely<P: Params, O: Codable>(_ route: String, handler: @escaping (P, ([O]?, RequestError?) -> Void) -> Void) {
        // Construct parameter route for the user
        let actual_route = try? ParamEncoder().encode(P()) + route
        Log.verbose("Param Encoded route is: \(actual_route)")
        get(actual_route) { request, response, next in
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
            // Make param arrays compatible with query arrays
            let transformedParams = request.parameters.mapValues { $0.replacingOccurrences(of: "/", with: ",") }
            print(transformedParams)

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

