//
//  PowerAssertionController.swift
//  Barista
//
//  Created by Franz Greiling on 06.06.17.
//  Copyright © 2017 Franz Greiling. All rights reserved.
//

import Cocoa
import IOKit.pwr_mgt

/// Well-known Dictionary Keys for assertion property dictionaries
private struct AssertionDictionaryKey {
    // The following cases are not described by IOPMKit but appear in the returned dictionaries
    static let AssertionTrueType = "AssertionTrueType"
    static let PID = "AssertPID"
    static let OnBehalfOfPID = "AssertionOnBehalfOfPID"
    static let ProcessName = "Process Name"
}

// MARK: -
class PowerAssertion: NSObject {
    private var id: IOPMAssertionID
    
    // MARK: -
    @objc dynamic var allowDisplaySleep: Bool {
        get {
            let type = getAssertionProperty(kIOPMAssertionTypeKey) as! String
            return type == kIOPMAssertionTypePreventUserIdleSystemSleep
        }
        set(allow) {
            // Type cannot be changed by just setting the property (bug?)
            // Workaround is to create a new Assertion with identical settings
            var props = IOPMAssertionCopyProperties(self.id).takeRetainedValue() as! Dictionary<String, CFTypeRef>
            props[kIOPMAssertionTypeKey] = (allow ?
                kIOPMAssertionTypePreventUserIdleSystemSleep : kIOPMAssertionTypePreventUserIdleDisplaySleep) as CFString
            
            var aid = UInt32(kIOPMNullAssertionID)
            if IOPMAssertionCreateWithProperties(props as CFDictionary, &aid) != kIOReturnSuccess {
                fatalError("didn't expect this not to work")
            }
            
            IOPMAssertionRelease(self.id)
            self.id = aid
        }
    }
    
    @objc dynamic var enabled: Bool {
        get {
            let val = getAssertionProperty(kIOPMAssertionLevelKey) as! Int
            return val == kIOPMAssertionLevelOn
        }
        set(enabled) {
            let level = (enabled ? kIOPMAssertionLevelOn : kIOPMAssertionLevelOff) as CFNumber
            setProperty(kIOPMAssertionLevelKey, value: level)
        }
    }
    
    // MARK: - Initalizers
    init(name: String, enabled: Bool, allowDisplaySleep: Bool) {
        var aid = UInt32(kIOPMNullAssertionID)
        
        let level = enabled ?
            kIOPMAssertionLevelOn : kIOPMAssertionLevelOff
        let type = allowDisplaySleep ?
            kIOPMAssertionTypePreventUserIdleSystemSleep : kIOPMAssertionTypePreventUserIdleDisplaySleep
        
        if IOPMAssertionCreateWithName(
            type as CFString,
            UInt32(level),
            name as CFString,
            &aid) != kIOReturnSuccess {
            fatalError("didn't expect this not to work")
        }
        
        self.id = aid
    }
    
    deinit {
        IOPMAssertionRelease(self.id)
    }
    
    // MARK: - Instance Methods
    fileprivate func getAssertionProperty(_ property: String) -> CFTypeRef? {
        let props = IOPMAssertionCopyProperties(self.id).takeRetainedValue() as! Dictionary<String, CFTypeRef>
        return props[property]
    }
    
    fileprivate func setProperty(_ property: String, value: CFTypeRef) {
        // TODO: Error Handling (Exceptions?)
        IOPMAssertionSetProperty(self.id, property as CFString, value)
    }
    
}

extension PowerAssertion {
    // MARK: - System Wide Assertion Status
    
}
