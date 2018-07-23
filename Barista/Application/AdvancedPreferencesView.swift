//
//  AdvancedPreferencesView.swift
//  Barista
//
//  Created by Franz Greiling on 23.07.18.
//  Copyright © 2018 Franz Greiling. All rights reserved.
//

import Cocoa

class AdvancedPreferencesView: NSView {

    // MARK: - Outlets
    @IBOutlet weak var displayModeStack: NSStackView!

    
    // MARK: - Lifecycle
    override func awakeFromNib() {
        displayModeStack.views.forEach {view in
            let rb = view as! NSButton
            rb.state = rb.tag == UserDefaults.standard.appListDetail ? .on : .off
            rb.isEnabled = UserDefaults.standard.showAppList
        }
    }

    
    // MARK: - Actions
    @IBAction func showAppList(_ sender: NSButton) {
        displayModeStack.views.forEach {rb in
            (rb as? NSButton)?.isEnabled = sender.state == NSControl.StateValue.on
        }
    }
    
    @IBAction func displayModeSelected(_ sender: NSButton) {
        UserDefaults.standard.appListDetail = sender.tag
    }
}
