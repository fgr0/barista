//
//  TimeInterval+SimpleFormat.swift
//  Barista
//
//  Created by Franz Greiling on 25.10.17.
//  Copyright © 2017 Franz Greiling. All rights reserved.
//

import Foundation

extension TimeInterval {
    /// Creates a simple human readable string for the time interval
    func simpleFormat(_ style: DateComponentsFormatter.UnitsStyle = .full,
                      allowedUnits: NSCalendar.Unit = [.day, .hour, .minute],
                      maxUnitCount: Int = 3, padZeros: Bool = false) -> String? {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = allowedUnits
        formatter.unitsStyle = style
        formatter.maximumUnitCount = maxUnitCount
        if padZeros {
            formatter.zeroFormattingBehavior = .pad
        }
        
        return formatter.string(from: self)
    }
}
