//
//  AppDelegate.swift
//  WebBrowser
//
//  Created by wak on 2/5/15.
//  Copyright (c) 2015 wak. All rights reserved.
//

import Cocoa


@NSApplicationMain
final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        REValidation.registerDefaultValidators()
        REValidation.registerDefaultErrorMessages()
        
        Async.background({
            if let DB = DBHelper.DB() {
                Bookmark.createTable(DB)
                println("Bookmark table has been created")
            }
        })
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
}

