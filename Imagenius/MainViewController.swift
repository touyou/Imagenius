//
//  ViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/02/10.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit

class MainViewController: UIViewController, UITabBarDelegate, UITableViewDelegate, UITableViewDataSource {

    var tweetArray: NSArray!
    @IBOutlet var timelineTableView: UITableView!
    
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
        tlmode = "home"
        mainTabBar.selectedItem = homeTabBarItem
        self.tabBar(mainTabBar, didSelectItem: homeTabBarItem)
    }
    
    func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
        if item == homeTabBarItem {
            tlmode = "home"
            self.loadTweet()
        } else {
            tlmode = "reply"
            self.loadTweet()
        }
    }
    
    // Tweetのロード
    func loadTweet() {
        
    }
    
    // TableView関係
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tweetArray.count
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:UITableViewCell = tableView.dequeueReusableCellWithIdentifier("TweetCell")! as UITableViewCell
        
        let tweetTextView:UITextView = cell.viewWithTag(3) as! UITextView
        let userLabel:UILabel = cell.viewWithTag(1) as! UILabel
        let userIDLabel:UILabel = cell.viewWithTag(2) as! UILabel
        let userImgView:UIImageView = cell.viewWithTag(4) as! UIImageView
        
        let tweet:NSDictionary = tweetArray[indexPath.row] as! NSDictionary
        let userInfo:NSDictionary = tweet["user"] as! NSDictionary
        
        tweetTextView.text = tweet["text"] as! String
        userLabel.text = userInfo["name"] as? String
        let userID = userInfo["screen_name"] as! String
        userIDLabel.text = "@\(userID)"
        let userImgPath:String = userInfo["profile_image_url"] as! String
        let userImgURL:NSURL = NSURL(string: userImgPath)!
        let userImgPathData:NSData = NSData(contentsOfURL: userImgURL)!
        userImgView.image = UIImage(data: userImgPathData)
        
        return cell
    }
}

