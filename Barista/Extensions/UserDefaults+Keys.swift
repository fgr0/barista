//
//  UserDefaults+Keys.swift
//  Barista
//
//  Created by Franz Greiling on 16.01.18.
//  Copyright © 2018 Franz Greiling. All rights reserved.
//

import Cocoa

extension UserDefaults {
    // MARK: - Preference Keys
    struct Keys {
        static let shouldActivateOnLaunch   = "shouldActivateOnLaunch"
        static let shouldLaunchAtLogin      = "shouldLaunchAtLogin"
        static let preventDisplaySleep      = "preventDisplaySleep"
        static let defaultTimeout           = "defaultTimeout"
        static let showAppList              = "showAppList"
        static let showUptime               = "showUptime"
        static let sendNotifications        = "sendNotifications"
        static let endOfDaySelected         = "endOfDaySelected"
        static let stopAtForcedSleep        = "stopAtForcedSleep"
        static let quickActivation          = "quickActivation"
        static let backgroundMonitoring     = "backgroundMonitoring"
        static let appListDetail            = "appListDetail"
        static let hadFirstLaunch           = "hadFirstLaunch"
        static let endOfDayTime             = "endOfDayTime"
    }
    
    // MARK: - Convenience Accessors
    @objc dynamic var shouldActivateOnLaunch: Bool {
        set(should) { set(should, forKey: UserDefaults.Keys.shouldActivateOnLaunch) }
        get { return bool(forKey: UserDefaults.Keys.shouldActivateOnLaunch) }
    }
    
    @objc dynamic var shouldLaunchAtLogin: Bool {
        set(should) { set(should, forKey: UserDefaults.Keys.shouldLaunchAtLogin) }
        get { return bool(forKey: UserDefaults.Keys.shouldLaunchAtLogin) }
    }
    
    @objc dynamic var preventDisplaySleep: Bool {
        set(should) { set(should, forKey: UserDefaults.Keys.preventDisplaySleep) }
        get { return bool(forKey: UserDefaults.Keys.preventDisplaySleep) }
    }
    
    @objc dynamic var defaultTimeout: Int {
        set(timeout) { set(timeout, forKey: UserDefaults.Keys.defaultTimeout) }
        get { return integer(forKey: UserDefaults.Keys.defaultTimeout) }
    }
    
    @objc dynamic var showAppList: Bool {
        set(always) { set(always, forKey: UserDefaults.Keys.showAppList) }
        get { return bool(forKey: UserDefaults.Keys.showAppList) }
    }
    
    @objc dynamic var showUptime: Bool {
        set(always) { set(always, forKey: UserDefaults.Keys.showUptime) }
        get { return bool(forKey: UserDefaults.Keys.showUptime) }
    }
    
    @objc dynamic var sendNotifications: Bool {
        set(should) { set(should, forKey: UserDefaults.Keys.sendNotifications) }
        get { return bool(forKey: UserDefaults.Keys.sendNotifications) }
    }
    
    @objc dynamic var endOfDaySelected: Bool {
        set(end) { set(end, forKey: UserDefaults.Keys.endOfDaySelected) }
        get { return bool(forKey: UserDefaults.Keys.endOfDaySelected) }
    }
    
    @objc dynamic var stopAtForcedSleep: Bool {
        set(stop) { set(stop, forKey: UserDefaults.Keys.stopAtForcedSleep) }
        get { return bool(forKey: UserDefaults.Keys.stopAtForcedSleep) }
    }
    
    @objc dynamic var quickActivation: Bool {
        set(quick) { set(quick, forKey: UserDefaults.Keys.quickActivation) }
        get { return bool(forKey: UserDefaults.Keys.quickActivation) }
    }
    
    
    @objc dynamic var backgroundMonitoring: Bool {
        set(should) { set(should, forKey: UserDefaults.Keys.backgroundMonitoring) }
        get { return bool(forKey: UserDefaults.Keys.backgroundMonitoring) }
    }
    
    @objc dynamic var appListDetail: Int {
        set(level) { set(level, forKey: UserDefaults.Keys.appListDetail) }
        get { return integer(forKey: UserDefaults.Keys.appListDetail) }
    }
    
    @objc dynamic var hadFirstLaunch: Bool {
        set(first) { set(first, forKey: UserDefaults.Keys.hadFirstLaunch) }
        get { return bool(forKey: UserDefaults.Keys.hadFirstLaunch)}
    }
    
    @objc dynamic var endOfDayTime: Int {
        set(time) { set(time, forKey: UserDefaults.Keys.endOfDayTime) }
        get { return integer(forKey: UserDefaults.Keys.endOfDayTime) }
    }
}
