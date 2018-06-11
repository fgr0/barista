//
//  Uptime.swift
//  Barista
//
//  Created by Franz Greiling on 11.06.18.
//  Copyright © 2018 Franz Greiling. All rights reserved.
//

import Foundation

struct SystemTime {
    static var systemUptime: TimeInterval {
        get {
            return ProcessInfo().systemUptime
        }
    }
    static var realUptime: DateInterval {
        get {
            return DateInterval(start: SystemTime.boot!, end: Date())
        }
    }
    
    static var boot: Date? {
        get {
            return SystemTime.date(fromSysctl: "kern.boottime")
        }
    }
    static var lastSleep: Date? {
        get {
            return SystemTime.date(fromSysctl: "kern.sleeptime")
        }
    }
    static var lastWake: Date? {
        get {
            return SystemTime.date(fromSysctl: "kern.waketime")
        }
    }
    
    private static func date(fromSysctl sysctl: String) -> Date? {
        var time = timeval()
        var tvSize = MemoryLayout.stride(ofValue: time)
        
        guard sysctlbyname(sysctl, &time, &tvSize, nil, 0) != -1 && time.tv_sec > 0 else { return nil }
        
        return Date(timeIntervalSince1970: TimeInterval(time.tv_sec))
    }
}
