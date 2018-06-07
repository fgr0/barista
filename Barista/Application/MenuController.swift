//
//  StatusBarMenu.swift
//  Barista
//
//  Created by Franz Greiling on 29.05.17.
//  Copyright © 2018 Franz Greiling. All rights reserved.
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
    
    @IBOutlet weak var assertionController: AssertionController!
    
    
    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Setup Status Bar
        self.statusItem.button!.title = "zZ"
        self.statusItem.button?.appearsDisabled = !assertionController.enabled
        self.statusItem.button?.target = self
        self.statusItem.button?.action = #selector(toggleAssertionAction(_:))
        self.statusItem.menu = self.menu
        self.statusItem.behavior = .terminationOnRemoval
        
        assertionController.addObserver(self)
        
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
        assertionController.removeObserver(self)
        self.timer?.invalidate()
    }

    
    // MARK: - Update Menu Items
    private var timer: Timer?
    private var override: Bool = false

    func updateMenu() {
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName")!
        
        // Set Standart Elements
        stateItem.title     = "\(appName): " + (assertionController.enabled ? "On" : "Off")
        timeRemainingItem.isHidden = true
        activateItem.title  = "Turn \(appName) " + (assertionController.enabled ? "Off" : "On")
        
        appListItem.isHidden = true
        appListSeparator.isHidden = true
        
        for item in menu.items {
            if item.tag == 1 {
                menu.removeItem(item)
            }
        }
        
        // Update Time Remaining
        if let tl = assertionController.timeLeft, tl > 0 {
            let title = TimeInterval(tl).simpleFormat(style: .short, units: [.day, .hour, .minute],
                                                      maxCount: 2, timeRemaining: true)!
            timeRemainingItem.title = title
            timeRemainingItem.isHidden = false
        }
        
        // Update List of Apps if wanted
        
        guard override || UserDefaults.standard.showAdvancedInformation else { return }
        
        let infos = AssertionInfo.byProcess()
        let numString = String.localizedStringWithFormat(
            NSLocalizedString("number_apps", comment: ""), infos.count)
        
        appListItem.isHidden = false
        appListSeparator.isHidden = false
        appListItem.title = "\(numString) Preventing Sleep"
        
        guard override || UserDefaults.standard.verbosityLevel >= 1 else { return }
        
        for info in infos {
            let index = menu.index(of: appListSeparator)
            let numString = String.localizedStringWithFormat(
                NSLocalizedString("number_assertions", comment: ""), info.ids.count)
            let pdsString = "Prevents \(info.preventsDisplaySleep ? "Display" : "Idle") Sleep"
            
            let appItem = NSMenuItem()
            appItem.tag = 1
            appItem.title = info.name
            appItem.toolTip = numString + "; " + pdsString
            appItem.image = info.icon
            appItem.image?.size = CGSize(width: 16, height: 16)
            appItem.representedObject = info
            appItem.target = self
            appItem.action = #selector(applicationAction(_:))
            menu.insertItem(appItem, at: index)
            
            // Add Verbose Information if wanted
            guard override || UserDefaults.standard.verbosityLevel >= 2 else { continue }
            
            let startDate = info.timeStarted
            let startFormatter = DateFormatter()
            startFormatter.dateStyle = .long
            startFormatter.timeStyle = .short
            startFormatter.doesRelativeDateFormatting = true
            
            let timeRemaining = info.timeLeft ?? 0
            let timeoutString = TimeInterval(timeRemaining).simpleFormat(
                style: .short, units: [.day, .hour, .minute], maxCount: 2)!
            
            menu.insertDescItem(pdsString, at: index+1)
            menu.insertDescItem("Started: \(startFormatter.string(from: startDate))", at: index+2)
            if timeRemaining > 0 {
                menu.insertDescItem("Timeout in: \(timeoutString)", at: index+3)
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
        if assertionController.enabled {
            assertionController.stopAssertion()
        } else {
            assertionController.startAssertion()
        }
    }
    
    @IBAction func activateForAction(_ sender: NSMenuItem) {
        guard let ti = sender.representedObject as? TimeInterval else { return }
        
        assertionController.startAssertion(withTimeout: UInt(ti))
    }
    
    @IBAction func activateIndefinitlyAction(_ sender: NSMenuItem) {
        assertionController.startAssertion(withTimeout: 0)
    }
    
    @IBAction func activateEndOfDayAction(_ sender: NSMenuItem) {
        assertionController.startAssertionForRestOfDay()
    }
}


// MARK: - AssertionObserver Protocol
extension MenuController: AssertionObserver {
    func assertionChanged(isRunning: Bool, preventDisplaySleep: Bool) {
        self.statusItem.button?.appearsDisabled = !isRunning
    }
    
    func systemAssertionsChanged(preventsIdleSleep: Bool, preventsDisplaySleep: Bool) {

    }
}


// MARK: - NSMenuDelegate Protocol
extension MenuController: NSMenuDelegate {
    func menuNeedsUpdate(_ menu: NSMenu) {
        guard menu == self.menu else { return }
        
        self.override = (NSApp.currentEvent?.modifierFlags.contains(.option))!
        self.updateMenu()
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        guard self.timer == nil else { return }
        self.timer = Timer(timeInterval: 1.0, repeats: true) { _ in self.updateMenu() }
        RunLoop.current.add(self.timer!, forMode: RunLoopMode.eventTrackingRunLoopMode)
    }
    
    func menuDidClose(_ menu: NSMenu) {
        self.override = false
        self.statusItem.button?.highlight(false)
        self.timer?.invalidate()
        self.timer = nil
    }
}
