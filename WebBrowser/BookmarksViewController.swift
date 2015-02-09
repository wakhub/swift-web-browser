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
    
    enum ColumnIdentifier: String {
        case Title = "Title", URL = "URL"
    }
    
    let cellIdentifier = "Cell"
    
    @IBOutlet weak var tableView: NSTableView?
    
    var bookmarks: [Bookmark]?
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reloadData()
    }
    
    // MARK: -
    
    func reloadData() {
        Async
            .background({ [weak self] in
                if let DB = DBHelper.DB() {
                    Bookmark.createTable(DB)
                    self?.bookmarks = Array(Bookmark.query(DB)).map {
                        (var row) -> Bookmark in
                        Bookmark(row)
                    }
                }
            }).main({ [weak self] in
                self?.tableView?.reloadData()
                return
            })
    }
    
    func openBookmark(bookmark: Bookmark) {
        let notification = NSNotification(
            name: ShouldOpenBookmarkNotification,
            object: self,
            userInfo: bookmark.asDictionary())
        NSNotificationCenter.defaultCenter().postNotification(notification)
        dismissViewController(self)
    }
    
    func deleteBookmark(bookmark: Bookmark) {
        Async
            .background({ [weak self] in
                if let DB = DBHelper.DB() {
                    if let ID = Bookmark.query(DB).filter(Bookmark.ID == bookmark.ID).delete() {
                        let notification = NSNotification(
                            name: DidDeleteBookmarkNotification,
                            object: self?,
                            userInfo: bookmark.asDictionary())
                        NSNotificationCenter.defaultCenter().postNotification(notification)
                    }
                }
            }).main({ [weak self] in
                self?.reloadData()
                return
            })
    }
    
    @IBAction func onSelectOpenMenuItem(sender: NSMenuItem) {
        if let row = tableView?.clickedRow {
            if let bookmark = bookmarks?[row] {
                openBookmark(bookmark)
            }
        }
    }
    
    @IBAction func onSelectDeleteMenuItem(sender: NSMenuItem) {
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
        var view: NSTextField? = tableView.makeViewWithIdentifier(cellIdentifier, owner: self) as NSTextField?
        if let tableColumn = tableColumn {
            if let identifier = ColumnIdentifier(rawValue: tableColumn.identifier) {
                if view == nil {
                    view = NSTextField(frame: NSRect())
                    view?.identifier = identifier.rawValue
                }
                view?.editable = false
                view?.bezeled = false
                view?.backgroundColor = NSColor.clearColor()
                
                switch identifier {
                case .Title:
                    view?.stringValue = bookmarks?[row].title ?? ""
                case .URL:
                    view?.stringValue = bookmarks?[row].URL ?? ""
                }
            }
        }
        
        return view?
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