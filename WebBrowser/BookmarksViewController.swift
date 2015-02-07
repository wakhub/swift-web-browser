//
//  BookmarksViewController.swift
//  WebBrowser
//
//  Created by wak on 2/6/15.
//  Copyright (c) 2015 wak. All rights reserved.
//

import Cocoa
import Foundation

import SQLite


final class BookmarksViewController : NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    
    @IBOutlet weak var tableView: NSTableView?
    
    var bookmarks: [Bookmark]?
    
    private enum ColumnIdentifier: String {
        case Title = "Title", URL = "URL"
    }
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        refreshViews()
    }
    
    // MARK: -
    
    func refreshViews() {
        if let DB = DBHelper.DB() {
            Bookmark.createTable(DB)
            bookmarks = Array(Bookmark.query(DB)).map {
                (var row) -> Bookmark in
                Bookmark(row)
            }
        }
        tableView?.reloadData()
    }
    
    func openBookmark(bookmark: Bookmark) {
        let notification = NSNotification(
            name: OpenBookmarkNotification,
            object: self,
            userInfo: bookmark.asDictionary())
        NSNotificationCenter.defaultCenter().postNotification(notification)
        dismissViewController(self)
    }
    
    func deleteBookmark(bookmark: Bookmark) {
        if let DB = DBHelper.DB() {
            if let ID = Bookmark.query(DB).filter(Bookmark.ID == bookmark.ID).delete() {
                let notification = NSNotification(
                    name: DidDeleteBookmarkNotification,
                    object: self,
                    userInfo: bookmark.asDictionary())
                refreshViews()
                NSNotificationCenter.defaultCenter().postNotification(notification)
            }
        }
    }
    
    @IBAction func onSelectOpenMenuItem(sender: NSMenuItem) {
        if let row = tableView?.clickedRow {
            if let bookmark = bookmarks?[row] {
                openBookmark(bookmark)
            }
        }
    }
    
    @IBAction func onSelectDeleteMenuItem(sender: NSMenuItem) {
        println("delete")
        
        if let row = tableView?.clickedRow {
            if let bookmark = bookmarks?[row] {
                deleteBookmark(bookmark)
            }
        }
    }
    
    // MARK: - NSTableViewDataSource
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return bookmarks?.count ?? 0
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let identifier = ColumnIdentifier(rawValue: tableColumn!.identifier)
        var view: NSTextField? = tableView.makeViewWithIdentifier("Cell", owner: self) as NSTextField?
        if view == nil  {
            view = NSTextField(frame: NSRect())
            view!.identifier = identifier!.rawValue
        }
        view!.editable = false
        view!.bezeled = false
        view!.backgroundColor = NSColor.clearColor()
        
        switch identifier! {
        case .Title:
            view!.stringValue = bookmarks?[row].title ?? ""
        case .URL:
            view!.stringValue = bookmarks?[row].URL ?? ""
        }
        
        return view as NSView?
    }
    
    // MARK: - NSTableViewDelegate
    
    func tableView(tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        if let bookmark = bookmarks?[row] {
            openBookmark(bookmark)
            return true
        }
        return false
    }
}