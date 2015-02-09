//
//  ActionsViewController.swift
//  WebBrowser
//
//  Created by wak on 2/7/15.
//  Copyright (c) 2015 wak. All rights reserved.
//

import Foundation
import Cocoa


final class ActionsViewController : NSViewController {
    
    @IBOutlet weak var addBookmarkButton: NSButton?
    
    @IBAction func onClickAddBookmarkButton(sender: NSButton) {
        NSNotificationCenter.defaultCenter()
            .postNotificationName(ShouldAddBookmarkNotification, object: self)
        dismissViewController(self)
    }
}
