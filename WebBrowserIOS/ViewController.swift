//
//  IOSViewController.swift
//  WebBrowserIOS
//
//  Created by wak on 2/9/15.
//  Copyright (c) 2015 wak. All rights reserved.
//

import UIKit

import SQLite


final class ViewController: UIViewController,
WebBrowserBehaviour, UISearchBarDelegate, UIActionSheetDelegate, UIWebViewDelegate {
    
    @IBOutlet weak var titleLabel: UILabel?
    
    @IBOutlet weak var searchBar: UISearchBar?
    
    @IBOutlet weak var webView: UIWebView?
    
    @IBOutlet weak var statusLabel: UILabel?
    
    @IBOutlet weak var backButton: UIBarButtonItem?
    
    @IBOutlet weak var forwardButton: UIBarButtonItem?
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(
            self,
            selector: "onShouldOpenBookmarkNotification:",
            name: ShouldOpenBookmarkNotification,
            object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBarHidden = true
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        loadURL(Const.defultURL)
    }
    
    // MARK: -
    
    @IBAction func onClickBackButton(sender: UIBarButtonItem) {
        webView?.goBack()
    }
    
    @IBAction func onClickForwardButton(sender: UIBarButtonItem) {
        webView?.goForward();
    }
    
    @IBAction func onClickRefreshButton(sender: UIBarButtonItem) {
        webView?.reload()
    }
    
    @IBAction func onClickActionsButton(sender: UIBarButtonItem) {
        UIActionSheet(
            title: "Actions",
            delegate: self,
            cancelButtonTitle: "Cancel",
            destructiveButtonTitle: "Bookmark").showFromBarButtonItem(sender, animated: true)
        
    }
    
    func onShouldOpenBookmarkNotification(notification: NSNotification) {
        println("onShouldOpenBookmarkNotification")
        if let info = notification.userInfo as [ String: String ]? {
            if let URL = info["URL"] {
                loadURL(URL)
            }
        }
    }
    
    func addBookmark() {
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
    
    func refreshViews() {
        titleLabel?.text = currentTitle
        backButton?.enabled = webView?.canGoBack ?? false
        forwardButton?.enabled = webView?.canGoForward ?? false
    }
    
    // MARK: - WebBrowserBehaviour
    
    var currentURL: String {
        return webView?.request?.URL.absoluteString ?? ""
    }
    
    var currentTitle: String {
        return webView?.stringByEvaluatingJavaScriptFromString("document.title") ?? ""
    }
    
    func loadURL(URLOrKeyword: String) -> Bool {
        if URLOrKeyword.isEmpty {
            return false
        }
        let errors = Array(REValidation.validateObject(URLOrKeyword, name: "url", validators: ["url", "presence"]))
        let URLString = errors.isEmpty
            ? URLOrKeyword
            : String(format: Const.googleSearchURL, URLOrKeyword)
        println("URL: \(URLString)")
        if let URL = NSURL(string: URLString) {
            webView?.loadRequest(NSURLRequest(URL: URL))
            searchBar?.text = URL.absoluteString
            return true
        }
        return false
    }
    
    func putStatus(status: String) {
        println(status)
        statusLabel?.text = status
    }
    
    // MARK: - UIWebViewDelegate
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        let URL = request.URL
        if navigationType != .Other {
            searchBar?.text = URL.absoluteString
        }
        putStatus("Loading \(URL)")
        return true
    }
    
    func webViewDidStartLoad(webView: UIWebView) {
        refreshViews()
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        if let URL = webView.request?.URL.absoluteString {
            putStatus("Failed to load \(URL)")
        }
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        putStatus("Finish loading")
        refreshViews()
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarShouldEndEditing(searchBar: UISearchBar) -> Bool {
        loadURL(searchBar.text)
        return true
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        loadURL(searchBar.text)
    }
    
    func actionSheet(actionSheet: UIActionSheet, clickedButtonAtIndex buttonIndex: Int) {
        if buttonIndex == 0 {
            addBookmark()
        }
    }
}

