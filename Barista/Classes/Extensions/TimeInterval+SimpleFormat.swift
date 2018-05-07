//
//  TimeInterval+SimpleFormat.swift
//  Barista
//
//  Created by Franz Greiling on 25.10.17.
//  Copyright © 2018 Franz Greiling. All rights reserved.
//

import Foundation

extension TimeInterval {
    /// Creates a simple human readable string for the time interval
    func simpleFormat(style: DateComponentsFormatter.UnitsStyle = .full,
                      units: NSCalendar.Unit = [.day, .hour, .minute],
                      maxCount: Int = 2,
                      timeRemaining: Bool = false) -> String? {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = units
        formatter.unitsStyle = style
        formatter.maximumUnitCount = maxCount
        formatter.includesTimeRemainingPhrase = timeRemaining
        
        return formatter.string(from: self)
    }
}
