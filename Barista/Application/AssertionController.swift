//
//  AssertionController.swift
//  Barista
//
//  Created by Franz Greiling on 26.11.17.
//  Copyright © 2017 Franz Greiling. All rights reserved.
//

import Cocoa

class AssertionController: NSObject {
    
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
    
    
    // MARK: - Managing Assertion
    private var assertion: Assertion?
    
    @objc var isRunning: Bool {
        get {
            guard let a = self.assertion else { return false }
            return a.enabled
        }
    }
    
    @objc dynamic var preventDisplaySleep: Bool = true {
        didSet {
            guard self.assertion != nil else { return }
            
            self.assertion?.preventDisplaySleep = self.preventDisplaySleep
            self.assertion?.details = AssertionController.makeDetailsString(
                displaySleep: self.preventDisplaySleep, time: (self.assertion?.timeout)!)
        }
    }
    
    func startAssertion() {
        self.startAssertion(withTimeout: UInt(UserDefaults.standard.integer(forKey: Constants.defaultTimeout)))
    }
    
    func startAssertion(withTimeout timeout: UInt = 0) {
        // Stop any running assertion
        stopAssertion()
        
        // Create new assertion
        let details = AssertionController.makeDetailsString(displaySleep: true, time: timeout)
        
        self.assertion = Assertion(preventDisplaySleep: self.preventDisplaySleep, timeout: timeout)
        self.assertion?.details = details
    }

    func stopAssertion() {
        guard self.assertion != nil else { return }
        
        self.assertion?.enabled = false
        self.assertion = nil
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
