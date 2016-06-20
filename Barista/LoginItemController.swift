//
//  LoginItemController.swift
//  Barista
//
//  Created by Franz Greiling on 19.11.14.
//  Copyright (c) 2014 Franz Greiling. All rights reserved.
//

import Foundation
import ServiceManagement

class LoginItemController: NSObject {
    private let helper: NSBundle
    
    // Controlls the login iteam and UserDefaults
    var enabled: Bool {
        didSet {
            if !SMLoginItemSetEnabled(helper.bundleIdentifier!, self.enabled) {
                NSLog("SMLoginItemSetEnabled \(helper.bundleIdentifier!) failed")
            } else {
                NSUserDefaults.standardUserDefaults().setBool(self.enabled, forKey: Settings.launchOnStart.rawValue)
            }
        }
    }
    
    // Singleton Implementation
    class func sharedController() -> LoginItemController {
        struct Static {
            static let instance: LoginItemController = LoginItemController()
        }
        return Static.instance
    }
    
    private override init() {
        let url = NSURL(fileURLWithPath: NSBundle.mainBundle().bundlePath)
            .URLByAppendingPathComponent("Contents/Library/LoginItems/BaristaHelper.app")!
        
        self.helper = NSBundle(path: url.path!)!
        self.enabled = NSUserDefaults.standardUserDefaults().boolForKey(Settings.launchOnStart.rawValue)
        
        // Register URL with Launch Services
        if LSRegisterURL(url, true) != 0 {
            NSLog("LSRegisterURL failed")
        }

        super.init()
    }
}
