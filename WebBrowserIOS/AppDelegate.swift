//
//  AppDelegate.swift
//  WebBrowserIOS
//
//  Created by wak on 2/9/15.
//  Copyright (c) 2015 wak. All rights reserved.
//

import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
        REValidation.registerDefaultValidators()
        REValidation.registerDefaultErrorMessages()
        
        Async.background({
            if let DB = DBHelper.DB() {
                Bookmark.createTable(DB)
                println("Bookmark table has been created")
            }
        })
        
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
    }
    
    func applicationWillTerminate(application: UIApplication) {
    }
}

