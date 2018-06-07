//
//  AssertionController.swift
//  Barista
//
//  Created by Franz Greiling on 26.11.17.
//  Copyright © 2018 Franz Greiling. All rights reserved.
//

import Cocoa
import IOKit.pwr_mgt

class AssertionController: NSObject {

    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.preventDisplaySleep = UserDefaults.standard.preventDisplaySleep
        self.shouldMonitor = UserDefaults.standard.backgroundMonitoring
        
        UserDefaults.standard.bind(
            NSBindingName(rawValue: UserDefaults.Keys.preventDisplaySleep),
            to: self,
            withKeyPath: #keyPath(preventDisplaySleep),
            options: nil)
        
        UserDefaults.standard.bind(
            NSBindingName(rawValue: UserDefaults.Keys.backgroundMonitoring),
            to: self,
            withKeyPath: #keyPath(shouldMonitor),
            options: nil)
        
        if UserDefaults.standard.shouldActivateOnLaunch {
            self.startAssertion()
        }
        
        NSWorkspace.shared.notificationCenter.addObserver(
        forName: NSWorkspace.didWakeNotification, object: nil, queue: nil) { _ in
            guard UserDefaults.standard.stopAtForcedSleep else { return }
            guard self.enabled else { return }
            
            self.notifyAssertionStoppedByWake()
            self.stopAssertion()
        }
    }
    
    deinit {
        self.timeoutTimer?.invalidate()
        self.monitorTimer?.invalidate()
        guard let id = self.aid else { return }
        IOPMAssertionRelease(id)
    }
    
    
    // MARK: - Managing the Assertion
    private var aid: IOPMAssertionID?
    private var timeoutTimer: Timer?
    
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
    
    @objc dynamic var preventDisplaySleep: Bool = true {
        didSet {
            guard let aid = self.aid else { return }
            
            // Type cannot be changed by just setting the property (bug?)
            // Workaround is to create a new Assertion with identical settings
            var props = IOPMAssertionCopyProperties(aid).takeRetainedValue() as! Dictionary<String, CFTypeRef>
            props[kIOPMAssertionTypeKey] = (preventDisplaySleep ?
                kIOPMAssertionTypePreventUserIdleDisplaySleep : kIOPMAssertionTypePreventUserIdleSystemSleep) as CFString
            props[kIOPMAssertionDetailsKey] = self.makeDetailsString(timeout) as CFString
            
            var newId = UInt32(kIOPMNullAssertionID)
            guard IOPMAssertionCreateWithProperties(props as CFDictionary, &newId) == kIOReturnSuccess  else {
                return
            }
            
            IOPMAssertionRelease(aid)
            self.aid = newId
            
            self.notifyAssertionChanged()
        }
    }
    
    private(set) var timeout: UInt {
        get {
            guard self.aid != nil else { return 0 }
            return getAssertionProperty(kIOPMAssertionTimeoutKey) as! UInt
        }
        set(timeout) {
            setProperty(kIOPMAssertionTimeoutKey, value: timeout as CFNumber)
        }
    }
    
    var timeLeft: UInt? {
        get {
            guard self.aid != nil else { return nil }
            guard self.timeout != 0 else { return nil }
            guard self.enabled else { return nil }
            
            // Calculate timeLeft based on the value inside the assertion dict and the time that value was updated
            let lastValue = getAssertionProperty("AssertTimeoutTimeLeft") as! Int
            let timeUpdated = getAssertionProperty("AssertTimeoutUpdateTime") as! Date
            return UInt(lastValue + Int(timeUpdated.timeIntervalSinceNow))
        }
    }
    
    
    func startAssertion() {
        if UserDefaults.standard.endOfDaySelected {
            self.startAssertionForRestOfDay()
        } else {
            self.startAssertion(withTimeout: UInt(UserDefaults.standard.defaultTimeout))
        }
    }
    
    func startAssertionForRestOfDay() {
        // Find the next 3:00am date that's more than 30 minutes in the future
        var nextDate: Date = Date()

        let hour = min(max(UserDefaults.standard.endOfDayTime, 0), 23)
        
        repeat {
            nextDate = Calendar.current.nextDate(
                after: nextDate,
                matching: DateComponents(hour: hour, minute: 0, second: 0),
                matchingPolicy: .nextTime)!
        } while nextDate.timeIntervalSinceNow < 1800

        self.startAssertion(withTimeout: UInt((nextDate.timeIntervalSinceNow)))
    }

    func startAssertion(withTimeout timeout: UInt) {
        // Stop any running assertion
        stopAssertion()
        
        // Create new assertion
        var id = UInt32(kIOPMNullAssertionID)
        var props = Dictionary<String, CFTypeRef>()
        
        props[kIOPMAssertionNameKey]    = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! CFString
        props[kIOPMAssertionLevelKey]   = kIOPMAssertionLevelOn as CFNumber
        props[kIOPMAssertionTypeKey]    = (preventDisplaySleep ?
            kIOPMAssertionTypePreventUserIdleDisplaySleep : kIOPMAssertionTypePreventUserIdleSystemSleep) as CFString
        props[kIOPMAssertionTimeoutActionKey]   = kIOPMAssertionTimeoutActionTurnOff as CFTypeRef
        props[kIOPMAssertionTimeoutKey]         = timeout as CFNumber
        props[kIOPMAssertionDetailsKey]         = self.makeDetailsString(timeout) as CFString

        guard IOPMAssertionCreateWithProperties(props as CFDictionary, &id) == kIOReturnSuccess else {
            return
        }
        
        self.aid = id
        
        if timeout > 0 {
            self.timeoutTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(timeout+5), repeats: false) { _ in
                guard !self.enabled else { return }
                self.notifyAssertionTimedOut(after: TimeInterval(timeout))
                self.stopAssertion()
            }
        }
        
        self.notifyAssertionChanged()
    }


    func stopAssertion() {
        guard self.aid != nil else { return }
        
        IOPMAssertionRelease(self.aid!)
        self.aid = nil
        
        self.timeoutTimer?.invalidate()
        self.notifyAssertionChanged()
    }
    
    
    // MARK: - Information about System Assertions
    @objc dynamic var shouldMonitor: Bool = false {
        didSet {
            if self.shouldMonitor {
                self.monitorTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
                    guard let current = AssertionInfo.systemStatus() else { return }

                    if let last = self.lastStatus, last != current {
                        self.notifySystemAssertionsChanged(current.preventingIdleSleep, current.preventingDisplaySleep)
                    }

                    self.lastStatus = current
                }
            } else {
                self.monitorTimer?.invalidate()
                self.lastStatus = nil
            }
        }
    }
    private var monitorTimer: Timer?
    private var lastStatus: (preventingIdleSleep: Bool, preventingDisplaySleep: Bool)? = nil
    
    
    // MARK: - Observation
    private var observers = [AssertionObserver]()
    
    func addObserver(_ observer: AssertionObserver) {
        observers.append(observer)
    }
    
    func removeObserver(_ observer: AssertionObserver) {
        observers = observers.filter { $0 !== observer }
    }
    
    private func notifyAssertionChanged() {
        observers.forEach { $0.assertionChanged(isRunning: self.enabled, preventDisplaySleep: self.preventDisplaySleep) }
    }
    
    private func notifyAssertionTimedOut(after: TimeInterval) {
        observers.forEach { $0.assertionTimedOut(after: after) }
    }
    
    private func notifyAssertionStoppedByWake() {
        observers.forEach { $0.assertionStoppedByWake() }
    }
    
    private func notifySystemAssertionsChanged(_ prevIdleSleep: Bool, _ prevDisplaySleep: Bool) {
        observers.forEach { $0.systemAssertionsChanged(preventsIdleSleep: prevIdleSleep, preventsDisplaySleep: prevDisplaySleep)}
    }
    
    
    // MARK: - Helper
    fileprivate func makeDetailsString(_ time: UInt) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .short
        
        let s = self.preventDisplaySleep ? "Preventing display sleep" :"Preventing sleep"
        let t = (time == 0) ? "forever" : "for \(formatter.string(from: Double(time))!)"
        
        return "\(s) \(t)"
    }
    
    private func getAssertionProperty(_ property: String) -> CFTypeRef? {
        guard let id = self.aid else { return nil }
        let props = IOPMAssertionCopyProperties(id).takeRetainedValue() as! Dictionary<String, CFTypeRef>
        return props[property]
    }
    
    private func setProperty(_ property: String, value: CFTypeRef) {
        guard let id = self.aid else { return }
        // TODO: Error Handling (Exceptions?)
        IOPMAssertionSetProperty(id, property as CFString, value)
    }
}
