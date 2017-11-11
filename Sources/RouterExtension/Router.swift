import Kitura
import KituraContracts
import LoggerAPI
import Foundation
import Contracts

// Notes: Only a single variadic parameter '...' is permitted
extension Router {

    public func get<O: Codable>(_ route: String, handler: (String..., ([O]?, RequestError?) -> Void) -> Void) {
        //getSafely(route, handler: handler)
    }

    public func get<O: Codable>(_ routes: String..., handler: @escaping (RouteParams, QueryParams, ([O]?, RequestError?) -> Void) -> Void) {
        let route = "/" + routes.joined(separator: "/")
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
            let routeParamKeys = self.extractParams(from: route)
            let routeParams = RouteParams(keys: routeParamKeys, dict: request.parameters)
            handler(routeParams, queryParameters, resultHandler)
        }
    }

    public func get<O: Codable>(_ route: String, handler: @escaping (QueryParams, ([O]?, RequestError?) -> Void) -> Void) {
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
            let queryParameters = QueryParams(request.queryParameters)
            handler(queryParameters, resultHandler)
        }
    }

    public func get<Id: Identifier, O: Codable>(_ route: String, handler: @escaping ([Id], (O?, RequestError?) -> Void) -> Void) {
        get(route) { request, response, next in
            Log.verbose("Received GET (plural) type-safe request")
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

            let params = self.extractParams(from: route)
            let identifiers: [Id] = params.map { request.parameters[$0]! }.map { try! Id(value: $0) }
            handler(identifiers, resultHandler)
        }
    }

    public func get<O: Codable, Q: Query>(_ route: String, handler: @escaping (Q, ([O]?, RequestError?) -> Void) -> Void) {
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
            let query: Q = try self.createQuery(from: request.queryParameters , queryType: Q.self)
            handler(query, resultHandler)
        }
    }

    private func extractParams(from route: String) -> [String] {
        //https://code.tutsplus.com/tutorials/swift-and-regular-expressions-swift--cms-26626
        let pattern = "/:([^/]*)(?:/|\\z)"
        // pattern is valid; hence we force unwrap next value
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let matches = regex.matches(in: route, options: [], range: NSRange(location: 0, length: route.characters.count))
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

public class ParamValue {
    private let rawValue: String?

    public var string: String? {
        get { return rawValue}
     }

    public var stringArray: [String]? {
         get { return rawValue?.components(separatedBy: ",") }
     }

    public var int: Int? {
        get {
            guard let rawValue = rawValue else {
                return nil
            }            
            return Int(rawValue)
        }
    }

    public var intArray: [Int]? {
         get { 
            if let strs: [String] = rawValue?.components(separatedBy: ",") {
                let ints: [Int] = strs.map { Int($0) }.filter { $0 != nil }.map { $0! }
                if ints.count == strs.count {
                    return ints
                }
            }
            return nil
        }
     }

    public func codable<T: Codable>(_ type: T.Type) -> T? {
        guard let rawValue = rawValue else {
            return nil
        } 
        guard let data = rawValue.data(using: .utf8) else {
            return nil
        }

        print("rawValue: \(rawValue)")
        let obj: T? = try? JSONDecoder().decode(type, from: data)
        return obj
     }

    public var float: Float? {
        get {
            guard let rawValue = rawValue else {
                return nil
            }            
            return Float(rawValue)
        }
    }

    public var double: Double? {
        get {
            guard let rawValue = rawValue else {
                return nil
            }            
            return Double(rawValue)
        }
    }

    public var floatArray: [Float]? {
         get { 
            if let strs: [String] = rawValue?.components(separatedBy: ",") {
                let floats: [Float] = strs.map { Float($0) }.filter { $0 != nil }.map { $0! }
                if floats.count == strs.count {
                    return floats
                }
            }
            return nil
        }
     }

    public var boolean: Bool? {
        get {
            guard let rawValue = rawValue else {
                return nil
            }            
            return Bool(rawValue)
        }
    }

    public var doubleArray: [Double]? {
         get { 
            if let strs: [String] = rawValue?.components(separatedBy: ",") {
                let doubles: [Double] = strs.map { Double($0) }.filter { $0 != nil }.map { $0! }
                if doubles.count == strs.count {
                    return doubles
                }
            }
            return nil
        }
     }


    public init(_ rawValue: String?) {
        self.rawValue = rawValue
    }
}

public class QueryParams {
    private let params: [String : String]
    public var count: Int {
        get { return params.count } 
    }
    public subscript(key: String) -> ParamValue {
        let value = params[key]
        return ParamValue(value)
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

extension String {
    public static var parameter: String {
        get {
            return ":string"
        }
    }
}

extension Int {
    public static var parameter: String {
        get {
            return ":int"
        }
    }

}
