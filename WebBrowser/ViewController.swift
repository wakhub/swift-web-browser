//
//  ViewController.swift
//  WebBrowser
//
//  Created by wak on 2/5/15.
//  Copyright (c) 2015 wak. All rights reserved.
//

import Cocoa
import WebKit

import SQLite


final class ViewController: NSViewController, NSTextFieldDelegate {
    
    enum ToolbarItemTag: Int {
        case
        Back = 101,
        Forward = 102,
        Refresh = 103,
        URL = 201
    }
    
    let defaultURL: String = "http://example.com"
    
    let googleSearchURL: String = "http://google.com/search?q=%@"
    
    @IBOutlet weak var webView: WebView?
    
    @IBOutlet weak var statusTextField: NSTextField?
    
    var toolbarItemBackButton: NSButton?
    
    var toolbarItemForwardButton: NSButton?
    
    var toolbarItemRefreshButton: NSButton?
    
    var toolbarItemURLTextField: NSTextField?
    
    var currentURL: String {
        if let item = webView?.backForwardList.currentItem {
            return item.URLString ?? ""
        }
        return ""
    }
    
    var currentTitle: String {
        if let item  = webView?.backForwardList.currentItem {
            return item.title ?? ""
        }
        return ""
    }
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let center = NSNotificationCenter.defaultCenter()
        center.addObserver(
            self,
            selector: "onAddBookmarkNotification:",
            name: AddBookmarkNotification,
            object: nil)
        center.addObserver(
            self,
            selector: "onOpenBookmarkNotification:",
            name: OpenBookmarkNotification,
            object: nil)
        center.addObserver(
            self,
            selector: "onDidDeleteBookmarkNotification:",
            name: DidDeleteBookmarkNotification,
            object: nil)
        
        REValidation.registerDefaultValidators()
        REValidation.registerDefaultErrorMessages()
        
        if let DB = DBHelper.DB() {
            Bookmark.createTable(DB)
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        if let items = self.view.window?.toolbar?.items {
            for item in items {
                let toolbarItem = item as NSToolbarItem
                if let tag = ToolbarItemTag(rawValue: toolbarItem.tag) {
                    switch tag {
                    case .Back:
                        toolbarItemBackButton = toolbarItem.view as NSButton?
                        toolbarItemBackButton?.target = self
                        toolbarItemBackButton?.action = "onClickBackButton:"
                    case .Forward:
                        toolbarItemForwardButton = toolbarItem.view as NSButton?
                        toolbarItemForwardButton?.target = self
                        toolbarItemForwardButton?.action = "onClickForwardButton:"
                    case .Refresh:
                        toolbarItemRefreshButton = toolbarItem.view as NSButton?
                        toolbarItemRefreshButton?.target = self
                        toolbarItemRefreshButton?.action = "onClickRefreshButton:"
                    case .URL:
                        toolbarItemURLTextField = toolbarItem.view as NSTextField?
                        toolbarItemURLTextField?.delegate = self
                    }
                }
            }
        }
        toolbarItemURLTextField?.stringValue = defaultURL
        webView?.takeStringURLFrom(toolbarItemURLTextField)
    }
    
    // MARK: -
    
    func onClickBackButton(sender: NSButton) {
        webView?.goBack()
    }
    
    func onClickForwardButton(sender: NSButton) {
        webView?.goForward()
    }
    
    func onClickRefreshButton(sender: NSButton) {
        webView?.reload(nil)
    }
    
    func onAddBookmarkNotification(notification: NSNotification) {
        println("onAddBookmarkNotification")
        if let DB = DBHelper.DB() {
            let insertedID: Int? = Bookmark.query(DB).insert(
                Bookmark.title <- currentTitle,
                Bookmark.URL <- currentURL)
            if insertedID != nil {
                putStatus("Added \(currentTitle) into bookmark")
            } else {
                putStatus("Failed to add \(currentTitle) into bookmark")
            }
        }
    }
    
    func onOpenBookmarkNotification(notification: NSNotification) {
        println("onOpenBookmarkNotification")
        if let info = notification.userInfo as [ String: String ]? {
            if let URL = info["URL"] {
                toolbarItemURLTextField?.stringValue = URL
                webView?.takeStringURLFrom(toolbarItemURLTextField)
            }
        }
    }
    
    func onDidDeleteBookmarkNotification(notification: NSNotification) {
        println("onDidDeleteBookmarkNotification")
        if let info = notification.userInfo as [ String: String ]? {
            if let title = info["title"] {
                putStatus("\"\(title)\" has been removed from bookmark")
            }
        }
    }
    
    func refreshViews() {
        if let webView = webView {
            toolbarItemBackButton?.enabled = webView.canGoBack
            toolbarItemForwardButton?.enabled = webView.canGoForward
            toolbarItemRefreshButton?.enabled = !currentURL.isEmpty
        }
    }
    
    func putStatus(status: String) {
        println(status)
        statusTextField?.stringValue = status
    }
    
    func getURLStringFromFrame(frame: WebFrame?) -> String? {
        return frame?.provisionalDataSource?.request.URL?.absoluteString
    }
    
    // MARK: - WebFrameLoadDelegate (informal)
    
    override func webView(sender: WebView!, didFailProvisionalLoadWithError error: NSError!, forFrame frame: WebFrame!) {
        if let URL = getURLStringFromFrame(frame) {
            putStatus("Failed to load \(URL)")
        }
    }
    
    override func webView(sender: WebView!, didStartProvisionalLoadForFrame frame: WebFrame!) {
        if let URL = getURLStringFromFrame(frame) {
            if sender.mainFrame === frame && !URL.isEmpty {
                toolbarItemURLTextField?.stringValue = URL
                refreshViews()
            }
            putStatus("Loading \(URL)")
        }
    }
    
    override func webView(sender: WebView!, didReceiveTitle title: String!, forFrame frame: WebFrame!) {
        self.view.window?.title = title ?? ""
    }
    
    override func webView(sender: WebView!, didReceiveServerRedirectForProvisionalLoadForFrame frame: WebFrame!) {
        if let URL = getURLStringFromFrame(frame) {
            if sender.mainFrame === frame && !URL.isEmpty {
                toolbarItemURLTextField?.stringValue = URL
                putStatus("Redirecting to \(URL)")
                refreshViews()
            }
        }
    }
    
    override func webView(sender: WebView!, didFailLoadWithError error: NSError!, forFrame frame: WebFrame!) {
        putStatus("Error: \(error)")
    }
    
    override func webView(sender: WebView!, didFinishLoadForFrame frame: WebFrame!) {
        if sender.mainFrame === frame  {
            refreshViews()
        }
        putStatus("Finish loading")
    }
    
    // MARK: - NSTextFieldDelegate
    
    func control(control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
        let URL = toolbarItemURLTextField?.stringValue ?? ""
        let errors = Array(REValidation.validateObject(
            URL, name: "url", validators: ["url", "presence"]))
        if !errors.isEmpty {
            println("\(errors)")
            if URL.isEmpty {
                return false
            }
            toolbarItemURLTextField?.stringValue = String(format: googleSearchURL, URL)
        }
        webView?.takeStringURLFrom(toolbarItemURLTextField)
        return true
    }
}
