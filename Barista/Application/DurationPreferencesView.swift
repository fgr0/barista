//
//  DurationPreferencesView.swift
//  Barista
//
//  Created by Franz Greiling on 23.07.18.
//  Copyright © 2018 Franz Greiling. All rights reserved.
//

import Cocoa

class DurationPreferencesView: NSView {
    @objc dynamic private var defaultTimeout: Int = 0
    
    
    // MARK: - Outlets
    @IBOutlet weak var durationSection: NSView!
      @IBOutlet weak var radioDurationTypeIndefinitly: NSButton!
      @IBOutlet weak var radioDurationTypeTimeout: NSButton!
      @IBOutlet weak var radioDurationTypeHour: NSButton!
      @IBOutlet weak var durationSlider: TimeIntervalSlider!
      @IBOutlet weak var selectedTimeField: NSTextField!
      @IBOutlet weak var durationTimePicker: NSDatePicker!
    
    @IBOutlet weak var line: NSBox!
    
    @IBOutlet weak var batterySection: NSView!
      @IBOutlet weak var batteryThresholdSlider: NSSlider!
    
    
    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Setup Radio Buttons
        let durationType = UserDefaults.standard.durationType
        radioDurationTypeIndefinitly.state = radioDurationTypeIndefinitly.tag == durationType ? .on : .off
        radioDurationTypeTimeout.state = radioDurationTypeTimeout.tag == durationType ? .on : .off
        radioDurationTypeHour.state = radioDurationTypeHour.tag == durationType ? .on : .off

        // Register Timeout with User Defaults
        self.defaultTimeout = UserDefaults.standard.durationTimeout
        UserDefaults.standard.bind(
            NSBindingName(rawValue: UserDefaults.Keys.durationTimeout),
            to: self,
            withKeyPath: #keyPath(defaultTimeout),
            options: nil)
        
        // Setup Duration Slider
        durationSlider.timeIntervals = [60, 300, 600, 900, 1800, 2700, 3600, 5400, 7200, 10800, 14400, 18000, 21600]
        durationSlider.labelForTickMarks = [0, 3, 6, 9, 12]
        durationSlider.timeValue = Double(self.defaultTimeout)
        durationSlider.isEnabled = radioDurationTypeTimeout.tag == UserDefaults.standard.durationType
        
        // Setup Date Picker
        durationTimePicker.dateValue = DateFormatter.date(
            from: UserDefaults.standard.durationEndAtTime, withFormat:  "HH:mm")!
        
        
        // Setup Battery Slider
        let pcntFormatter = NumberFormatter()
        pcntFormatter.numberStyle = .percent
        pcntFormatter.multiplier = 100
        pcntFormatter.maximumFractionDigits = 0
        
        for i in [0, 4, 8] {
            let v = batteryThresholdSlider.tickMarkValue(at: i)
            let label = batteryThresholdSlider.createLabelForTickMark(i, withString: pcntFormatter.string(from: NSNumber(value: v))!)
            batteryThresholdSlider.superview?.addSubview(label!)
        }
        
        // Hide Battery-related Preferences if there is no battery
        if !PowerSource.hasBattery {
            line.isHidden = true
            batterySection.isHidden = true
        }
    }
    
    
    // MARK: - Interface Actions
    @IBAction func defaultDurationTypeSelected(_ sender: NSButton) {
        UserDefaults.standard.durationType = sender.tag
        
        durationSlider.isEnabled = sender == radioDurationTypeTimeout
        durationTimePicker.isEnabled = sender == radioDurationTypeHour
    }
    
    @IBAction func durationSliderChanged(_ sender: TimeIntervalSlider) {
        switch NSApp.currentEvent!.type {
        case .leftMouseDown:
            selectedTimeField.isHidden = false
            fallthrough
        case .leftMouseDragged:
            selectedTimeField.stringValue =
                sender.timeValue > 0 ? sender.timeValue.simpleFormat()! : sender.infinityLabel
            self.defaultTimeout = Int(sender.timeValue/60) * 60
        case .leftMouseUp:
            selectedTimeField.isHidden = true
        default:
            break
        }
    }
    
    @IBAction func durationTimePickerChanged(_ sender: NSDatePicker) {
        UserDefaults.standard.durationEndAtTime = DateFormatter.string(from: sender.dateValue, withFormat: "HH:mm")!
    }
}
