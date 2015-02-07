//
//  Bookmark.swift
//  WebBrowser
//
//  Created by wak on 2/6/15.
//  Copyright (c) 2015 wak. All rights reserved.
//

import Foundation

import SQLite


private let _ID = Expression<Int>("id")

private let _title = Expression<String>("title")

private let _URL = Expression<String>("url")


final class Bookmark {
    
    class var ID: Expression<Int> { return _ID }
    
    class var title: Expression<String> { return _title }
    
    class var URL: Expression<String> { return _URL }
    
    class func query(DB: Database) -> Query {
        return DB["bookmark"]
    }
    
    class func createTable(DB: Database) {
        DB.create(table: query(DB), ifNotExists: true) { t in
            t.column(_ID, primaryKey: true)
            t.column(_title)
            t.column(_URL)
        }
    }
    
    // MARK: -
    
    let ID: Int
    
    let title: String
    
    let URL: String
    
    init(_ row: Row) {
        self.ID = row.get(_ID)
        self.title = row.get(_title)
        self.URL = row.get(_URL)
    }
    
    func asDictionary() -> [ String: String ]{
        return [ "ID": "\(ID)", "title": title, "URL": URL ]
    }
}