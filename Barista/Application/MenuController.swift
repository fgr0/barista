//
//  StatusBarMenu.swift
//  Barista
//
//  Created by Franz Greiling on 29.05.17.
//  Copyright © 2017 Franz Greiling. All rights reserved.
//

import Cocoa
import Foundation

class MenuController: NSObject {
    
    // MARK: - UI Outlets
    let statusBarItem: NSStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    
    @IBOutlet var menu: NSMenu!
    
    @IBOutlet weak var stateItem: NSMenuItem!
    @IBOutlet weak var activateItem: NSMenuItem!
    
    @IBOutlet weak var appListItem: NSMenuItem!
    @IBOutlet weak var appListSystem: NSMenuItem!
    @IBOutlet weak var appListSeparator: NSMenuItem!
    
    @IBOutlet weak var assertionController: AssertionController!
    
    // MARK: - Setup
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Setup Status Bar
        self.statusBarItem.button!.title = "zZ"
        self.statusBarItem.button?.appearsDisabled = !assertionController.isRunning
        self.statusBarItem.menu = menu
    }
    


    // MARK: - IB Actions
    @IBAction func setMode(_ sender: NSMenuItem) {
        if assertionController.isRunning {
            assertionController.stopAssertion()
        } else {
            assertionController.startAssertion()
        }
        
        self.statusBarItem.button?.appearsDisabled = !assertionController.isRunning
    }
}

// MARK: - NSMenuDelegate Protocol
extension MenuController: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        guard menu == self.menu else { return }
        return
//        if assertion.enabled {
//            stateItem.title = "\(appName): On"
//            activateItem.title = "Turn \(appName) Off"
//            statusBarItem.button?.appearsDisabled = false
//        } else {
//            stateItem.title = "\(appName): Off"
//            activateItem.title = "Turn \(appName) On"
//            statusBarItem.button?.appearsDisabled = true
//        }
    }
}
