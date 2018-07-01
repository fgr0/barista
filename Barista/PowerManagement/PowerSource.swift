//
//  PowerSource.swift
//  Barista
//
//  Created by Franz Greiling on 30.06.18.
//  Copyright © 2018 Franz Greiling. All rights reserved.
//

import Cocoa
import IOKit.ps


/// Enum of Return Types from `IOPSGetProvidingPowerSourceType()`
enum PowerSourceType: String {
    case AC = "AC Power"            // kIOPMACPowerKey
    case Battery = "Battery Power"  // kIOPMBatteryPowerKey
    case UPS = "UPS Power"          // kIOPMUPSPowerKey
}


// MARK: - Main Class
class PowerSource {
    
    // MARK: - Properties
    private(set) var current: PowerSourceType? {
        didSet {
            guard oldValue != self.current else { return }
            self.delegate?.powerSourceNotification()
        }
    }
    
    private(set) var currentCapacity: Int? {
        didSet {
            guard oldValue != self.currentCapacity else { return }
            self.delegate?.batteryLevelNotification()
        }
    }
    
    private(set) var maxCapacity: Int? {
        didSet {
            guard oldValue != self.maxCapacity else { return }
            self.delegate?.batteryLevelNotification()
        }
    }
    
    var batteryLevel: Float? {
        guard let cur = self.currentCapacity, let max = self.maxCapacity else { return nil }
        return Float(cur) / Float(max)
    }
    
    
    // MARK: - Lifecycle
    var delegate: PowerSourceDelegate?
    
    init() {
        self.updateInformation()
        self.registerPowerSourceNotification()
    }
    
    deinit {
        self.deregisterPowerSourceNotification()
    }


    // MARK: - Manage Power Source Information
    func updateInformation() {
        self.current = PowerSource.providingPowerSource()
        
        let desc = PowerSource.powerSourceDescription()
        self.currentCapacity = desc?[kIOPSCurrentCapacityKey] as? Int
        self.maxCapacity = desc?[kIOPSMaxCapacityKey] as? Int
    }
    
    private static func powerSourceDescription() -> Dictionary<String,CFTypeRef>? {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else { return nil }
        guard let sources: NSArray = IOPSCopyPowerSourcesList(info)?.takeRetainedValue(), sources.count > 0
            else { return nil }
        
        for source in sources {
            let sdesc = IOPSGetPowerSourceDescription(info, source as CFTypeRef)?.takeUnretainedValue()
            guard let desc = sdesc as? Dictionary<String, CFTypeRef> else { continue }
            
            if let isPresent = desc[kIOPSIsPresentKey], (isPresent as! CFBoolean) == kCFBooleanTrue {
                return desc
            }
        }
        
        return nil
    }
    
    private static func providingPowerSource() -> PowerSourceType? {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else { return nil }
        guard let powerSource = IOPSGetProvidingPowerSourceType(info)?.takeRetainedValue() else { return nil }
        
        return PowerSourceType(rawValue: powerSource as String)
    }
    
    
    // MARK: - Power Source Notification
    private var loop: CFRunLoopSource?

    private func registerPowerSourceNotification() {
        let loop: CFRunLoopSource = IOPSNotificationCreateRunLoopSource({ (context: UnsafeMutableRawPointer?) in
            guard context != nil else { return }
            Unmanaged<PowerSource>
                .fromOpaque(context!)
                .takeUnretainedValue()
                .updateInformation()
        }, Unmanaged.passUnretained(self).toOpaque()).takeRetainedValue() as CFRunLoopSource
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), loop, CFRunLoopMode.defaultMode)
        self.loop = loop
    }
    
    private func deregisterPowerSourceNotification() {
        guard let loop = self.loop else { return }
        
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), loop, CFRunLoopMode.defaultMode)
        self.loop = nil
    }
}


// MARK: - Power Source Delegate
protocol PowerSourceDelegate {
    func powerSourceNotification()
    func batteryLevelNotification()
}
