//
//  TimeIntervalSliderCell.swift
//  Barista
//
//  Created by Franz Greiling on 27.10.17.
//  Copyright © 2017 Franz Greiling. All rights reserved.
//

import Cocoa

class TimeIntervalSliderCell: NSSliderCell {
    var snapToLast: Bool = false
    
    // MARK: - Override Tracking
    override func continueTracking(last lastPoint: NSPoint, current currentPoint: NSPoint, in controlView: NSView) -> Bool {
        if snapToLast {
            // Horizontal position of 2nd to last Tick Mark
            let x = self.rectOfTickMark(at: self.numberOfTickMarks - 2).origin.x
            if currentPoint.x >= x {
                self.allowsTickMarkValuesOnly = true
            } else {
                self.allowsTickMarkValuesOnly = false
            }
        }

        return super.continueTracking(last: lastPoint, current: currentPoint, in: controlView)
    }
}
