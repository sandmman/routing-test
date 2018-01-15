//
//  SwiftKuery.swift
//  Kitura-Next
//
//  Created by Aaron Liberatore on 1/15/18.
//

import Kitura
import KituraContracts
import LoggerAPI
import Foundation
import Contracts

extension Router {
    
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
    /// Swift Kuery Conformance
    ///
    
    // We need where `Q.QueryTable == M.table` This is currently unimplemented in swift kuery.
    public func get<Q: TableQuery, M: Model>(_ route: String, handler: @escaping (Q, @escaping CodableArrayResultClosure<M>) -> Void) where Q.QueryTable == M.QueryTable  {
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
    /// 2 - This just uses the necessary decoder- otherwise the same
    ///
    
    // We need where `Q.QueryTable == M.table` This is currently unimplemented in swift kuery.
    public func get<Q: TableKuery, M: Model>(_ route: String, handler: @escaping (Q, @escaping CodableArrayResultClosure<M>) -> Void) where Q.QueryTable == M.QueryTable  {
        getSafely(route, handler: handler)
    }
    
    // Get w/Query Parameters
    fileprivate func getSafely<Q: TableKuery, M: Model>(_ route: String, handler: @escaping (Q, @escaping CodableArrayResultClosure<M>) -> Void) {
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
                let query: Q = try KueryDecoder(dictionary: request.queryParameters).decode(Q.self)
                handler(query, resultHandler)
            } catch {
                // Http 400 error
                response.status(.badRequest)
                next()
            }
        }
    }
}
