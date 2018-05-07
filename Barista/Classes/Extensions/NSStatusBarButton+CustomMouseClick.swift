//
//  NSStatusBarButton+CustomMouseClick.swift
//  Barista
//
//  Created by Franz Greiling on 17.01.18.
//  Copyright © 2018 Franz Greiling. All rights reserved.
//

import Cocoa

// Fix highlighting issues and implement Quick Activation feature
extension NSStatusBarButton {
    override open func mouseDown(with event: NSEvent) {
        if UserDefaults.standard.quickActivation &&
            !(event.modifierFlags.contains(.control) || event.modifierFlags.contains(.option)) {
            self.highlight(true)
            return
        }
        
        super.mouseDown(with: event)
    }
    
    override open func mouseUp(with event: NSEvent) {
        if UserDefaults.standard.quickActivation &&
            !(event.modifierFlags.contains(.control) || event.modifierFlags.contains(.option)) {
            NSApp.sendAction(self.action!, to: self.target, from: self)
            self.highlight(false)
        }
        
        super.mouseUp(with: event)
    }
}
