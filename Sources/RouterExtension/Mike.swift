import Kitura
import KituraContracts
import LoggerAPI
import Foundation
import Contracts


public protocol Instantiatable {
    init(fromKeyDict: [PartialKeyPath<Self>: Any]) throws
}
public protocol ParamType {}

public struct InstantiationError: Error {}

extension String: ParamType {}
extension Int: ParamType {}

public struct MyParams: Codable, Instantiatable {
    public let name: String
    public let id: Int
    
    public init(name: String, id: Int) {
        self.name = name
        self.id = id
    }

    public init(fromKeyDict keydict: [PartialKeyPath<MyParams>: Any]) throws {
        guard let name = keydict[\MyParams.name] as? String,
            let id = keydict[\MyParams.id] as? Int
            else {
                throw InstantiationError()
        }
        self.name = name
        self.id = id
    }
}

public enum RoutePart<ParamStruct: Codable & Instantiatable> {
    case literal(String)
    case stringParam(KeyPath<ParamStruct, String>)
    case intParam(KeyPath<ParamStruct, Int>)
}

extension Router {
    private func createRoute<ParamStruct>(_ parts: [RoutePart<ParamStruct>]) -> (String, [PartialKeyPath<ParamStruct>: Any]) {
        var route = [""]
        var values: [PartialKeyPath<ParamStruct>: Any] = [:]
        for part in parts {
            switch part {
            case .literal(let literal):
                route.append(literal)
            case .stringParam(let keypath):
                route.append(":string(\(keypath))");
                values[keypath] = "example"
            case .intParam(let keypath):
                route.append(":int(\(keypath))");
                values[keypath] = 1
            }
        }
        
        return (route.joined(separator: "/"), values)
    }

    public func get<ParamStruct, O: Codable>(_ parts: RoutePart<ParamStruct>..., handler: @escaping (ParamStruct, (O?, RequestError?) -> ()) -> ()) {
        let (route, values) = createRoute(parts)
        
        Log.verbose("Instantiating GET with route parameters: \(route)")

        /// One of [ (, ), ., <, >] is altering the route from what is expected
        get(route) { request, response, next in
            let resultHandler: CodableResultClosure<O> = { result, error in
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
    
            do {
                let params = try ParamStruct.init(fromKeyDict: values)
                handler(params, resultHandler)
            } catch {
                print("error in route")
            }
        }
    }
}
