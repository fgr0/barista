//
//  GeneralPreferencesView.swift
//  Barista
//
//  Created by Franz Greiling on 23.07.18.
//  Copyright © 2018 Franz Greiling. All rights reserved.
//

import Cocoa

class GeneralPreferencesView: NSView {
    
    @IBOutlet weak var launchAtLoginButton: NSButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.launchAtLoginButton.bind(
            NSBindingName("value"),
            to: NSApp.delegate as! AppDelegate,
            withKeyPath: #keyPath(AppDelegate.launchAtLogin),
            options: [
                NSBindingOption.raisesForNotApplicableKeys: true,
                NSBindingOption.conditionallySetsEnabled: true
            ]
        )
    }

}
