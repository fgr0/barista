//
//  PowerMgmtObserver.swift
//  Barista
//
//  Created by Franz Greiling on 17.01.18.
//  Copyright © 2018 Franz Greiling. All rights reserved.
//

import Cocoa


enum StoppedPreventingSleepReason {
    case Deactivated
    case Timeout
    case SystemWake
    case LowBattery
    case NoACPower
}


// MARK: - Observation
protocol PowerMgmtObserver: class {
    
    // Sleep Prevention
    func startedPreventingSleep(for: TimeInterval)
    func stoppedPreventingSleep(after: TimeInterval, because reason: StoppedPreventingSleepReason)
}


// MARK: Observer Default Implementation
extension PowerMgmtObserver {
    func startedPreventingSleep(for: TimeInterval) {
        return
    }
    
    func stoppedPreventingSleep(after: TimeInterval, because reason: StoppedPreventingSleepReason) {
        return
    }
}
