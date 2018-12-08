//
//  DateFormatter+StringConversion.swift
//  Barista
//
//  Created by Franz Greiling on 23.07.18.
//  Copyright © 2018 Franz Greiling. All rights reserved.
//

import Foundation

extension DateFormatter {
    static func date(from: String, withFormat format: String) -> Date? {
        let df = DateFormatter()
        df.dateFormat = format
        
        return df.date(from: from)
    }
    
    static func string(from: Date, withFormat format: String) -> String? {
        let df = DateFormatter()
        df.dateFormat = format
        
        return df.string(from: from)
    }
}
