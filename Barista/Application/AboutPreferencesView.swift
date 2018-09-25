//
//  AboutPreferencesView.swift
//  Barista
//
//  Created by Franz Greiling on 23.07.18.
//  Copyright © 2018 Franz Greiling. All rights reserved.
//

import Cocoa

class AboutPreferencesView: NSView {

    @IBOutlet weak var versionLabel: NSTextField!
    @IBOutlet weak var aboutTextView: NSTextView!
    
    override func awakeFromNib() {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let buildnr = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        
        versionLabel.stringValue = "Version \(version) (\(buildnr))"
        
        aboutTextView.readRTFD(fromFile: Bundle.main.path(forResource: "About", ofType: "rtf")!)
        
        aboutTextView.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        aboutTextView.textColor = NSColor.labelColor
        
        if #available(OSX 10.14, *) {
            aboutTextView.linkTextAttributes?[.foregroundColor] = NSColor.controlAccentColor
        }
    }
    
}
