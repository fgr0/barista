//
//  AssertionController.swift
//  Barista
//
//  Created by Franz Greiling on 26.11.17.
//  Copyright © 2017 Franz Greiling. All rights reserved.
//

import Cocoa


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
    }
    
    
    // MARK: - Managing Assertion
    private var assertion: Assertion?
    
    var isRunning: Bool {
        get {
            guard let a = self.assertion else { return false }
            return a.enabled
        }
    }
    
    @objc dynamic var preventDisplaySleep: Bool = true {
        didSet {
            guard self.assertion != nil else { return }
            
            self.assertion?.preventDisplaySleep = self.preventDisplaySleep
            self.assertion?.details = PowerMgmtController.makeDetailsString(
                displaySleep: self.preventDisplaySleep, time: (self.assertion?.timeout)!)
            
            self.notifyAssertionChanged()
        }
    }
    
    func startAssertion() {
        self.startAssertion(withTimeout: UInt(UserDefaults.standard.integer(forKey: Constants.defaultTimeout)))
    }
    
    func startAssertion(withTimeout timeout: UInt = 0) {
        // Stop any running assertion
        stopAssertion()
        
        // Create new assertion
        let details = PowerMgmtController.makeDetailsString(displaySleep: true, time: timeout)
        
        self.assertion = Assertion(preventDisplaySleep: self.preventDisplaySleep, timeout: timeout)
        self.assertion?.details = details
        
        if timeout > 0 {
            startTimer(withTimeout: timeout)
        }
        
        self.notifyAssertionChanged()
    }

    func stopAssertion() {
        guard self.assertion != nil else { return }
        
        self.assertion?.enabled = false
        self.assertion = nil
        
        self.stopTimer()
        
        self.notifyAssertionChanged()
    }
    
    @IBAction func toggleAssertion(_ sender: NSMenuItem) {
        if self.assertion != nil && (self.assertion?.enabled)! {
            self.stopAssertion()
        } else {
            self.startAssertion()
        }
    }
    
    
    // MARK: - Timer
    private var timer: Timer?
    
    private func startTimer(withTimeout timeout: UInt) {
        // Invalidate any running timer
        if let t = timer {
            t.invalidate()
        }

        self.timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(timeout-15), repeats: false) {_ in
            // TODO: Error Handling
            //guard !self.isRunning else { return }

            self.stopAssertion()
            self.notifyAssertionTimedOut(after: timeout)
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
            o.assertionChanged(isRunning: self.isRunning, preventDisplaySleep: self.preventDisplaySleep)
        }
    }
    
    private func notifyAssertionTimedOut(after: UInt) {
        for o in observers {
            o.assertionTimedOut(after: after)
        }
    }
    
    
    // MARK: - Helper
    fileprivate class func makeDetailsString(displaySleep: Bool, time: UInt) -> String {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .short
        
        let s = displaySleep ? "Preventing sleep" : "Preventing display sleep"
        let t = (time == 0) ? "forever" : "for \(formatter.string(from: Double(time))!)"
        
        return "\(s) \(t)"
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
        print("timeout")
        return
    }
}
