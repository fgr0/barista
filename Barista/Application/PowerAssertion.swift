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
    
    // MARK: - Properties
    @objc dynamic var allowDisplaySleep: Bool {
        get {
            return getAssertionProperty(kIOPMAssertionTypeKey) as! String == kIOPMAssertionTypePreventUserIdleSystemSleep
        }
        set(allow) {
            // Update Details
            self.details = PowerAssertion.makeDetailsString(displaySleep: allow, time: self.timeout)
            
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
            return getAssertionProperty(kIOPMAssertionLevelKey) as! Int == kIOPMAssertionLevelOn
        }
        set(enabled) {
            let level = (enabled ? kIOPMAssertionLevelOn : kIOPMAssertionLevelOff) as CFNumber
            setProperty(kIOPMAssertionLevelKey, value: level)
        }
    }
    
    @objc dynamic var timeout: Int {
        get {
            return getAssertionProperty(kIOPMAssertionTimeoutKey) as! Int
        }
        set(timeout) {
            self.details = PowerAssertion.makeDetailsString(displaySleep: self.allowDisplaySleep, time: timeout)
            guard timeout >= 0 else { return }
            setProperty(kIOPMAssertionTimeoutKey, value: timeout as CFNumber)
        }
    }
    
    private var details: String {
        get {
            return getAssertionProperty(kIOPMAssertionDetailsKey) as! String
        }
        set(details) {
            setProperty(kIOPMAssertionDetailsKey, value: details as CFString)
        }
    }
    
    // MARK: - Life Cycle
    convenience override init() {
        self.init(enabled: false, allowDisplaySleep: false, timeout: 0)
    }
    
    init(enabled: Bool, allowDisplaySleep: Bool, timeout: Int) {
        var aid = UInt32(kIOPMNullAssertionID)
        
        let name = "\(Bundle.main.object(forInfoDictionaryKey: "CFBundleName")!) Menubar Application" as CFString
        let level = (enabled ? kIOPMAssertionLevelOn : kIOPMAssertionLevelOff) as CFNumber
        let type = (allowDisplaySleep ?
            kIOPMAssertionTypePreventUserIdleSystemSleep : kIOPMAssertionTypePreventUserIdleDisplaySleep) as CFString
        
        var props = Dictionary<String, CFTypeRef>()
        props[kIOPMAssertionNameKey] = name
        props[kIOPMAssertionLevelKey] = level
        props[kIOPMAssertionTypeKey] = type
        props[kIOPMAssertionTimeoutActionKey] = kIOPMAssertionTimeoutActionTurnOff as CFTypeRef
        props[kIOPMAssertionTimeoutKey] = timeout as CFNumber
        props[kIOPMAssertionDetailsKey] = PowerAssertion.makeDetailsString(
            displaySleep: allowDisplaySleep, time: timeout) as CFString
        
        if IOPMAssertionCreateWithProperties(props as CFDictionary, &aid) != kIOReturnSuccess {
            fatalError("didn't expect this not to work")
        }
        
        self.id = aid
    }
    
    deinit {
        IOPMAssertionRelease(self.id)
    }
    
    // MARK: - Helper
    fileprivate func getAssertionProperty(_ property: String) -> CFTypeRef? {
        let props = IOPMAssertionCopyProperties(self.id).takeRetainedValue() as! Dictionary<String, CFTypeRef>
        return props[property]
    }
    
    fileprivate func setProperty(_ property: String, value: CFTypeRef) {
        // TODO: Error Handling (Exceptions?)
        IOPMAssertionSetProperty(self.id, property as CFString, value)
    }
    
    fileprivate class func makeDetailsString(displaySleep: Bool, time: Int) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        
        let s = displaySleep ? "Preventing sleep" : "Preventing display sleep"
        let t = (time == 0) ? "forever" : "for \(formatter.string(from: Double(time))!)"
        
        return "\(s) \(t)"
    }
}
