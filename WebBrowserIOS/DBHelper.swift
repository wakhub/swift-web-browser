//
//  DBHelper.swift
//  WebBrowser
//
//  Created by wak on 2/9/15.
//  Copyright (c) 2015 wak. All rights reserved.
//

import Foundation

import SQLite

final class DBHelper {
    
    class func DB() -> Database? {
        let path = NSSearchPathForDirectoriesInDomains(
            .DocumentDirectory, .UserDomainMask, true
            ).first as String
        
        return Database("\(path)/db.sqlite3")
    }
}