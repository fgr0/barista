//
//  NSMenu+insertDescItem.swift
//  Barista
//
//  Created by Franz Greiling on 05.01.18.
//  Copyright © 2018 Franz Greiling. All rights reserved.
//

import Cocoa

extension NSMenu {
    func insertDescItem(_ title: String, withIndentation indent: Int = 2, at index: Int) {
        let numItem = NSMenuItem()
        numItem.tag = 1
        numItem.title = title
        numItem.indentationLevel = indent
        numItem.isEnabled = false
        self.insertItem(numItem, at: index)
    }
}
