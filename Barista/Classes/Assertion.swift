//
//  AppAssertion.swift
//  Barista
//
//  Created by Franz Greiling on 28.01.18.
//  Copyright © 2018 Franz Greiling. All rights reserved.
//

import Foundation


// MARK: - Assertion Struct
struct Assertion {
    let aid: IOPMAssertionID
    let preventsDisplaySleep: Bool
    let details: String?
    let timeStarted: Date
    let timeout: UInt
    
    var timeLeft: UInt? {
        guard self.timeout > 0 else { return nil }
        return UInt(Int(self.timeout) + Int(self.timeStarted.timeIntervalSinceNow))
    }
    
    init?(dict: [String: Any]) {
        self.aid = dict["AssertionId"] as! IOPMAssertionID
        self.details = dict[kIOPMAssertionDetailsKey] as? String
        self.timeStarted = (dict["AssertStartWhen"] as? Date)!
        self.timeout = UInt((dict[kIOPMAssertionTimeoutKey] as? Int) ?? 0)
        
        guard let s = dict["AssertionTrueType"] as? String else { return nil }
        
        var pds = false
        switch s {
        case "PreventUserIdleDisplaySleep":
            pds = true
        case "PreventUserIdleSystemSleep": break
        default:
            // We don't care about other assertion types atm
            pds = false
        }
        
        self.preventsDisplaySleep = pds
    }
}
