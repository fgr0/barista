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
    @IBOutlet weak var timeRemainingItem: NSMenuItem!
    @IBOutlet weak var activateItem: NSMenuItem!
    
    @IBOutlet weak var appListItem: NSMenuItem!
    @IBOutlet weak var appListSystem: NSMenuItem!
    @IBOutlet weak var appListSeparator: NSMenuItem!
    
    @IBOutlet weak var powerMgmtController: PowerMgmtController!
    
    
    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Setup Status Bar
        self.statusBarItem.button!.title = "zZ"
        self.statusBarItem.button?.appearsDisabled = !powerMgmtController.enabled
        self.statusBarItem.menu = menu
        
        powerMgmtController.addObserver(self)
    }
    
    deinit {
        powerMgmtController.removeObserver(self)
        timer?.invalidate()
    }

    
    // MARK: - Update Menu Items
    private var timer: Timer?
    
    func updateMenu() {
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName")!
        
        // Set Standart Elements
        stateItem.title     = "\(appName): " + (powerMgmtController.enabled ? "On" : "Off")
        timeRemainingItem.isHidden = true
        activateItem.title  = "Turn \(appName) " + (powerMgmtController.enabled ? "Off" : "On")
        
        appListItem.isHidden = true
        appListSeparator.isHidden = true
        
        for item in menu.items {
            if item.tag == 1 {
                menu.removeItem(item)
            }
        }
        
        // Update Time Remaining
        if let tl = powerMgmtController.timeLeft, tl > 0 {
            let title = TimeInterval(tl).simpleFormat(style: .short, units: [.day, .hour, .minute, .second],
                                                      maxCount: 2, timeRemaining: true)!
            timeRemainingItem.title = title
            timeRemainingItem.isHidden = false
        }
        
        // Update List of Apps
        if let apps = powerMgmtController.assertionsByApp() {
            appListItem.isHidden = false
            appListSeparator.isHidden = false
            
            let index = menu.index(of: appListSeparator)
            
            for app in apps {
                let appItem = NSMenuItem()
                appItem.tag = 1
                appItem.title = app.app.localizedName!
                appItem.image = app.app.icon
                appItem.image?.size = CGSize(width: 16, height: 16)
                appItem.representedObject = app
                appItem.target = self
                appItem.action = #selector(applicationAction(_:))
                menu.insertItem(appItem, at: index)
            }
        }
    }


    // MARK: - Actions
    @objc func applicationAction(_ sender: NSMenuItem) {
        guard let app = sender.representedObject as? AssertingApp else { return }
        
        if let cmdKey = NSApp.currentEvent?.modifierFlags.contains(.command), cmdKey {
            app.app.terminate()
        } else {
            app.app.activate(options: [.activateIgnoringOtherApps])
        }
    }
}


// MARK: - PowerMgmtObserver Protocol
extension MenuController: PowerMgmtObserver {
    func assertionChanged(isRunning: Bool, preventDisplaySleep: Bool) {
        self.statusBarItem.button?.appearsDisabled = !isRunning
    }
}


// MARK: - NSMenuDelegate Protocol
extension MenuController: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        guard menu == self.menu else { return }
        self.updateMenu()
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        guard self.timer == nil else { return }
        self.timer = Timer(timeInterval: 1.0, repeats: true) { _ in self.updateMenu() }
        RunLoop.current.add(self.timer!, forMode: RunLoopMode.eventTrackingRunLoopMode)
    }
    
    func menuDidClose(_ menu: NSMenu) {
        self.timer?.invalidate()
        self.timer = nil
    }
}
