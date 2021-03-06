//
//  PowerMgmtController.swift
//  Barista
//
//  Created by Franz Greiling on 24.06.18.
//  Copyright © 2018 Franz Greiling. All rights reserved.
//

import Cocoa


class PowerMgmtController: NSObject, PowerSourceDelegate {

    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if UserDefaults.standard.shouldActivateOnLaunch {
            self.preventSleep()
        }
        
        // Register for `Wake` Notifications
        NSWorkspace.shared.notificationCenter.addObserver(
        forName: NSWorkspace.didWakeNotification, object: nil, queue: nil) { _ in
            guard UserDefaults.standard.stopAtForcedSleep else { return }
            guard let assertion = self.assertion, assertion.enabled else { return }
            
            self.stopPreventingSleep(reason: .SystemWake)
        }
        
        if PowerSource.hasBattery {
            self.powerSource.delegate = self
        }
    }
    
    deinit {
        self.timeoutTimer?.invalidate()
        //self.monitorTimer?.invalidate()
    }
    
    
    // MARK: - Managing System Sleep
    private(set) var assertion: UserAssertion?
    private var timeoutTimer: Timer?
    
    func preventSleep() {
        if UserDefaults.standard.durationType == 0 {
            self.preventSleep(withTimeout: 0)
        } else if UserDefaults.standard.durationType == 1 {
            self.preventSleep(withTimeout: UInt(UserDefaults.standard.durationTimeout))
        } else {
            self.preventSleepUntilEndOfDay()
        }
    }
    
    func preventSleep(until: Date) {
        self.preventSleep(withTimeout: UInt((until.timeIntervalSinceNow)))

    }
    
    func preventSleep(withTimeout timeout: UInt) {
        // Stop any running assertion
        stopPreventingSleep()
        
        // Create new assertion
        guard let assertion = UserAssertion.createAssertion(
            withName: Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as! String,
            timeout: timeout,
            thatPreventsDisplaySleep: UserDefaults.standard.preventDisplaySleep
            ) else { return }
        
        self.assertion = assertion
        
        if timeout > 0 {
            self.timeoutTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(timeout+2), repeats: false) { _ in
                guard let assertion = self.assertion, !assertion.enabled else { return }
                self.stopPreventingSleep(reason: .Timeout)
            }
        }
        
        self.notifyStartedPreventingSleep(for: TimeInterval(timeout))
    }
    
    func preventSleepUntilEndOfDay() {
        // Find the next 3:00am date that's more than 30 minutes in the future
        var nextDate: Date = Date()
        
        let date = DateFormatter.date(from: UserDefaults.standard.durationEndAtTime, withFormat: "HH:mm")!
        let time = Calendar.current.dateComponents([.hour, .minute], from: date)
        
        repeat {
            nextDate = Calendar.current.nextDate(
                after: nextDate,
                matching: time,
                matchingPolicy: .nextTime)!
        } while nextDate.timeIntervalSinceNow < 60
        
        self.preventSleep(until: nextDate)
    }
    
    func stopPreventingSleep() {
        self.stopPreventingSleep(reason: .Deactivated)
    }
    
    private func stopPreventingSleep(reason: StoppedPreventingSleepReason) {
        guard let assertion = self.assertion else { return }
        
        self.timeoutTimer?.invalidate()
        self.notifyStoppedPreventingSleep(after: Date().timeIntervalSince(assertion.timeStarted), because: reason)
        self.assertion = nil
    }
    
    
    // MARK: - Power Source Information
    private(set) var powerSource = PowerSource()
    
    func powerSourceNotification() {
        guard let assertion = self.assertion, assertion.enabled else { return }
        guard let ps = self.powerSource.current, ps == .Battery else { return }
        guard UserDefaults.standard.batteryTurnOffOnSwitch else { return }
        
        self.stopPreventingSleep(reason: .NoACPower)
    }
    
    func batteryLevelNotification() {
        guard let assertion = self.assertion, assertion.enabled else { return }
        guard let battery = self.powerSource.batteryLevel else { return }
        guard UserDefaults.standard.batteryDeactivateOnThreshold else { return }
        
        if Double(battery) <= UserDefaults.standard.batteryThreshold {
            self.stopPreventingSleep(reason: .LowBattery)
        }
    }
    
    
    // MARK: - Obervation
    private var observers = [PowerMgmtObserver]()
    
    func addObserver(_ observer: PowerMgmtObserver) {
        observers.append(observer)
    }
    
    func removeObserver(_ observer: PowerMgmtObserver) {
        observers.removeAll { $0 === observer }
    }
    
    
    private func notifyStartedPreventingSleep(for timeout: TimeInterval) {
        observers.forEach { $0.startedPreventingSleep(for: timeout) }
    }
    
    private func notifyStoppedPreventingSleep(after timeout: TimeInterval, because reason: StoppedPreventingSleepReason) {
        observers.forEach { $0.stoppedPreventingSleep(after: timeout, because: reason) }
    }
}
