import Kitura
import KituraContracts
import LoggerAPI
import Foundation

extension Router {
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
            print(request.queryParameters)
            let queryParameters = QueryParams(request.queryParameters)
            handler(queryParameters, resultHandler)
        }
    }

    public func get<O: Codable>(_ route: String, handler: @escaping (Identifier..., ([O]?, RequestError?) -> Void) -> Void) {
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

            let id = request.parameters["id"] ?? ""
            //https://code.tutsplus.com/tutorials/swift-and-regular-expressions-swift--cms-26626
           let pattern1 = "\\/(:.+)/"
            let pattern2 = "\\/(:.+)$"
            let str = "/users/:id1/orders/:id2"
            let regex = try! NSRegularExpression(pattern: pattern1, options: [])
            let matches = regex.matches(in: str, options: [], range: NSRange(location: 0, length: str.characters.count))
            print(matches.count)
            let r: String = route
            
           // handler(resultHandler)
        }
    }
}

public struct ParamValue {
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
        let obj: T? = try? JSONDecoder().decode(type, from: data)
        return obj
     }

    public init(_ rawValue: String?) {
        self.rawValue = rawValue
    }
}

public struct QueryParams {
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
