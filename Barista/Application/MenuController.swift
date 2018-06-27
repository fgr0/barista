//
//  StatusBarMenu.swift
//  Barista
//
//  Created by Franz Greiling on 29.05.17.
//  Copyright © 2018 Franz Greiling. All rights reserved.
//

import Cocoa
import Foundation

private enum MenuItemTag: Int {
    case hidden = 1
    case temporary = 2
    case interval = 3
}

class MenuController: NSObject {
    
    // MARK: - UI Outlets
    let statusItem: NSStatusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    
    @IBOutlet var menu: NSMenu!
    
    @IBOutlet weak var stateItem: NSMenuItem!
    @IBOutlet weak var timeRemainingItem: NSMenuItem!
    @IBOutlet weak var activateItem: NSMenuItem!
    
    @IBOutlet weak var activateForItem: NSMenuItem!
    
    @IBOutlet weak var uptimeItem: NSMenuItem!
    @IBOutlet weak var awakeForItem: NSMenuItem!
    @IBOutlet weak var infoSeparator: NSMenuItem!
    
    @IBOutlet weak var appListItem: NSMenuItem!
    @IBOutlet weak var appListSeparator: NSMenuItem!
    
    @IBOutlet weak var powerMgmtController: PowerMgmtController!
    
    
    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Setup Status Bar
        self.statusItem.button!.title = "zZ"
        self.statusItem.button?.appearsDisabled = !powerMgmtController.isPreventingSleep
        self.statusItem.button?.target = self
        self.statusItem.button?.action = #selector(toggleAssertionAction(_:))
        self.statusItem.menu = self.menu
        self.statusItem.behavior = .terminationOnRemoval
        
        powerMgmtController.addObserver(self)
        
