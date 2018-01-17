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
    let statusItem: NSStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    
    @IBOutlet var menu: NSMenu!
    
    @IBOutlet weak var stateItem: NSMenuItem!
    @IBOutlet weak var timeRemainingItem: NSMenuItem!
    @IBOutlet weak var activateItem: NSMenuItem!
    
    @IBOutlet weak var activateForItem: NSMenuItem!
    
    @IBOutlet weak var appListItem: NSMenuItem!
    @IBOutlet weak var appListSeparator: NSMenuItem!
    
    @IBOutlet weak var powerMgmtController: PowerMgmtController!
    
    
    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Setup Status Bar
        self.statusItem.button!.title = "zZ"
        self.statusItem.button?.appearsDisabled = !powerMgmtController.enabled
        self.statusItem.button?.target = self
        self.statusItem.button?.action = #selector(toggleAssertionAction(_:))
        self.statusItem.menu = self.menu
        self.statusItem.behavior = .terminationOnRemoval
        
        powerMgmtController.addObserver(self)
        
        // Setup "Activate for" Submenu
        for item in (activateForItem.submenu?.items)! {
            if item.tag == 1 {
                let ti = TimeInterval(item.title)!
                item.representedObject = ti
                item.title = ti.simpleFormat(maxCount: 1)!
                item.target = self
                item.action = #selector(activateForAction(_:))
            }
        }
    }
    
    deinit {
        powerMgmtController.removeObserver(self)
        self.timer?.invalidate()
    }

    
    // MARK: - Update Menu Items
    private var timer: Timer?
    private var verbose = false

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
        
        // Update List of Apps if wanted
        guard verbose || UserDefaults.standard.alwaysShowApps else { return }
        
        if let apps = powerMgmtController.assertionsByApp() {
            appListItem.isHidden = false
            appListSeparator.isHidden = false
            
            for (app, list) in apps {
                let index = menu.index(of: appListSeparator)
                let numString = String.localizedStringWithFormat(
                    NSLocalizedString( "number_assertions", comment: ""), list.count)
                let pdsString = "Prevents \(list.contains { $0.preventsDisplaySleep } ? "Display" : "Idle") Sleep"
                
                let appItem = NSMenuItem()
                appItem.tag = 1
                appItem.title = app.localizedName!
                appItem.toolTip = numString + "; " + pdsString
                appItem.image = app.icon
                appItem.image?.size = CGSize(width: 16, height: 16)
                appItem.representedObject = app
                appItem.target = self
                appItem.action = #selector(applicationAction(_:))
                menu.insertItem(appItem, at: index)
                
                // Add Verbose Information if wanted
                guard verbose else { continue }
                
                let startDate = list.reduce(Date.distantFuture) { min($0, $1.timeStarted) }
                let startFormatter = DateFormatter()
                startFormatter.dateStyle = .long
                startFormatter.timeStyle = .short
                startFormatter.doesRelativeDateFormatting = true

                let timeRemaining = list.reduce(0) { max($0, $1.timeLeft ?? 0)}
                let timeoutString = TimeInterval(timeRemaining).simpleFormat(
                    style: .short, units: [.day, .hour, .minute, .second], maxCount: 2)!

                menu.insertDescItem(pdsString, at: index+1)
                menu.insertDescItem("Started: \(startFormatter.string(from: startDate))", at: index+2)
                if timeRemaining > 0 {
                    menu.insertDescItem("Timeout in: \(timeoutString)", at: index+3)
                }
            }
        }
    }


    // MARK: - Actions
    @IBAction func applicationAction(_ sender: NSMenuItem) {
        guard let app = sender.representedObject as? NSRunningApplication else { return }
        
        if let cmdKey = NSApp.currentEvent?.modifierFlags.contains(.command), cmdKey {
            app.terminate()
        } else {
            app.activate(options: [.activateIgnoringOtherApps])
        }
    }
    
    @IBAction func toggleAssertionAction(_ sender: NSObject) {
        if powerMgmtController.enabled {
            powerMgmtController.stopAssertion()
        } else {
            powerMgmtController.startAssertion()
        }
    }
    
    @IBAction func activateForAction(_ sender: NSMenuItem) {
        guard let ti = sender.representedObject as? TimeInterval else { return }
        
        powerMgmtController.startAssertion(withTimeout: UInt(ti))
    }
    
    @IBAction func activateIndefinitlyAction(_ sender: NSMenuItem) {
        powerMgmtController.startAssertion(withTimeout: 0)
    }
    
    @IBAction func activateEndOfDayAction(_ sender: NSMenuItem) {
        powerMgmtController.startAssertionForRestOfDay()
    }
}


// MARK: - PowerMgmtObserver Protocol
extension MenuController: PowerMgmtObserver {
    func assertionChanged(isRunning: Bool, preventDisplaySleep: Bool) {
        self.statusItem.button?.appearsDisabled = !isRunning
    }
}


// MARK: - NSMenuDelegate Protocol
extension MenuController: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        guard menu == self.menu else { return }
        
        self.verbose = self.verbose || (NSApp.currentEvent?.modifierFlags.contains(.option))!
        self.updateMenu()
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        guard self.timer == nil else { return }
        self.timer = Timer(timeInterval: 1.0, repeats: true) { _ in self.updateMenu() }
        RunLoop.current.add(self.timer!, forMode: RunLoopMode.eventTrackingRunLoopMode)
    }
    
    func menuDidClose(_ menu: NSMenu) {
        self.verbose = false
        self.statusItem.button?.highlight(false)
        self.timer?.invalidate()
        self.timer = nil
    }
}
