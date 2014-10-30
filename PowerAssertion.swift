//
//  Assertion.swift
//  Barista
//
//  Created by Franz Greiling on 28/10/14.
//  Copyright (c) 2014 Franz Greiling. All rights reserved.
//

import Foundation

import IOKit.pwr_mgt


enum PowerAssertionType: String {
    case PreventUserIdleSystemSleep = "PreventUserIdleSystemSleep",
    PreventUserIdleDisplaySleep = "PreventUserIdleDisplaySleep",
    PreventSystemSleep = "PrevenSystemSleep",
    NoIdleSleep = "NoIdleSleepAssertion",
    NoDisplaySleep = "NoDisplaySleepAssertion"
}

enum PowerAssertionDictionaryKey: String {
    case AssertionTimeoutKey = "TimeoutSeconds",
    AssertionTimeoutActionKey = "TimeoutAction",
    AssertionTimeoutActionLog = "TimeoutActionLog",
    AssertionTimeoutActionTurnOff = "TimeoutActionTurnOff",
    AssertionTimeoutActionRelease = "TimeoutActionRelease",
    AssertionRetainCountKey = "RetainCount",
    AssertionNameKey = "AssertName",
    AssertionDetailsKey = "Details",
    AssertionHumanReadableReasonKey = "HumanReadableReason",
    AssertionLocalizationBundlePathKey = "BundlePath",
    AssertionFrameworkIDKey = "FrameworkBundleID",
    AssertionPlugInIDKey = "PlugInBundleID",
    AssertionTypeKey = "AssertType",
    AssertionLevelKey = "AssertLevel"
}

enum PowerAssertionLevel: UInt32 {
    case On = 255,
    Off =   0
}


/// Wrapper around the IOPMlib C-API
class PowerAssertion {
    
    private var assertionID: IOPMAssertionID = UInt32(kIOPMNullAssertionID)
    
    /*
    *  Wrapper around the AssertionDictionary Values
    */
    var name: String {
        get {
            return getAssertionProperty(.AssertionNameKey)! as String
        }
        set(name) {
            setAssertionProperty(.AssertionNameKey, theValue: name)
        }
    }
    
    var type: PowerAssertionType {
        get {
            return PowerAssertionType(rawValue: getAssertionProperty(.AssertionTypeKey)! as String)!
        }
    }
    
    var level: PowerAssertionLevel {
        get {
            return PowerAssertionLevel(rawValue: UInt32(getAssertionProperty(.AssertionLevelKey)! as Int))!
        }
        set(level) {
            setAssertionProperty(.AssertionLevelKey, theValue: NSNumber(unsignedInt: level.rawValue))
        }
    }
    
    var details: String? {
        get {
            return getAssertionProperty(.AssertionDetailsKey) as String?
        }
        set(details) {
            setAssertionProperty(.AssertionDetailsKey, theValue: details)
        }
    }
    
    var humanReadableReason: String? {
        get {
            return getAssertionProperty(.AssertionHumanReadableReasonKey) as String?
        }
        set(hRString) {
            setAssertionProperty(.AssertionHumanReadableReasonKey, theValue: hRString)
        }
    }
    
    var localizationBundlePath: String? {
        get {
            return getAssertionProperty(.AssertionLocalizationBundlePathKey) as String?
        }
        set(lBPath) {
            setAssertionProperty(.AssertionLocalizationBundlePathKey, theValue: lBPath)
        }
    }
    
    var timeoutInSeconds: Double? {
        get {
            return getAssertionProperty(.AssertionTimeoutKey) as Double?
        }
        set(timeout) {
            // TODO: Setting the Timeout AND a default value for TimeoutAction
            //   This should probably not be done
            setAssertionProperty(.AssertionTimeoutKey, theValue: timeout)
            setAssertionProperty(.AssertionTimeoutActionKey, theValue: PowerAssertionDictionaryKey.AssertionTimeoutActionTurnOff.rawValue)
        }
    }
    
    /*
    *  Init
    */
    init?(name: String, type: PowerAssertionType, level: PowerAssertionLevel) {
        let ret: IOReturn = IOPMAssertionCreateWithName(
            type.rawValue,
            level.rawValue,
            name,
            &assertionID)
        
        // Because for some reason,
        // AssertionCreateWithName does not honor IOPMAssertionLevel
        if level == .Off {
            self.level = .Off
        }
        
        if ret != kIOReturnSuccess {
            return nil
        }
    }
    
    deinit {
        let ret: IOReturn = IOPMAssertionRelease(assertionID)
        
        if ret != kIOReturnSuccess {
            fatalError("Unable to release Assertion!")
        }
    }
    
    /*
    *  Private Helpers
    */
    private func setAssertionProperty(theProperty: PowerAssertionDictionaryKey, theValue: AnyObject?) -> IOReturn {
        return IOPMAssertionSetProperty(assertionID, theProperty.rawValue, theValue)
    }
    
    private func getAssertionProperty(theProperty: PowerAssertionDictionaryKey) -> AnyObject? {
        let dict: NSDictionary = IOPMAssertionCopyProperties(assertionID)!.takeRetainedValue()
        return dict.valueForKey(theProperty.rawValue)
    }
    
    
    /*
    *  Class Functions
    */
    class func getAssertionStatus() -> Dictionary<String,Int>? {
        var _assertionsStatus: Unmanaged<CFDictionaryRef>?
        
        let ret: IOReturn = IOPMCopyAssertionsStatus(&_assertionsStatus)
        if ret == kIOReturnSuccess {
            let assertionStatus: NSDictionary = _assertionsStatus!.takeRetainedValue()
            return assertionStatus as? Dictionary<String,Int>
        }
        
        return nil
    }
    
    private class func getAssertionCount(dict: Dictionary<String,Int>?) -> Int? {
        var count = 0
        
        if let dict = dict? {
            for (_, value) in dict {
                count += value
            }
            return count
        }
        
        return nil
    }
    
    class func getAssertionCount() -> Int? {
        return getAssertionCount(getAssertionStatus())
    }
    
    class func getFilteredAssertionStatus() -> Dictionary<String,Int>? {
        let dict = getAssertionStatus()
        let options = ["BackgroundTask", "ApplePushServiceTask", "UserIsActive", "PreventUserIdleDisplaySleep", "PreventSystemSleep", "ExternalMedia", "PreventUserIdleSystemSleep", "NetworkClientActive"]
        
        var newDict = Dictionary<String,Int>()
        
        if dict != nil {
            for (key, value) in dict! {
                if contains(options, key) {
                    newDict[key] = value
                }
            }
            return newDict
        }
        
        return nil
    }
    
    class func getFilteredAssertionCount() -> Int? {
        return getAssertionCount(getFilteredAssertionStatus())
    }
}