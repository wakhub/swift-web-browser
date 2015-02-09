//
//  IOSBookmarksViewController.swift
//  WebBrowser
//
//  Created by wak on 2/9/15.
//  Copyright (c) 2015 wak. All rights reserved.
//

import UIKit

import SQLite


final class BookmarksViewControler: UITableViewController {
    
    let cellIdentifier = "Cell"
    
    var bookmarks: [Bookmark]?
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBarHidden = false
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
        navigationController?.popToRootViewControllerAnimated(true)
    }
    
    func deleteBookmark(bookmark: Bookmark) {
        var deletedID: Int?
        Async
            .background({
                if let DB = DBHelper.DB() {
                    deletedID = Bookmark.query(DB).filter(Bookmark.ID == bookmark.ID).delete()
                }
            })
            .main({ [weak self] in
                if deletedID == nil {
                    println("Failed to delete \(bookmark.title)")
                } else {
                    println("\(bookmark.title) has been deleted")
                    self?.reloadData()
                }
            })
    }
    
    // MARK: - UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bookmarks?.count ?? 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as UITableViewCell?
        if cell == nil {
            cell = UITableViewCell(style: .Subtitle, reuseIdentifier: cellIdentifier)
        }
        if cell != nil {
            if let bookmark = bookmarks?[indexPath.row] {
                cell?.textLabel.text = bookmark.title ?? ""
                cell?.detailTextLabel?.text = bookmark.URL ?? ""
            }
        }
        return cell!
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let bookmark = bookmarks?[indexPath.row] {
            openBookmark(bookmark)
        }
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            if let bookmark = bookmarks?[indexPath.row] {
                deleteBookmark(bookmark)
            }
        }
        return
    }
}