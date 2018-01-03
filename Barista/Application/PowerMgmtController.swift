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
        
        self.preventDisplaySleep = UserDefaults.standard.bool(forKey: Constants.preventDisplaySleep)
        
        UserDefaults.standard.bind(
            NSBindingName(rawValue: Constants.preventDisplaySleep),
            to: self,
            withKeyPath: "preventDisplaySleep",
            options: nil)
        
        if UserDefaults.standard.bool(forKey: Constants.shouldActivateOnLaunch) {
            self.startAssertion()
        }
    }
    
    deinit {
        self.timer?.invalidate()
        guard let id = self.aid else { return }
        IOPMAssertionRelease(id)
    }
    
    
    // MARK: - Managing the Assertion
    private var aid: IOPMAssertionID?
    
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
            if IOPMAssertionCreateWithProperties(props as CFDictionary, &newId) != kIOReturnSuccess {
                fatalError("didn't expect this not to work")
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
            
            // Calculate timeLeft based on the value inside the assertion dict and the time that value was updated
            let lastValue = getAssertionProperty("AssertTimeoutTimeLeft") as! Int
            let timeUpdated = getAssertionProperty("AssertTimeoutUpdateTime") as! Date
            let timeLeft = lastValue + Int(timeUpdated.timeIntervalSinceNow)
            
            return UInt(timeLeft)
        }
    }
    
    
    func startAssertion() {
        self.startAssertion(withTimeout: UInt(UserDefaults.standard.integer(forKey: Constants.defaultTimeout)))
    }
    
    func startAssertion(withTimeout timeout: UInt = 0) {
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

        if IOPMAssertionCreateWithProperties(props as CFDictionary, &id) != kIOReturnSuccess {
            fatalError("didn't expect this not to work")
        }
        
        self.aid = id
        
        if timeout > 0 {
            startTimer(withTimeout: timeout)
        }
        
        self.notifyAssertionChanged()
    }

    func stopAssertion() {
        guard self.aid != nil else { return }
        
        IOPMAssertionRelease(self.aid!)
        self.aid = nil
        
        self.stopTimer()
        self.notifyAssertionChanged()
    }
    
    @IBAction func toggleAssertion(_ sender: NSMenuItem) {
        if self.aid != nil && self.enabled {
            self.stopAssertion()
        } else {
            self.startAssertion()
        }
    }
    
    
    // MARK: - Information about Global Assertions
    var assertingApps: [AssertingApp]?
    
    func assertionsByApp() -> [AssertingApp]? {
        var assertionsByProcess: Unmanaged<CFDictionary>?
        
        if IOPMCopyAssertionsByProcess(&assertionsByProcess) != kIOReturnSuccess {
            fatalError("o.o")
        }
        
        guard let pids = assertionsByProcess?.takeRetainedValue() as? [Int: [[String: Any]]] else { return nil }
        
        var aP = Set<AssertingApp>()
        
        pids.forEach { (pid, assertions) in
            guard let app = NSRunningApplication(processIdentifier: pid_t(pid)) else { return }
            #if RELEASE
            guard app != NSRunningApplication.current else { return }
            #endif
            
            var prevDisplaySleep = false
            var skip = false
            
            assertions.forEach { assertion in
                guard let s = assertion["AssertionTrueType"] as? String else { return }
                
                switch s {
                case "PreventUserIdleDisplaySleep":
                    prevDisplaySleep = true
                case "PreventUserIdleSystemSleep": break
                default:
                    // We don't care about other assertion types atm
                    skip = true
                }
            }
            
            if !skip {
                aP.update(with: AssertingApp(app: app, preventsDisplaySleep: prevDisplaySleep))
            }
        }
        
        return aP.isEmpty ? nil : Array(aP)
    }
    
    
    // MARK: - Timer
    private var timer: Timer?
    
    private func startTimer(withTimeout timeout: UInt) {
        // Invalidate any running timer
        if let t = timer {
            t.invalidate()
        }

        self.timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(timeout+5), repeats: false) {_ in
            // TODO: Error Handling
            guard !self.enabled else { return }
            
            self.notifyAssertionTimedOut(after: timeout)
            self.stopAssertion()
        }
    }
    
    private func stopTimer() {
        self.timer?.invalidate()
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
        for o in observers {
            o.assertionChanged(isRunning: self.enabled, preventDisplaySleep: self.preventDisplaySleep)
        }
    }
    
    private func notifyAssertionTimedOut(after: UInt) {
        for o in observers {
            o.assertionTimedOut(after: after)
        }
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


// MARK: - AssertingApp Struct
struct AssertingApp {
    let app: NSRunningApplication
    let preventsDisplaySleep: Bool
}

// MARK: Equatable Implementation
extension AssertingApp: Hashable {
    var hashValue: Int {
        return self.app.hashValue ^ self.preventsDisplaySleep.hashValue &* 16777619
    }
    static func ==(lhs: AssertingApp, rhs: AssertingApp) -> Bool {
        return (lhs.app == rhs.app &&
            lhs.preventsDisplaySleep == rhs.preventsDisplaySleep)
    }
}


// MARK: - Observation
protocol PowerMgmtObserver: class {
    func assertionChanged(isRunning: Bool, preventDisplaySleep: Bool)
    func assertionTimedOut(after: UInt)
}

// MARK: Observer Default Implementation
extension PowerMgmtObserver {
    func assertionChanged(isRunning: Bool, preventDisplaySleep: Bool) {
        return
    }
    
    func assertionTimedOut(after: UInt) {
        return
    }
}
