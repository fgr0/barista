//
//  PowerMgmtObserver.swift
//  Barista
//
//  Created by Franz Greiling on 17.01.18.
//  Copyright © 2018 Franz Greiling. All rights reserved.
//

import Cocoa

// MARK: - Observation
protocol PowerMgmtObserver: class {
    func assertionChanged(isRunning: Bool, preventDisplaySleep: Bool)
    func systemAssertionsChanged(preventsIdleSleep: Bool, preventsDisplaySleep: Bool)
    func assertionTimedOut(after: TimeInterval)
    func assertionStoppedByWake()
}

// MARK: Observer Default Implementation
extension PowerMgmtObserver {
    func assertionChanged(isRunning: Bool, preventDisplaySleep: Bool) {
        return
    }
    
    func assertionTimedOut(after: TimeInterval) {
        return
    }
    
    func assertionStoppedByWake() {
        return
    }
    
    func systemAssertionsChanged(preventsIdleSleep: Bool, preventsDisplaySleep: Bool) {
        return
    }
}
