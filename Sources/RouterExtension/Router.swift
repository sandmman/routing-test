import Kitura
import KituraContracts
import LoggerAPI
import Foundation
import Contracts

public enum RouteSubPath<R: Route> {
    case literal(String)
    case stringParam(R)
    case intParam(Int)
}

public protocol SafeString: CustomStringConvertible {

}

public protocol Route: Codable { init() }

public protocol Params: Codable {}


let routes: [String: (Codable, (Codable?, RequestError?) -> Void) -> Void] = [:]

extension Router {

    ///
    /// 1a/1b --- Params
    ///
    
    public func get<P: Params, O: Codable>(_ route: String? = nil, handler: @escaping  (P, ([O]?, RequestError?) -> Void) -> Void) {
        getSafely(route ?? "", handler: handler)
    }
    
    public func getSafely<P: Params, O: Codable>(_ route: String, handler: @escaping (P, ([O]?, RequestError?) -> Void) -> Void) {
        
        guard let default_object = try? DefaultDecoder([:]).decode(P.self),
            let encoded_route = try? ParamEncoder().encode(default_object) else {
                return
        }
        
        Log.verbose("1a / 1b --- Param Encoded route is: \(encoded_route + route)")
        
        get(encoded_route + route) { request, response, next in
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
            
            /// We can share the decoder as long as we map fixup the values a little bit
            let params: P = try QueryDecoder(dictionary: transformedParams).decode(P.self)
            handler(params, resultHandler)
        }
    }

    /// 3a
    public func get<Id: Identifier, O: Codable>(_ route: String, handler: @escaping ([Id], (O?, RequestError?) -> Void) -> Void) {
        Log.verbose("3a - Codable GET with route params - \(route)")

        let entities: [String] = route.components(separatedBy: "/").filter { !$0.isEmpty }
        let params = (0...(entities.count-1)).map({ (index: Int) -> String in
            return "id\(index)"
        })
        let routeComponents = (0...(entities.count-1)).map({ (index: Int) -> String in
            return "\(entities[index])/:\(params[index])"
        })
        let routeWithIds = "/" + routeComponents.joined(separator: "/")
        Log.verbose("routeWithIds: \(routeWithIds)")

        get(routeWithIds) { request, response, next in
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

    /// 3b
    public func get<Id: Identifier, O: Codable>(_ route: String, handler: @escaping ([Id], ([O]?, RequestError?) -> Void) -> Void) {
        Log.verbose("3b - Codable GET with route params - \(route)")

        let entities: [String] = route.components(separatedBy: "/").filter { !$0.isEmpty }
        let params = (0...(entities.count-2)).map({ (index: Int) -> String in
            return "id\(index)"
        })
        let routeComponents = (0...(entities.count-2)).map({ (index: Int) -> String in
            return "\(entities[index])/:\(params[index])"
        })
        let routeWithIds = "/" + routeComponents.joined(separator: "/") + "/" + entities[entities.count - 1]
        Log.verbose("routeWithIds: \(routeWithIds)")

        get(routeWithIds) { request, response, next in
            Log.verbose("Received GET (plural) type-safe request...")
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

            let identifiers: [Id] = params.map { request.parameters[$0]! }.map { try? Id(value: $0) }.filter { $0 != nil }.map { $0! }
            handler(identifiers, resultHandler)
        }
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

    /// router.get("users", Int.parameter, "orders", String.parameter) { (routeParams: RouteParams, queryParams: QueryParams, respondWith: ([Order]?, RequestError?) -> Void) in
    public func get<O: Codable>(_ routes: String..., handler: @escaping ([String: Param], ([O]?, RequestError?) -> Void) -> Void) {

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
          _ = Router.extractParams(from: route)
            let routeParams: [String: Param] = request.parameters.reduce([String: Param]()) { (acc, value) in
                var acc = acc
                switch value.key.prefix(3) {
                case "str": acc[value.key] = Param(string: value.value, int: nil)
                case "int": acc[value.key] = Param(string: nil, int: Int(value.value))
                default: print("error"); acc[value.key] = Param(string: nil, int: nil)
                }
                return acc
            }
            handler(routeParams, resultHandler)
        }
    }

    /// router.get("users", Int.parameter, "orders", String.parameter) { (routeParams: RouteParams, queryParams: QueryParams, respondWith: ([Order]?, RequestError?) -> Void) in
    public func get<O: Codable>(_ routes: SafeString..., handler: @escaping (RouteParameters, ([O]?, RequestError?) -> Void) -> Void) {
        
        let dict: [String: String] = routes.enumerated().reduce([String: String]()) { accumulator, element in
            var accumulator = accumulator
            if element.offset % 2 == 1 {
                let prev = routes[element.offset - 1]
                accumulator[prev.description] = routes[element.offset].description
            } else {
                if routes.count - 1 == element.offset {
                    let prev = routes[element.offset - 1]
                    accumulator[prev.description] = "end_route"
                }
            }
            return accumulator
        }

        let route: String = routes.reduce("") { acc, element in
            let value = element.description
            guard let r: String = dict[value] else {
                return acc
            }

            return r.starts(with: ":") ? (acc + "/" + value + "/:" + value) : (acc + "/" + value)
            
        }

        Log.verbose("MY Computed route is: \(route)")

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

            let routeParams: [String: Param] = request.parameters.reduce([String: Param]()) { (acc, value) in
                var acc = acc
                guard let type = dict[value.key] else {
                    return acc
                }
                switch type {
                case ":string": acc[value.key] = Param(string: value.value, int: nil)
                case ":int": acc[value.key] = Param(string: nil, int: Int(value.value))
                default: print("error"); acc[value.key] = Param(string: nil, int: nil)
                }
                return acc
            }

            handler(RouteParameters(dict: routeParams), resultHandler)
        }
    }

    public func get<O: Codable>(_ routes: Typed..., handler: @escaping (RouteParameters, ([O]?, RequestError?) -> Void) -> Void) {
        let routes = routes.reduce([String]()) { acc, element in
            var acc = acc
            if element.myType.split(separator: ":").count != 0 {
                acc.append(contentsOf: element.myType.split(separator: ":").map { String($0) })
            } else {
                acc.append(element.myType)
            }
            return acc
        }
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
            let routeParamKeys = Router.extractParams(from: route)
            let routeParams: [String: Param] = request.parameters.reduce([String: Param]()) { (acc, value) in
                var acc = acc
                switch value.key.prefix(3) {
                case "str": acc[value.key] = Param(string: value.value, int: nil)
                case "int": acc[value.key] = Param(string: nil, int: Int(value.value))
                default: print("error"); acc[value.key] = Param(string: nil, int: nil)
                }
                return acc
            }
            handler(RouteParameters(dict: routeParams), resultHandler)
        }
    }

