//
//  TimeIntervalSlider.swift
//  Barista
//
//  Created by Franz Greiling on 26.10.17.
//  Copyright © 2017 Franz Greiling. All rights reserved.
//

import Cocoa

class TimeIntervalSlider: NSSlider {
    
    // MARK: - Initializers
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: Setup
    override func awakeFromNib() {
        self.updateLabels()
    }

    // MARK: - Accessing the Time Interval Value
    var timeIntervals: [TimeInterval] = [0.0] {
        didSet {
            self.resetValueLimits()
            self.updateLabels()
        }
    }
    
    var timeValue: TimeInterval {
        set(value) {
            for i in 0 ..< (timeIntervals.count - 1) {
                if (value >= timeIntervals[i] && value <= timeIntervals[i+1]) {
                    self.doubleValue = TimeIntervalSlider.mapValue(
                        value,
                        from: (timeIntervals[i], timeIntervals[i + 1]),
                        to: (Double(i), Double(i + 1))
                    )!
                }
            }
            
            // VALUE COULD NOT BE MAPPED
            // TODO: Error Handling
        }
        get {
            let value = self.doubleValue
            
            for i in 0 ..< (timeIntervals.count - 1) {
                if (value >= Double(i) && value <= Double(i+1)) {
                    return TimeIntervalSlider.mapValue(
                        value,
                        from: (Double(i), Double(i + 1)),
                        to: (timeIntervals[i], timeIntervals[i + 1])
                    )!
                }
            }

            // VALUE COULD NOT BE MAPPED
            // TODO: Error Handling
            return Double.infinity
        }
    }
    
    // MARK: - "Never" Interval
    // TODO: Make Snapping happen
    @objc var showInfinity: Bool = false {
        didSet {
            (self.cell as! TimeIntervalSliderCell).snapToLast = showInfinity
            self.resetValueLimits()
            self.updateLabels()
        }
    }
    @objc var infinityLabel: String = "Never"
    
    // MARK: - Labels
    private var labels: [NSTextField] = []
    
    @objc var showLabels: Bool = false {
        didSet {
            self.updateLabels()
        }
    }
    
    var labelForTickMarks: [Int] = [] {
        didSet {
            self.updateLabels()
        }
    }
    
    fileprivate func updateLabels() {
        while labels.count > 0 {
            let l = labels.popLast()!
            l.removeFromSuperview()
        }
        
        if showLabels {
            for m in self.labelForTickMarks {
                let text = self.timeIntervals[m].simpleFormat(.short)!
                let label = self.createLabelForTickMark(m, withString: text)!
                labels.append(label)
                self.superview?.addSubview(label)
            }
            
            if showInfinity {
                let label = self.createLabelForTickMark(self.numberOfTickMarks - 1, withString: self.infinityLabel, alignment: NSTextAlignment.left)!
                labels.append(label)
                self.superview?.addSubview(label)
            }
        }
    }

    /// Generates a label for given tickmark
    fileprivate func createLabelForTickMark(_ at: Int, withString text: String, alignment: NSTextAlignment = NSTextAlignment.center) -> NSTextField? {
        
        guard at < self.numberOfTickMarks else { return nil }
        
        var label: NSTextField
        if #available(OSX 10.12, *) {
            label = NSTextField(labelWithString: text)
            label.font = NSFont.systemFont(ofSize: 10.0)
        } else {
            label = NSTextField()
            label.stringValue = text
            label.textColor = NSColor.labelColor
            label.font = NSFont.systemFont(ofSize: 10.0)
            label.backgroundColor = NSColor.controlColor
            label.isEditable = false
            label.isBordered = false
        }
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
        
        return label
    }

    
    // MARK: - Helper
    /// Maps a value from one Interval onto another
    fileprivate static func mapValue(_ value: Double, from: (Double, Double), to: (Double, Double)) -> Double? {
        guard value >= from.0 && value <= from.1 else { return nil }
        
        let fromRange = from.1 - from.0
        let toRange = to.1 - to.0
        
        return (value - from.0) * toRange / fromRange + to.0
    }
    
    fileprivate func resetValueLimits() {
        if showInfinity {
            self.maxValue = Double(self.timeIntervals.count)
            self.numberOfTickMarks = self.timeIntervals.count + 1
        } else {
            self.maxValue = Double(self.timeIntervals.count) - 1.0
            self.numberOfTickMarks = self.timeIntervals.count
        }
    }
}
