//
//  DatabaseHelper.swift
//  WebBrowser
//
//  Created by wak on 2/6/15.
//  Copyright (c) 2015 wak. All rights reserved.
//

import Foundation

import SQLite


private var instance: Database?


final class DBHelper {
    
    class func DB() -> Database? {
        if instance != nil {
            return instance
        }
        let path =
            NSSearchPathForDirectoriesInDomains(
                .ApplicationSupportDirectory,
                .UserDomainMask, true).first as String
            + NSBundle.mainBundle().bundleIdentifier!
        
        NSFileManager.defaultManager().createDirectoryAtPath(
            path, withIntermediateDirectories: true, attributes: nil, error: nil
        )
        
        instance = Database("\(path)/db.sqlite3")
        
        return instance
    }   
}
