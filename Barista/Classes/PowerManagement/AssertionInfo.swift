//
//  AppAssertion.swift
//  Barista
//
//  Created by Franz Greiling on 28.01.18.
//  Copyright © 2018 Franz Greiling. All rights reserved.
//

import Cocoa
import IOKit.pwr_mgt


// MARK: - AssertionInfo Struct
struct AssertionInfo {
    //    var timeLeft: UInt? {
    //        guard self.timeout > 0 else { return nil }
    //        return UInt(Int(self.timeout) + Int(self.timeStarted.timeIntervalSinceNow))
    //    }
    
    let pid: pid_t
    let name: String
    let icon: NSImage?
    
    var num: Int {
        get { return self.ids.count }
    }
    
    let ids: [IOPMAssertionID]
    let preventsDisplaySleep: Bool
    let details: [String]?
    
    let timeStarted: Date
    let timeEnding: Date?
    var timeLeft: UInt? {
        guard let te = self.timeEnding, te.timeIntervalSinceNow > 0 else { return nil }
        return UInt(te.timeIntervalSinceNow)
    }
}


extension AssertionInfo {
    static func systemStatus() -> (preventingIdleSleep: Bool, preventingDisplaySleep: Bool)? {
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
    
    static func byProcess() -> [AssertionInfo] {
        var assertionsByProcess: Unmanaged<CFDictionary>?
        
        if IOPMCopyAssertionsByProcess(&assertionsByProcess) != kIOReturnSuccess {
            // TODO: Error Handling
            fatalError("o.o")
        }
        
        guard let pids = assertionsByProcess?.takeRetainedValue() as? [Int: [[String: Any]]] else { return [] }
        
        var assertionInfos = [AssertionInfo]()
        
        pids.forEach { (pid, assertions) in
            let name: String
            let icon: NSImage?
            if let app = NSRunningApplication(processIdentifier: pid_t(pid)) {
                #if RELEASE
                guard app != NSRunningApplication.current else { return }
                #endif
                name = app.localizedName!
                icon = app.icon
            } else {
                // Special Processing for Background Services
                switch assertions[0]["Process Name"] as? String {
                case "backupd":
                    name = "Time Machine"
                    icon = NSWorkspace.shared.icon(forFile: "/Applications/Time Machine.app")
                default:
                    return
                }
            }
            
            let initial: ([IOPMAssertionID], Bool, Date, Date?) = ([], false, Date.distantFuture, nil)
            let reduced = assertions.reduce(initial) { (previous, assertion) in
                var ids = previous.0
                ids.append(assertion["AssertionId"] as! IOPMAssertionID)
                
                let pds = previous.1 || assertion["AssertionTrueType"] as! String == "PreventUserIdleDisplaySleep"
                let ts = min(previous.2, assertion["AssertStartWhen"] as! Date)
                var te: Date? = previous.3
                
                if let to = (assertion[kIOPMAssertionTimeoutKey] as? Int), to > 0 {
                    if te != nil  {
                        te = max(te!, ts.addingTimeInterval(TimeInterval(to)))
                    } else {
                        te = ts.addingTimeInterval(TimeInterval(to))
                    }
                }

                return (ids, pds, ts, te)
            }
            
            assertionInfos.append(AssertionInfo(
                pid: pid_t(pid), name: name, icon: icon,
                ids: reduced.0, preventsDisplaySleep: reduced.1,
                details: nil, timeStarted: reduced.2, timeEnding: reduced.3
            ))
        }
        
        // TODO: Sort `.isEmpty ? [] : assertionInfos.sorted { $0.0.localizedName! < $1.0.localizedName! }`
        return assertionInfos.sorted { $0.name < $1.name }
    }
}
