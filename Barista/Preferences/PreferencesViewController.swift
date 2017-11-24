//
//  PreferencesViewController.swift
//  Barista
//
//  Created by Franz Greiling on 21.06.17.
//  Copyright © 2017 Franz Greiling. All rights reserved.
//

import Cocoa

class PreferencesViewController: NSViewController {
    @IBOutlet weak var launchAtLoginButton: NSButton!
    
    @IBOutlet weak var buttonIndefinitly: NSButton!
    @IBOutlet @objc weak var buttonTurnOffAfter: NSButton!
    @IBOutlet weak var buttonTurnOffMorning: NSButton!
    

    @IBOutlet weak var slider: TimeIntervalSlider!
    
    @IBOutlet weak var selectedTimeField: NSTextField!
    
    // MARK: - View Events
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.launchAtLoginButton.bind(
            NSBindingName("value"),
            to: NSApp.delegate as! AppDelegate,
            withKeyPath: "loginItemController.enabled",
            options: [
                NSBindingOption.raisesForNotApplicableKeys: true,
                NSBindingOption.conditionallySetsEnabled: true
            ]
        )

        slider.timeIntervals = [60, 300, 600, 900, 1800, 2700, 3600, 5400, 7200, 10800, 14400, 18000, 21600]
        slider.labelForTickMarks = [0, 3, 6, 9, 12]
        
    }
    
    // MARK: - Interface Actions
    @IBAction func defaultDurationTypeSelected(_ sender: NSButton) {
        slider.isEnabled = false

        switch sender {
        case buttonTurnOffAfter:
            slider.isEnabled = true
        case buttonTurnOffMorning:
            break
        default: break
        }
    }
    
    @IBAction func durationSliderChanged(_ sender: TimeIntervalSlider) {
        switch NSApp.currentEvent!.type {
        case .leftMouseDown:
            selectedTimeField.isHidden = false
            fallthrough
        case .leftMouseDragged:
            selectedTimeField.stringValue =
                sender.timeValue != Double.infinity ? sender.timeValue.simpleFormat()! : sender.infinityLabel
        case .leftMouseUp:
            selectedTimeField.isHidden = true
        default:
            break
        }
    }
}
