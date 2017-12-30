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

    
    // MARK: - Update Menu Items
    private var timer: Timer?
    
    func updateMenu() {
        let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName")!
        
        stateItem.title     = "\(appName): " + (powerMgmtController.isRunning ? "On" : "Off")
        self.updateTimeRemaining()
        activateItem.title  = "Turn \(appName) " + (powerMgmtController.isRunning ? "Off" : "On")
    }
    
    func updateTimeRemaining() {
        if let tl = powerMgmtController.timeLeft, tl > 0 {
            // Substract 0.5 'seconds' from the TimeInterval to ensure maxUnitCount of 2
            let timeLeft = TimeInterval(Double(tl)-0.5)
            
            let formatter = DateComponentsFormatter()
            formatter.allowedUnits = [.hour, .minute, .second]
            formatter.unitsStyle = .short
            formatter.includesTimeRemainingPhrase = true
            formatter.maximumUnitCount = 2
            //formatter.zeroFormattingBehavior = .pad
            
            timeRemainingItem.title = formatter.string(from: timeLeft)!
            timeRemainingItem.isHidden = false
            
            // While timeRemaining is shown, live-update its title
            guard self.timer == nil else { return }

            self.timer = Timer(timeInterval: 1.0, repeats: true) {_ in
                self.updateTimeRemaining()
            }
            RunLoop.current.add(self.timer!, forMode: RunLoopMode.eventTrackingRunLoopMode)
        } else {
            timeRemainingItem.isHidden = true
            self.timer?.invalidate()
            self.timer = nil
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
}
