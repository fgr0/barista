//
//  PreferencesWindowController.swift
//  Barista
//
//  Created by Franz Greiling on 07.06.17.
//  Copyright © 2018 Franz Greiling. All rights reserved.
//

import Cocoa

class PreferencesWindowController: NSWindowController {
    
    // MARK: - Creation
    class func defaultController() -> PreferencesWindowController {
        return NSStoryboard(
                name: NSStoryboard.Name("Preferences"),
                bundle: Bundle.main
            ).instantiateInitialController() as! PreferencesWindowController
    }
}
