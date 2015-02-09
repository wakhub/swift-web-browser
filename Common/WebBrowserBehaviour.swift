//
//  WebBrowserBehaviour.swift
//  WebBrowser
//
//  Created by wak on 2/9/15.
//  Copyright (c) 2015 wak. All rights reserved.
//

protocol WebBrowserBehaviour {
    
    var currentTitle: String { get }
    
    var currentURL: String { get }
    
    func loadURL(URLOrKeyword: String) -> Bool
    
    func putStatus(status: String)
}