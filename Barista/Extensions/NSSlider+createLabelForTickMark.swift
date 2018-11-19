//
//  NSSlider+createLabelForTickMark.swift
//  Barista
//
//  Created by Franz Greiling on 07.08.18.
//  Copyright © 2018 Franz Greiling. All rights reserved.
//

import Cocoa

extension NSSlider {

    /// Generates a label for given tickmark
    func createLabelForTickMark(_ at: Int, withString text: String, alignment: NSTextAlignment = NSTextAlignment.center) -> NSTextField? {
        
        guard at < self.numberOfTickMarks else { return nil }
        
        var label: NSTextField
        label = NSTextField(labelWithString: text)
        label.controlSize = .mini
        label.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: .mini))
        label.alignment = alignment
        label.sizeToFit()
        
        // Calculate position
        // NOTE: The hardcoded offsets are kinda eyeballed
        let pTick = self.rectOfTickMark(at: at).origin
        let pSlider = self.frame.origin
        var point = CGPoint(x: pTick.x + pSlider.x, y: pSlider.y - 3)
        
        point.y -= label.frame.height
        
        switch alignment {
        case .center:
            point.x -= label.bounds.width/2
        case .left:
            point.x -= 6
        case .right:
            point.x -= label.bounds.width - 6
        case .natural, .justified:
            point.x -= label.bounds.width - 6
        }
        
        label.frame.origin = point
        label.frame.origin.x.round(.toNearestOrEven)
        label.frame.origin.y.round(.toNearestOrEven)
        
        return label
    }
}
