//
//  Piping.swift
//  RouterExtension
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
    /// Piping
    ///
    
    class Input<I: Codable> {
        
        let closure: ((I?, String?) -> Void) -> Void
        
        func response(id: Int) -> I? {
            return nil
        }
        
        init(closure: @escaping ((I?, String?) -> Void) -> Void) {
            self.closure = closure
        }
    }
    
    class Chain<I: Codable, O: Codable> {
        
        let input: Input<I>
        
        let closure: (I, (O?, String?) -> Void) -> Void
        
        let respondWith = { (result: O?, error: String?) in
            
        }
        
        func response() -> O? {
            return nil //input.response(id: 1)
        }
        
        init(input: Input<I>, closure: @escaping ((I, (O?, String?) -> Void) -> Void)) {
            self.input = input
            self.closure = closure
        }
    }
}