    public func get<O: Codable>(_ routes: RouteParam..., handler: @escaping (RouteParameters, ([O]?, RequestError?) -> Void) -> Void) {
        let route: String = routes.map { $0.description }.joined(separator: "/")
        Log.verbose("RouteParam Computed route is: \(route)")

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
            let routeParamKeys = Router.extractParams(from: route)
            let routeParams: [String: Param] = request.parameters.reduce([String: Param]()) { (acc, value) in
                var acc = acc
                switch value.key.prefix(3) {
                case "str": acc[value.key] = Param(string: value.value, int: nil)
                case "int": acc[value.key] = Param(string: nil, int: Int(value.value))
                default: print("error"); acc[value.key] = Param(string: nil, int: nil)
                }
                return acc
            }
            handler(RouteParameters(dict: routeParams), resultHandler)
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

public struct RouteParameters {
    private var dict: [String: Param]

    public init(dict: [String: Param]) {
        self.dict = dict
    }
  
    public subscript(_ index: SafeString) -> Int? {
      get {
        return dict[index.description]?.int
      }
    }
  
    public subscript(_ index: SafeString) -> String? {
      get {
        return dict[index.description]?.string
      }
    }
}
public struct Param {

    public var string: String?
    public var int: Int?

    init(string: String?, int: Int?){
        self.string = string
        self.int = int
    }
}

public enum RouteParam: CustomStringConvertible {
    case int(String)
    case string(String)
    case path(String)

    public var description: String {
        switch self {
        case .string(let str): return "\(str)/:string"
        case .int(let str): return "\(str)/:int"
        case .path(let str): return "\(str)"
        }
    }

    public var type: String {
        switch self {
        case .string(_): return "string"
        case .int(_): return "int"
        case .path(_): return "path"
        }
    }

    public var value: String {
        switch self {
        case .string(let str): return ":\(str)"
        case .int(let str): return ":\(str)"
        case .path(let str): return "\(str)"
        }
    }
}
