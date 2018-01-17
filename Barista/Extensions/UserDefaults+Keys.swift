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
        static let alwaysShowApps           = "alwaysShowApps"
        static let sendNotifications        = "sendNotifications"
        static let endOfDaySelected         = "endOfDaySelected"
        static let stopAtForcedSleep        = "stopAtForcedSleep"
        static let quickActivation          = "quickActivation"
    }
    
    // MARK: - Convenience Accessors
    var shouldActivateOnLaunch: Bool {
        set(should) { UserDefaults.standard.set(should, forKey: UserDefaults.Keys.shouldActivateOnLaunch) }
        get { return UserDefaults.standard.bool(forKey: UserDefaults.Keys.shouldActivateOnLaunch) }
    }
    
    var shouldLaunchAtLogin: Bool {
        set(should) { UserDefaults.standard.set(should, forKey: UserDefaults.Keys.shouldLaunchAtLogin) }
        get { return UserDefaults.standard.bool(forKey: UserDefaults.Keys.shouldLaunchAtLogin) }
    }
    
    var preventDisplaySleep: Bool {
        set(should) { UserDefaults.standard.set(should, forKey: UserDefaults.Keys.preventDisplaySleep) }
        get { return UserDefaults.standard.bool(forKey: UserDefaults.Keys.preventDisplaySleep) }
    }
    
    var defaultTimeout: Int {
        set(timeout) { UserDefaults.standard.set(timeout, forKey: UserDefaults.Keys.defaultTimeout) }
        get { return UserDefaults.standard.integer(forKey: UserDefaults.Keys.preventDisplaySleep) }
    }
    
    var alwaysShowApps: Bool {
        set(should) { UserDefaults.standard.set(should, forKey: UserDefaults.Keys.alwaysShowApps) }
        get { return UserDefaults.standard.bool(forKey: UserDefaults.Keys.alwaysShowApps) }
    }
    
    var sendNotifications: Bool {
        set(should) { UserDefaults.standard.set(should, forKey: UserDefaults.Keys.sendNotifications) }
        get { return UserDefaults.standard.bool(forKey: UserDefaults.Keys.sendNotifications) }
    }
    
    var endOfDaySelected: Bool {
        set(should) { UserDefaults.standard.set(should, forKey: UserDefaults.Keys.endOfDaySelected) }
        get { return UserDefaults.standard.bool(forKey: UserDefaults.Keys.endOfDaySelected) }
    }
    
    var stopAtForcedSleep: Bool {
        set(should) { UserDefaults.standard.set(should, forKey: UserDefaults.Keys.stopAtForcedSleep) }
        get { return UserDefaults.standard.bool(forKey: UserDefaults.Keys.stopAtForcedSleep) }
    }
    
    var quickActivation: Bool {
        set(should) { UserDefaults.standard.set(should, forKey: UserDefaults.Keys.quickActivation) }
        get { return UserDefaults.standard.bool(forKey: UserDefaults.Keys.quickActivation) }
    }
}
