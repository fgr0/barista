//
//  ClickableTextField.swift
//  Barista
//
//  Created by Franz Greiling on 19.04.18.
//  Copyright © 2018 Franz Greiling. All rights reserved.
//

import Cocoa

class ClickableTextField: NSTextField {
    @IBInspectable var url: String = ""

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }

    override func resetCursorRects() {
        self.addCursorRect(self.bounds, cursor: NSCursor.pointingHand)
    }
    
    override func mouseDown(with event: NSEvent) {
        if let url = URL(string: self.url) {
            NSWorkspace.shared.open(url)
        }
    }
}
