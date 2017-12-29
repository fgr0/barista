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
    
    @IBOutlet weak var powerMgmtController: PowerMgmtController!
    
    // MARK: - Setup
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Setup Status Bar
        self.statusBarItem.button!.title = "zZ"
        self.statusBarItem.button?.appearsDisabled = !powerMgmtController.isRunning
        self.statusBarItem.menu = menu
        
        powerMgmtController.addObserver(self)
    }
    
    deinit {
        powerMgmtController.removeObserver(self)
    }
}


// MARK: - PowerMgmtObserver Protocol
extension MenuController: PowerMgmtObserver {
    func assertionChanged(isRunning: Bool, preventDisplaySleep: Bool) {
        self.statusBarItem.button?.appearsDisabled = !isRunning
        
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName")!
        
        if isRunning {
            stateItem.title = "\(appName): On"
            activateItem.title = "Turn \(appName) Off"
        } else {
            stateItem.title = "\(appName): Off"
            activateItem.title = "Turn \(appName) On"
        }
    }
}


// MARK: - NSMenuDelegate Protocol
extension MenuController: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        guard menu == self.menu else { return }
        return
    }
}
