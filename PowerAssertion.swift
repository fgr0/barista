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
    case On = 255
    case Off =  0
}

class PowerAssertion {
    
    private var assertionID: IOPMAssertionID = UInt32(kIOPMNullAssertionID)
    
    var name: String {
        set(name) {
            setAssertionProperty(
                PowerAssertionDictionaryKey.AssertionNameKey,
                theValue: name
            )
        }
        get {
            return getAssertionProperty(PowerAssertionDictionaryKey.AssertionNameKey)! as String
        }
    }
    var type: PowerAssertionType {
        get {
            return PowerAssertionType(rawValue:
                getAssertionProperty(PowerAssertionDictionaryKey.AssertionTypeKey)! as String
            )!
        }
    }
    var level: PowerAssertionLevel {
        set(level) {
            setAssertionProperty(
                PowerAssertionDictionaryKey.AssertionLevelKey,
                theValue: NSNumber(unsignedInt: level.rawValue)
            )
        }
        get {
            return PowerAssertionLevel(rawValue:
                UInt32(getAssertionProperty(PowerAssertionDictionaryKey.AssertionLevelKey)! as Int)
            )!
        }
    }
    var details: String? {
        set(details) {
            setAssertionProperty(
                PowerAssertionDictionaryKey.AssertionDetailsKey,
                theValue: details
            )
        }
        get {
            return getAssertionProperty(PowerAssertionDictionaryKey.AssertionDetailsKey) as String?
        }
    }
    var humanReadableReason: String? {
        set(hRString) {
            setAssertionProperty(
                PowerAssertionDictionaryKey.AssertionHumanReadableReasonKey,
                theValue: hRString
            )
        }
        get {
            return getAssertionProperty(PowerAssertionDictionaryKey.AssertionHumanReadableReasonKey) as String?
        }
    }
    var localizationBundlePath: String? {
        set(lBPath) {
            setAssertionProperty(
                PowerAssertionDictionaryKey.AssertionLocalizationBundlePathKey,
                theValue: lBPath
            )
        }
        get {
            return getAssertionProperty(PowerAssertionDictionaryKey.AssertionLocalizationBundlePathKey) as String?
        }
    }
    var timeoutInSeconds: Double? {
        set(timeout) {
            setAssertionProperty(
                PowerAssertionDictionaryKey.AssertionTimeoutKey,
                theValue: timeout
            )
            setAssertionProperty(
                PowerAssertionDictionaryKey.AssertionTimeoutActionKey,
                theValue: PowerAssertionDictionaryKey.AssertionTimeoutActionTurnOff.rawValue
            )
        }
        get {
            return getAssertionProperty(PowerAssertionDictionaryKey.AssertionTimeoutKey) as Double?
        }
    }
    
    init?(name: String, type: PowerAssertionType, level: PowerAssertionLevel) {
        
        let ret: IOReturn = IOPMAssertionCreateWithName(
            type.rawValue,
            level.rawValue,
            name,
            &assertionID)
        
        if ret != kIOReturnSuccess {
            return nil
        }
    }
    
    init?(name: String, type: PowerAssertionType, level: PowerAssertionLevel, details: String?, humanReadableReason: String?, localizationBundlePath: String?, withTimeoutInSeconds: Double) {
        
        let ret: IOReturn = IOPMAssertionCreateWithDescription(
            type.rawValue,
            name,
            details,
            humanReadableReason,
            localizationBundlePath,
            withTimeoutInSeconds,
            "TimeoutActionTurnOff",
            &assertionID
        )
        
        if ret != kIOReturnSuccess {
            return nil
        }
    }

    
    private func setAssertionProperty(theProperty: PowerAssertionDictionaryKey, theValue: AnyObject?) -> IOReturn {
        return IOPMAssertionSetProperty(assertionID, theProperty.rawValue, theValue)
    }
    
    private func getAssertionProperty(theProperty: PowerAssertionDictionaryKey) -> AnyObject? {
        let dict: NSDictionary = IOPMAssertionCopyProperties(assertionID)!.takeRetainedValue()
        return dict.valueForKey(theProperty.rawValue)
    }
    
    deinit {
        let ret: IOReturn = IOPMAssertionRelease(assertionID)

        if ret != kIOReturnSuccess {
            fatalError("Unable to release Assertion!")
        }
    }
    
    /***
     * Class Functions
     ***/
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