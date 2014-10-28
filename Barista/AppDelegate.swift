//
//  AppDelegate.swift
//  Barista
//
//  Created by Franz Greiling on 28/10/14.
//  Copyright (c) 2014 Franz Greiling. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var assertion: PowerAssertion?
    var assertion2: PowerAssertion?

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        assertion = PowerAssertion(name: "Test", type: .PreventUserIdleSystemSleep, level: .On)
        
        println("[")
        for (key, value) in PowerAssertion.getFilteredAssertionStatus()! {
            println("  \(key): \(value),")
        }
        println("]")
        println(PowerAssertion.getFilteredAssertionCount()!)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }


}

