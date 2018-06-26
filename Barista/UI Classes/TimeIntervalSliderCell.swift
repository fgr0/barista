//
//  TimeIntervalSliderCell.swift
//  Barista
//
//  Created by Franz Greiling on 27.10.17.
//  Copyright © 2018 Franz Greiling. All rights reserved.
//

import Cocoa

class TimeIntervalSliderCell: NSSliderCell {
    var snapToLast: Bool = false
    
    // MARK: - Override Tracking
    override func startTracking(at startPoint: NSPoint, in controlView: NSView) -> Bool {
        checkSnapToLast(forPoint: startPoint)
        return super.startTracking(at: startPoint, in: controlView)
    }
    
    override func continueTracking(last lastPoint: NSPoint, current currentPoint: NSPoint, in controlView: NSView) -> Bool {
        checkSnapToLast(forPoint: currentPoint)
        return super.continueTracking(last: lastPoint, current: currentPoint, in: controlView)
    }
    
    fileprivate func checkSnapToLast(forPoint point: NSPoint) {
        if snapToLast {
            // Horizontal position of 2nd to last Tick Mark
            let x = self.rectOfTickMark(at: self.numberOfTickMarks - 2).origin.x
            
            if point.x > x {
                self.allowsTickMarkValuesOnly = true
                
                // Force new Handle position
                self.doubleValue = self.closestTickMarkValue(toValue: self.doubleValue)
            } else {
                self.allowsTickMarkValuesOnly = false
            }
        }
    }
}
