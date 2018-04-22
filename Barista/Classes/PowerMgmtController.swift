//
//  AssertionController.swift
//  Barista
//
//  Created by Franz Greiling on 26.11.17.
//  Copyright © 2017 Franz Greiling. All rights reserved.
//

import Cocoa
import IOKit.pwr_mgt

class PowerMgmtController: NSObject {

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
        // Calculate Date for Tomorrow, 2AM local time
        let c = Calendar(identifier: .gregorian)
        var tomorrow = c.dateComponents([.day, .month, .year],
                                        from: c.date(byAdding: DateComponents(day: 1),
                                                     to: Date())!)
        // TODO: Make this a user setting (at least a hidden default)
        tomorrow.hour = 2
        
        self.startAssertion(withTimeout: UInt((c.date(from: tomorrow)?.timeIntervalSinceNow)!))
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
                    guard let current = PowerMgmtController.assertionsStatus() else { return }
                    
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
    
    class func assertionsStatus() -> (preventingIdleSleep: Bool, preventingDisplaySleep: Bool)? {
        var assertionsStatus: Unmanaged<CFDictionary>?
        
        if IOPMCopyAssertionsStatus(&assertionsStatus) != kIOReturnSuccess {
            return nil
        }
        
        guard let state = assertionsStatus?.takeRetainedValue() as? [String: Bool] else { return nil }

        var prevIdleSleep = false
        var prevDisplaySleep = false
        
        for (type, level) in state {
            guard level else { continue }
            
            switch type {
            // Preventing Display Sleep
            case "PreventUserIdleDisplaySleep":
                prevDisplaySleep = true
            // Preventing Idle Sleep
            case "ApplePushServiceTask",
                 "AwakeOnReservePower",
                 "PreventUserIdleSystemSleep":
                prevIdleSleep = true
            // Unknown/Ignored Assertions (some of which do prevent sleep, but are usually very short-lived)
            default:
                break
            }
        }
        
        return (prevIdleSleep, prevDisplaySleep)
    }
    
    class func assertionsByApp() -> [(NSRunningApplication, [Assertion])] {
        var assertionsByProcess: Unmanaged<CFDictionary>?
        
        if IOPMCopyAssertionsByProcess(&assertionsByProcess) != kIOReturnSuccess {
            fatalError("o.o")
        }
        
        guard let pids = assertionsByProcess?.takeRetainedValue() as? [Int: [[String: Any]]] else { return [] }
        
        var aP = [(NSRunningApplication, [Assertion])]()
        
        pids.forEach { (pid, assertions) in
            guard let app = NSRunningApplication(processIdentifier: pid_t(pid)) else { return }
            #if RELEASE
            guard app != NSRunningApplication.current else { return }
            #endif
            
            var list = [Assertion]()
            
            assertions.forEach { assertion in
                guard let a = Assertion(dict: assertion) else { return }
                list.append(a)
            }
            
            aP.append((app, list))
        }
        
        return aP.isEmpty ? [] : aP.sorted { $0.0.localizedName! < $1.0.localizedName! }
    }

    
    // MARK: - Observation
    private var observers = [PowerMgmtObserver]()
    
    func addObserver(_ observer: PowerMgmtObserver) {
        observers.append(observer)
    }
    
    func removeObserver(_ observer: PowerMgmtObserver) {
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
