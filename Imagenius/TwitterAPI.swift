//
//  TwitterAPI.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/02/20.
//  Copyright © 2016年 touyou. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire
import Accounts
import Social

public class TwitterAPI {
    
    // MARK: - Properties
    
    internal(set) var apiURL: NSURL
    internal(set) var uploadURL: NSURL
    internal(set) var streamURL: NSURL
    internal(set) var userStreamURL: NSURL
    internal(set) var siteStreamURL: NSURL
    
    // MARK: - Initializers
    
    public convenience init(consumerKey: String, consumerSecret: String) {
        self.init(consumerKey: consumerKey, consumerSecret: consumerSecret, appOnly: false)
    }
    
    public init(consumerKey: String, consumerSecret: String, appOnly: Bool) {
        self.apiURL = NSURL(string: "https://api.twitter.com/1.1/")!
        self.uploadURL = NSURL(string: "https://upload.twitter.com/1.1/")!
        self.streamURL = NSURL(string: "https://stream.twitter.com/1.1/")!
        self.userStreamURL = NSURL(string: "https://userstream.twitter.com/1.1/")!
        self.siteStreamURL = NSURL(string: "https://sitestream.twitter.com/1.1/")!
    }
    
    public init(consumerKey: String, consumerSecret: String, oauthToken: String, oauthTokenSecret: String) {
        self.apiURL = NSURL(string: "https://api.twitter.com/1.1/")!
        self.uploadURL = NSURL(string: "https://upload.twitter.com/1.1/")!
        self.streamURL = NSURL(string: "https://stream.twitter.com/1.1/")!
        self.userStreamURL = NSURL(string: "https://userstream.twitter.com/1.1/")!
        self.siteStreamURL = NSURL(string: "https://sitestream.twitter.com/1.1/")!
    }
    
    public init(account: ACAccount) {
        self.apiURL = NSURL(string: "https://api.twitter.com/1.1/")!
        self.uploadURL = NSURL(string: "https://upload.twitter.com/1.1/")!
        self.streamURL = NSURL(string: "https://stream.twitter.com/1.1/")!
        self.userStreamURL = NSURL(string: "https://userstream.twitter.com/1.1/")!
        self.siteStreamURL = NSURL(string: "https://sitestream.twitter.com/1.1/")!
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

}