//
//  PowerAssertionController.swift
//  Barista
//
//  Created by Franz Greiling on 06.06.17.
//  Copyright © 2017 Franz Greiling. All rights reserved.
//

import Cocoa
import IOKit.pwr_mgt

class Assertion {
    
    // MARK: - Lifecycle
    convenience init() {
        self.init(enabled: false, preventDisplaySleep: false, timeout: 0)
    }
    
    init(enabled: Bool = true, preventDisplaySleep: Bool, timeout: UInt) {
        var aid = UInt32(kIOPMNullAssertionID)
        
        var props = Dictionary<String, CFTypeRef>()
        
        props[kIOPMAssertionNameKey]    = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! CFString
        props[kIOPMAssertionLevelKey]   = (enabled ? kIOPMAssertionLevelOn : kIOPMAssertionLevelOff) as CFNumber
        props[kIOPMAssertionTypeKey]    = (preventDisplaySleep ?
            kIOPMAssertionTypePreventUserIdleDisplaySleep : kIOPMAssertionTypePreventUserIdleSystemSleep) as CFString
        
        props[kIOPMAssertionTimeoutActionKey]   = kIOPMAssertionTimeoutActionTurnOff as CFTypeRef
        props[kIOPMAssertionTimeoutKey]         = timeout as CFNumber
        
        if IOPMAssertionCreateWithProperties(props as CFDictionary, &aid) != kIOReturnSuccess {
            fatalError("didn't expect this not to work")
        }
        
        self.id = aid
    }
    
    deinit {
        IOPMAssertionRelease(self.id)
    }
    
    
    // MARK: - Assertion Properties
    private var id: IOPMAssertionID
    
    var enabled: Bool {
        get {
            guard getAssertionProperty("AssertTimedOutWhen") == nil else { return false }
            return getAssertionProperty(kIOPMAssertionLevelKey) as! Int == kIOPMAssertionLevelOn
        }
        set(enabled) {
            let level = (enabled ? kIOPMAssertionLevelOn : kIOPMAssertionLevelOff) as CFNumber
            setProperty(kIOPMAssertionLevelKey, value: level)
        }
    }
    
    var preventDisplaySleep: Bool {
        get {
            return getAssertionProperty(kIOPMAssertionTypeKey) as! String == kIOPMAssertionTypePreventUserIdleSystemSleep
        }
        set(prevent) {
            // Type cannot be changed by just setting the property (bug?)
            // Workaround is to create a new Assertion with identical settings
            var props = IOPMAssertionCopyProperties(self.id).takeRetainedValue() as! Dictionary<String, CFTypeRef>
            props[kIOPMAssertionTypeKey] = (prevent ?
                kIOPMAssertionTypePreventUserIdleDisplaySleep : kIOPMAssertionTypePreventUserIdleSystemSleep) as CFString
            
            var aid = UInt32(kIOPMNullAssertionID)
            if IOPMAssertionCreateWithProperties(props as CFDictionary, &aid) != kIOReturnSuccess {
                fatalError("didn't expect this not to work")
            }
            
            IOPMAssertionRelease(self.id)
            self.id = aid
        }
    }
    
    var timeout: UInt {
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
            
            // Calculate timeLeft based on the value inside the assertion dict and the time that value was updated
            let lastValue = getAssertionProperty("AssertTimeoutTimeLeft") as! Int
            let timeUpdated = getAssertionProperty("AssertTimeoutUpdateTime") as! Date
            let timeLeft = lastValue + Int(timeUpdated.timeIntervalSinceNow)
            if timeLeft > 0 {
                return UInt(timeLeft)
            } else {
                return 0
            }
        }
    }
    
    var details: String {
        get {
            return getAssertionProperty(kIOPMAssertionDetailsKey) as! String
        }
        set(details) {
            setProperty(kIOPMAssertionDetailsKey, value: details as CFString)
        }
    }
    
    
    // MARK: - System Wide Assertions
    class func assertionsByProcess() -> Dictionary<Int, Array<Dictionary<String, Any>>>? {
        var assertionsByPID: Unmanaged<CFDictionary>?
        
        if IOPMCopyAssertionsByProcess(&assertionsByPID) != kIOReturnSuccess {
            fatalError("o.o")
        }
        
        return assertionsByPID?.takeRetainedValue() as? [Int: [[String: Any]]]
    }
    
    
    // MARK: - Helper
    private func getAssertionProperty(_ property: String) -> CFTypeRef? {
        let props = IOPMAssertionCopyProperties(self.id).takeRetainedValue() as! Dictionary<String, CFTypeRef>
        return props[property]
    }
    
    private func setProperty(_ property: String, value: CFTypeRef) {
        // TODO: Error Handling (Exceptions?)
        IOPMAssertionSetProperty(self.id, property as CFString, value)
    }
}
