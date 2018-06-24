//
//  UserAssertion.swift
//  Barista
//
//  Created by Franz Greiling on 26.11.17.
//  Copyright © 2018 Franz Greiling. All rights reserved.
//

import Cocoa
import IOKit.pwr_mgt

class UserAssertion {
    private(set) var aid: IOPMAssertionID

    // MARK: - Lifecycle
    private init?(name: CFString, level: CFNumber, type: CFString, timeout: CFNumber, details: CFString) {
        var id = UInt32(kIOPMNullAssertionID)
        var props = Dictionary<String, CFTypeRef>()
        
        props[kIOPMAssertionNameKey]            = name
        props[kIOPMAssertionLevelKey]           = level
        props[kIOPMAssertionTypeKey]            = type
        props[kIOPMAssertionTimeoutActionKey]   = kIOPMAssertionTimeoutActionTurnOff as CFTypeRef
        props[kIOPMAssertionTimeoutKey]         = timeout
        props[kIOPMAssertionDetailsKey]         = details
        
        guard IOPMAssertionCreateWithProperties(props as CFDictionary, &id) == kIOReturnSuccess else {
            return nil
        }
        
        self.aid = id
    }
    
    deinit {
        IOPMAssertionRelease(aid)
    }
    
    static func createAssertion(withName name: String, timeout: UInt, thatPreventsDisplaySleep: Bool = false) -> UserAssertion? {
        return UserAssertion(
            name: name as CFString,
            level: kIOPMAssertionLevelOn as CFNumber,
            type: (thatPreventsDisplaySleep ? kIOPMAssertionTypePreventUserIdleDisplaySleep : kIOPMAssertionTypePreventUserIdleSystemSleep) as CFString,
            timeout: timeout as CFNumber,
            details: UserAssertion.makeDetailsString(timeout, thatPreventsDisplaySleep) as CFString)
    }
    
    // MARK: - Properties
    private(set) var enabled: Bool {
        get {
            guard getAssertionProperty("AssertTimedOutWhen") == nil else { return false }
            guard let lvl = getAssertionProperty(kIOPMAssertionLevelKey) as? Int else { return false }
            return lvl == kIOPMAssertionLevelOn
        }
        set(enabled) {
            let level = (enabled ? kIOPMAssertionLevelOn : kIOPMAssertionLevelOff) as CFNumber
            setProperty(kIOPMAssertionLevelKey, value: level)
        }
    }
    
    var preventsDisplaySleep: Bool = true {
        didSet {
            // Type cannot be changed by just setting the property (bug?)
            // Workaround is to create a new Assertion with identical settings
            var props = IOPMAssertionCopyProperties(aid).takeRetainedValue() as! Dictionary<String, CFTypeRef>
            props[kIOPMAssertionTypeKey] = (preventsDisplaySleep ?
                kIOPMAssertionTypePreventUserIdleDisplaySleep : kIOPMAssertionTypePreventUserIdleSystemSleep) as CFString
            props[kIOPMAssertionDetailsKey] = UserAssertion.makeDetailsString(timeout, preventsDisplaySleep) as CFString
            
            var newId = UInt32(kIOPMNullAssertionID)
            guard IOPMAssertionCreateWithProperties(props as CFDictionary, &newId) == kIOReturnSuccess  else {
                return
            }
            
            IOPMAssertionRelease(aid)
            self.aid = newId
        }
    }
    
    private(set) var timeout: UInt {
        get {
            return getAssertionProperty(kIOPMAssertionTimeoutKey) as! UInt
        }
        set(timeout) {
            setProperty(kIOPMAssertionTimeoutKey, value: timeout as CFNumber)
        }
    }
    
    var timeLeft: UInt? {
        get {
            guard self.timeout != 0 else { return nil }
            guard self.enabled else { return nil }
            
            // Calculate timeLeft based on the value inside the assertion dict
            // and the time that value was updated
            let lastValue = getAssertionProperty("AssertTimeoutTimeLeft") as! Int
            let timeUpdated = getAssertionProperty("AssertTimeoutUpdateTime") as! Date
            return UInt(lastValue + Int(timeUpdated.timeIntervalSinceNow))
        }
    }
    
    var timeStarted: Date {
        get {
            return getAssertionProperty("AssertStartWhen") as! Date
        }
    }
    

    // MARK: - Helper
    fileprivate static func makeDetailsString(_ time: UInt, _ preventsDisplaySleep: Bool) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .short
        
        let s = preventsDisplaySleep ? "Preventing display sleep" :"Preventing sleep"
        let t = (time == 0) ? "forever" : "for \(formatter.string(from: Double(time))!)"
        
        return "\(s) \(t)"
    }
    
    fileprivate func getAssertionProperty(_ property: String) -> CFTypeRef? {
        let props = IOPMAssertionCopyProperties(self.aid).takeRetainedValue() as! Dictionary<String, CFTypeRef>
        return props[property]
    }
    
    fileprivate func setProperty(_ property: String, value: CFTypeRef) {
        // TODO: Error Handling (Exceptions?)
        IOPMAssertionSetProperty(self.aid, property as CFString, value)
    }
}
