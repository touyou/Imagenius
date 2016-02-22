//
//  ViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/02/10.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import Accounts
import SwifteriOS

class MainViewController: UIViewController, UITabBarDelegate, UITableViewDelegate, UITableViewDataSource {
    var tweetArray: [JSONValue] = []
    @IBOutlet var timelineTableView: UITableView!
    var swifter: Swifter!
    var maxId: String!
    let saveData:NSUserDefaults = NSUserDefaults.standardUserDefaults()
    // 今どっちを選択しているか？
    var tlmode: String!
    // tabの処理
    @IBOutlet var mainTabBar: UITabBar!
    @IBOutlet var homeTabBarItem: UITabBarItem!
    @IBOutlet var replyTabBarItem: UITabBarItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mainTabBar.delegate = self
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if saveData.objectForKey("twitter") != nil {
            let account = saveData.objectForKey("twitter") as! ACAccount
            swifter = Swifter(account: account)
            tlmode = "home"
            mainTabBar.selectedItem = homeTabBarItem
            self.loadTweet()
        } else {
            // TableViewが空の時の画面を出す
        }
    }
    
    // tabBarが選択されたとき
    func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
        if item == homeTabBarItem {
            tlmode = "home"
            tweetArray = []
            self.loadTweet()
        } else if item == replyTabBarItem {
            tlmode = "reply"
            tweetArray = []
            self.loadTweet()
        }
    }
    
    // Tweetのロード
    func load(moreflag: Bool) {
        let failureHandler: ((NSError) -> Void) = { error in
            Utility.simpleAlert(String(error.localizedFailureReason), presentView: self)
        }
        let successHandler: (([JSONValue]?) -> Void) = { statuses in
            guard let tweets = statuses else { return }
            for var i = 0; i < tweets.count - 1; i++ {
                self.tweetArray.append(tweets[i])
            }
            self.maxId = tweets[tweets.count - 1]["id_str"].string
            self.timelineTableView.reloadData()
        }
        if !moreflag {
            if tlmode == "home" {
                self.swifter.getStatusesHomeTimelineWithCount(41, includeEntities: true, success: successHandler, failure: failureHandler)
            } else if tlmode == "reply" {
                self.swifter.getStatusesMentionTimelineWithCount(41, includeEntities: true, success: successHandler, failure: failureHandler)
            }
        } else {
            if tlmode == "home" {
                self.swifter.getStatusesHomeTimelineWithCount(41, sinceID: nil, maxID: self.maxId, trimUser: nil, contributorDetails: nil, includeEntities: true, success: successHandler, failure: failureHandler)
            } else if tlmode == "reply" {
                self.swifter.getStatusesMentionTimelineWithCount(41, sinceID: nil, maxID: self.maxId, trimUser: nil, contributorDetails: nil, includeEntities: true, success: successHandler, failure: failureHandler)
            }
        }
    }
    func loadTweet() {
        load(false)
    }
    func loadMore() {
        load(true)
    }
    
    // TableView関係
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tweetArray.count
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:TweetViewCell = tableView.dequeueReusableCellWithIdentifier("TweetCell")! as! TweetViewCell
        
        let tweet = tweetArray[indexPath.row]
        let userInfo = tweet["user"]
        
        cell.tweetLabel.text = tweet["text"].string
        cell.userLabel.text = userInfo["name"].string
        let userID = userInfo["screen_name"].string!
        cell.userIDLabel.text = "@\(userID)"
        let userImgPath:String = userInfo["profile_image_url_https"].string!
        let userImgURL:NSURL = NSURL(string: userImgPath)!
        let userImgPathData:NSData = NSData(contentsOfURL: userImgURL)!
        cell.userImgView.image = UIImage(data: userImgPathData)
        
        if (self.tweetArray.count - 1) == indexPath.row && self.maxId != "" {
            self.loadMore()
        }
        
        return cell
    }
}