        // Setup "Activate for" Submenu
        for item in (activateForItem.submenu?.items)! {
            if item.tag == MenuItemTag.interval.rawValue {
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
    private var override: Bool = false

    func updateMenu() {
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName")!
        
        // Set Standart Elements
        stateItem.title     = "\(appName): " + (powerMgmtController.isPreventingSleep ? "On" : "Off")
        timeRemainingItem.isHidden = true
        activateItem.title  = "Turn \(appName) " + (powerMgmtController.isPreventingSleep ? "Off" : "On")
        
        // Reset Item
        for item in menu.items {
            if let tag = MenuItemTag(rawValue: item.tag) {
                switch tag {
                case .hidden:
                    item.isHidden = true
                case .temporary:
                    menu.removeItem(item)
                default: break
                }
            }
        }
        
        // Update Time Remaining
        if let tl = powerMgmtController.timeLeft, tl > 0 {
            let title = TimeInterval(tl).simpleFormat(style: .short, units: [.day, .hour, .minute],
                                                      maxCount: 2, timeRemaining: true)!
            timeRemainingItem.title = title
            timeRemainingItem.isHidden = false
        }
        
        // Update List of Apps if wanted
        menuShowApps(override: self.override)
        menuShowInfo(override: self.override)
    }
    
    private func menuShowInfo(override: Bool) {
        guard override || UserDefaults.standard.showUptime else { return }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        let uptime = SystemTime.systemUptime.simpleFormat(style: .short, units: [.day, .hour, .minute, .second], maxCount: 3)!
        
        uptimeItem.isHidden = false
        uptimeItem.title = "Uptime: \(uptime)"
        uptimeItem.toolTip = "Booted at \(dateFormatter.string(from: SystemTime.boot!))"
        
        let awakeSince: String
        if let lastWake = SystemTime.lastWake {
            let ti = Date().timeIntervalSince(lastWake)
            awakeSince = ti.simpleFormat(style: .short, units: [.day, .hour, .minute, .second], maxCount: 3)!
        } else {
            awakeSince = uptime
        }
        
        awakeForItem.isHidden = false
        awakeForItem.title = "Awake For: \(awakeSince)"
        
        infoSeparator.isHidden = false
    }
    
    private func menuShowApps(override: Bool) {
        guard override || UserDefaults.standard.showAppList else { return }
        
        let infos = AssertionInfo.byProcess()
        let numString = String.localizedStringWithFormat(
            NSLocalizedString("number_apps", comment: ""), infos.count)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
        
        appListItem.isHidden = false
        appListSeparator.isHidden = false
        appListItem.title = "\(numString) Preventing Sleep"
        
        guard override || (UserDefaults.standard.showAppList && UserDefaults.standard.appListDetail >= 1)
            else { return }
        
        for info in infos {
            let index = menu.index(of: appListSeparator)
            let numString = String.localizedStringWithFormat(
                NSLocalizedString("number_assertions", comment: ""), info.ids.count)
            let pdsString = "Prevents \(info.preventsDisplaySleep ? "Display" : "Idle") Sleep"
            
            let appItem = NSMenuItem()
            appItem.tag = MenuItemTag.temporary.rawValue
            appItem.title = info.name
            appItem.toolTip = numString + "; " + pdsString
            appItem.image = info.icon
            appItem.image?.size = CGSize(width: 16, height: 16)
            appItem.representedObject = info
            appItem.target = self
            appItem.action = #selector(applicationAction(_:))
            menu.insertItem(appItem, at: index)
            
            // Add Verbose Information if wanted
            guard override || UserDefaults.standard.appListDetail >= 2 else { continue }
            
            let startDate = info.timeStarted
            
            let timeRemaining = info.timeLeft ?? 0
            let timeoutString = TimeInterval(timeRemaining).simpleFormat(
                style: .short, units: [.day, .hour, .minute], maxCount: 2)!
            
            menu.insertDescItem(pdsString, at: index+1)
            menu.insertDescItem("Started: \(dateFormatter.string(from: startDate))", at: index+2)
            if timeRemaining > 0 {
                menu.insertDescItem("Timeout in: \(timeoutString)", at: index+3)
            }
        }
    }


    // MARK: - Actions
    @IBAction func applicationAction(_ sender: NSMenuItem) {
        guard let pid = (sender.representedObject as? AssertionInfo)?.pid,
            let app = NSRunningApplication(processIdentifier: pid)
            else { return }
        
        if let cmdKey = NSApp.currentEvent?.modifierFlags.contains(.command), cmdKey {
            app.terminate() // Doesn't Work
        } else {
            app.activate(options: [.activateIgnoringOtherApps])
        }
    }
    
    @IBAction func toggleAssertionAction(_ sender: NSObject) {
        if powerMgmtController.isPreventingSleep {
            powerMgmtController.stopPreventingSleep()
        } else {
            powerMgmtController.preventSleep()
        }
    }
    
    @IBAction func activateForAction(_ sender: NSMenuItem) {
        guard let ti = sender.representedObject as? TimeInterval else { return }
        
        powerMgmtController.preventSleep(withTimeout: UInt(ti))
    }
    
    @IBAction func activateIndefinitlyAction(_ sender: NSMenuItem) {
        powerMgmtController.preventSleep(withTimeout: 0)
    }
    
    @IBAction func activateEndOfDayAction(_ sender: NSMenuItem) {
        powerMgmtController.preventSleepUntilEndOfDay()
    }
}


// MARK: - AssertionObserver Protocol
extension MenuController: PowerMgmtObserver {
    func startedPreventingSleep(for: TimeInterval) {
        self.statusItem.button?.appearsDisabled = false
    }
    
    func stoppedPreventingSleep(after: TimeInterval, because reason: StoppedPreventingSleepReason) {
        self.statusItem.button?.appearsDisabled = true
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
        RunLoop.current.add(self.timer!, forMode: RunLoop.Mode.eventTracking)
    }
    
    func menuDidClose(_ menu: NSMenu) {
        self.override = false
        self.statusItem.button?.highlight(false)
        self.timer?.invalidate()
        self.timer = nil
    }
}
