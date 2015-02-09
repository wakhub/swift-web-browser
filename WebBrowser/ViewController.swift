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


final class ViewController: NSViewController, WebBrowserBehaviour, NSTextFieldDelegate {
    
    enum ToolbarItemTag: Int {
        case
        Back = 101,
        Forward = 102,
        Refresh = 103,
        URL = 201
    }
    
    @IBOutlet weak var webView: WebView?
    
    @IBOutlet weak var statusTextField: NSTextField?
    
    weak var backButton: NSButton?
    
    weak var forwardButton: NSButton?
    
    weak var refreshButton: NSButton?
    
    weak var URLTextField: NSTextField?
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let center = NSNotificationCenter.defaultCenter()
        center.addObserver(
            self,
            selector: "onShuoldAddBookmarkNotification:",
            name: ShouldAddBookmarkNotification,
            object: nil)
        center.addObserver(
            self,
            selector: "onShouldOpenBookmarkNotification:",
            name: ShouldOpenBookmarkNotification,
            object: nil)
        center.addObserver(
            self,
            selector: "onDidDeleteBookmarkNotification:",
            name: DidDeleteBookmarkNotification,
            object: nil)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        if let items = self.view.window?.toolbar?.items {
            for item in items {
                let toolbarItem = item as NSToolbarItem
                if let tag = ToolbarItemTag(rawValue: toolbarItem.tag) {
                    switch tag {
                    case .Back:
                        backButton = toolbarItem.view as NSButton?
                        backButton?.target = self
                        backButton?.action = "onClickBackButton:"
                    case .Forward:
                        forwardButton = toolbarItem.view as NSButton?
                        forwardButton?.target = self
                        forwardButton?.action = "onClickForwardButton:"
                    case .Refresh:
                        refreshButton = toolbarItem.view as NSButton?
                        refreshButton?.target = self
                        refreshButton?.action = "onClickRefreshButton:"
                    case .URL:
                        URLTextField = toolbarItem.view as NSTextField?
                        URLTextField?.delegate = self
                    }
                }
            }
        }
        loadURL(Const.defultURL)
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
    
    func onShouldAddBookmarkNotification(notification: NSNotification) {
        println("onShouldAddBookmarkNotification")
        let URL = currentURL
        if URL.isEmpty {
            return
        }
        let title = !currentTitle.isEmpty ? currentTitle : URL
        var insertedID: Int?
        Async
            .background({
                if let DB = DBHelper.DB() {
                    insertedID = Bookmark.query(DB).insert(
                        Bookmark.title <- title,
                        Bookmark.URL <- URL)
                }
            }).main({ [weak self] in
                if insertedID == nil {
                    self?.putStatus("Failed to add \(title) into bookmark")
                } else {
                    self?.putStatus("Added \(title) into bookmark")
                }
            })
    }
    
    func onShouldOpenBookmarkNotification(notification: NSNotification) {
        println("onShuoldOpenBookmarkNotification")
        if let info = notification.userInfo as [ String: String ]? {
            if let URL = info["URL"] {
                loadURL(URL)
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
            backButton?.enabled = webView.canGoBack
            forwardButton?.enabled = webView.canGoForward
            refreshButton?.enabled = !currentURL.isEmpty
        }
    }
    
    func getURLStringFromFrame(frame: WebFrame?) -> String? {
        return frame?.provisionalDataSource?.request.URL?.absoluteString
    }
    
    // MARK: - WebBrowserBehaviour
    
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
    
    func loadURL(URLOrKeyword: String) -> Bool {
        if URLOrKeyword.isEmpty {
            return false
        }
        let errors = Array(REValidation.validateObject(URLOrKeyword, name: "url", validators: ["url", "presence"]))
        let URLString = errors.isEmpty
            ? URLOrKeyword
            : String(format: Const.googleSearchURL, URLOrKeyword)
        URLTextField?.stringValue = URLString
        webView?.takeStringURLFrom(URLTextField)
        return true
    }
    
    func putStatus(status: String) {
        println(status)
        statusTextField?.stringValue = status
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
                URLTextField?.stringValue = URL
                refreshViews()
            }
            putStatus("Loading \(URL)")
        }
    }
    
    override func webView(sender: WebView!, didReceiveTitle title: String!, forFrame frame: WebFrame!) {
        if sender.mainFrame === frame {
            self.view.window?.title = title ?? ""
        }
    }
    
    override func webView(sender: WebView!, didReceiveServerRedirectForProvisionalLoadForFrame frame: WebFrame!) {
        if let URL = getURLStringFromFrame(frame) {
            if sender.mainFrame === frame && !URL.isEmpty {
                URLTextField?.stringValue = URL
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
        return loadURL(URLTextField?.stringValue ?? "")
    }
}
