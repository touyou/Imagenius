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
import TTTAttributedLabel
import DZNEmptyDataSet
import SWTableViewCell

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource, SWTableViewCellDelegate {
    var tweetArray: [JSONValue] = []
    var swifter: Swifter!
    var maxId: String!
    var replyID: String?
    var replyStr: String?
    let saveData:NSUserDefaults = NSUserDefaults.standardUserDefaults()
    var refreshControl: UIRefreshControl!
    var accountImg: UIImage?
    var account: ACAccount?
    let accountStore = ACAccountStore()
    var accounts = [ACAccount]()
    
    @IBOutlet var timelineTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.timelineTableView.estimatedRowHeight = 200
        self.timelineTableView.rowHeight = UITableViewAutomaticDimension
        self.timelineTableView.emptyDataSetDelegate = self
        self.timelineTableView.emptyDataSetSource = self
        self.timelineTableView.allowsSelection = false
        self.timelineTableView.tableFooterView = UIView()
        // 引っ張ってロードするやつ
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "loading...")
        refreshControl.addTarget(self, action: "refresh", forControlEvents: UIControlEvents.ValueChanged)
        timelineTableView.addSubview(refreshControl)
        // navigationBarについて設定
        // self.navigationController?.navigationBar.setBackgroundImage(Utility.resizeImage(UIImage(named: "imagenius-logo.png")!, size: CGSize(width: 200, height: 50)), forBarMetrics: .Default)
        self.navigationController?.navigationBar.backgroundColor = Settings.Colors.mainColor
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if saveData.objectForKey(Settings.Saveword.twitter) == nil {
            TwitterUtil.loginTwitter(self, success: { (ac)->() in
                self.account = ac
                self.swifter = Swifter(account: self.account!)
                self.loadTweet()
            })
        } else {
            let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
            accountStore.requestAccessToAccountsWithType(accountType, options: nil) { granted, error in
                if granted {
                    self.accounts = self.accountStore.accountsWithAccountType(accountType) as! [ACAccount]
                    if self.accounts.count != 0 {
                        self.account = self.accounts[self.saveData.objectForKey(Settings.Saveword.twitter) as! Int]
                        self.swifter = Swifter(account: self.account!)
                        self.loadTweet()
                    }
                }
            }
        }
    }
    
    // refresh処理
    func refresh() {
        self.tweetArray = []
        loadTweet()
        self.refreshControl.endRefreshing()
    }
    
    @IBAction func accountChange(sender: AnyObject) {
        self.tweetArray = []
        TwitterUtil.loginTwitter(self, success: { (ac) -> () in
            self.account = ac
            self.swifter = Swifter(account: self.account!)
            self.loadTweet()
        })
    }
    
    // Tweetのロード
    func load(moreflag: Bool) {
    }
    func loadTweet() {
        if swifter != nil {
            load(false)
        }
    }
    func loadMore() {
        if swifter != nil {
            load(true)
        }
    }
    
    // TableView関係
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tweetArray.count
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if tweetArray.count <= indexPath.row || indexPath.row < 0 {
            // Utility.simpleAlert("ローディング中にエラーが発生しました。", presentView: self)
            return UITableViewCell()
        }
        let tweet = tweetArray[indexPath.row]
        let favorited = tweet["favorited"].bool!
        let retweeted = tweet["retweeted"].bool!
        if TwitterUtil.isContainMedia(tweet) {
            let cell:TweetViewWithImageCell = tableView.dequeueReusableCellWithIdentifier("TweetCellWithImage") as! TweetViewWithImageCell
            cell.setOutlet(tweet)
            if (self.tweetArray.count - 1) == indexPath.row && self.maxId != "" {
                self.loadMore()
            }
            cell.rightUtilityButtons = self.rightButtons(favorited, retweeted: retweeted) as [AnyObject]
            cell.leftUtilityButtons = self.leftButtons() as [AnyObject]
            cell.delegate = self
            cell.layoutIfNeeded()
            return cell
        } else {
            let cell:TweetViewCell = tableView.dequeueReusableCellWithIdentifier("TweetCell")! as! TweetViewCell
            cell.setOutlet(tweet)
            if (self.tweetArray.count - 1) == indexPath.row && self.maxId != "" {
                self.loadMore()
            }
            cell.rightUtilityButtons = self.rightButtons(favorited, retweeted: retweeted) as [AnyObject]
            cell.leftUtilityButtons = self.leftButtons() as [AnyObject]
            cell.delegate = self
            cell.layoutIfNeeded()
            return cell
        }
    }
    // TableViewをスライドした時のボタン一覧
    func rightButtons(favorited: Bool, retweeted: Bool) -> NSArray {
        let rightUtilityButtons: NSMutableArray = NSMutableArray()
        if favorited {
            rightUtilityButtons.addObject(addUtilityButtonWithColor(Settings.Colors.favColor, icon: (UIImage(named: "like-action")!)))
        } else {
            rightUtilityButtons.addObject(addUtilityButtonWithColor(Settings.Colors.selectedColor, icon: UIImage(named: "like-action")!))
        }
        rightUtilityButtons.addObject(addUtilityButtonWithColor(Settings.Colors.twitterColor, icon: UIImage(named: "reply-action_0")!))
        if retweeted {
            rightUtilityButtons.addObject(addUtilityButtonWithColor(Settings.Colors.retweetColor, icon: UIImage(named: "retweet-action")!))
        } else {
            rightUtilityButtons.addObject(addUtilityButtonWithColor(Settings.Colors.selectedColor, icon: UIImage(named: "retweet-action")!))
        }
        return rightUtilityButtons
    }
    func leftButtons() -> NSArray {
        let leftUtilityButtons: NSMutableArray = NSMutableArray()
        leftUtilityButtons.addObject(addUtilityButtonWithColor(Settings.Colors.twitterColor, icon: UIImage(named: "TwitterLogo_white_1")!))
        leftUtilityButtons.addObject(addUtilityButtonWithColor(Settings.Colors.userColor, icon: UIImage(named: "use_white")!))
        return leftUtilityButtons
    }
    // ボタンの追加(なんかObj-CのNSMutableArray拡張ヘッダーが上手く反映できてないので)
    func addUtilityButtonWithColor(color : UIColor, icon : UIImage) -> UIButton {
        let button:UIButton = UIButton(type: UIButtonType.Custom)
        button.backgroundColor = color
        button.setImage(icon, forState: .Normal)
        return button
    }
    // TableViewをスライドした時のボタンの挙動
    func swipeableTableViewCell(cell: SWTableViewCell!, didTriggerRightUtilityButtonWithIndex index: Int) {
        let cellIndexPath: NSIndexPath = self.timelineTableView.indexPathForCell(cell)!
        let tweet = tweetArray[cellIndexPath.row]
        switch index {
        case 0:
            // fav
            if tweet["favorited"].bool! {
                swifter.postDestroyFavoriteWithID(tweet["id_str"].string!, success: {
                    statuses in
                    (cell.rightUtilityButtons[0] as! UIButton).backgroundColor = Settings.Colors.selectedColor
                })
                break
            }
            swifter.postCreateFavoriteWithID(tweet["id_str"].string!, success: {
                statuses in
                (cell.rightUtilityButtons[0] as! UIButton).backgroundColor = Settings.Colors.favColor
            })
            break
        case 1:
            // reply
            replyID = tweet["id_str"].string
            replyStr = "@\(tweet["user"]["screen_name"].string!) "
            performSegueWithIdentifier("toTweetView", sender: nil)
            break
        case 2:
            // retweet
            if tweet["retweeted"].bool! {
                // (cell.rightUtilityButtons[2] as! UIButton).backgroundColor = Settings.Colors.selectedColor
                break
            }
            swifter.postStatusRetweetWithID(tweet["id_str"].string!, success: {
                statuses in
                (cell.rightUtilityButtons[2] as! UIButton).backgroundColor = Settings.Colors.retweetColor
            })
            break
        default:
            break
        }
    }
    func swipeableTableViewCell(cell: SWTableViewCell!, didTriggerLeftUtilityButtonWithIndex index: Int) {
        let cellIndexPath: NSIndexPath = self.timelineTableView.indexPathForCell(cell)!
        let tweet = tweetArray[cellIndexPath.row]
        switch index {
        case 0:
            let url = NSURL(string: "https://twitter.com/"+tweet["user"]["screen_name"].string!+"/status/"+tweet["id_str"].string!)!
            Utility.openWebView(url)
            break
        case 1:
            let url = NSURL(string: "https://twitter.com/"+tweet["user"]["screen_name"].string!)!
            Utility.openWebView(url)
        default:
            break
        }
    }
    // 先にユーザーのプロフ画像を読み込んでおく
    func changeAccountImage() {
        let failureHandler: ((NSError) -> Void) = { error in
            Utility.simpleAlert(String(error.localizedFailureReason), presentView: self)
        }
        swifter.getUsersShowWithScreenName(account!.username, success: {(user) -> Void in
            if let userDict = user {
                if let userImage = userDict["profile_image_url_https"] {
                    self.accountImg = UIImage(data: NSData(contentsOfURL: NSURL(string: userImage.string!)!)!)!
                }
            }
            }, failure: failureHandler)
    }
    // ツイート編集画面に行く前にアカウント画像を取得しておく
    @IBAction func pushTweet() {
        changeAccountImage()
        performSegueWithIdentifier("toTweetView", sender: nil)
    }
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "toTweetView" {
            let tweetView = segue.destinationViewController as! TweetViewController
            tweetView.accountImg = self.accountImg
            tweetView.replyID = self.replyID
            tweetView.replyStr = self.replyStr
            self.accountImg = nil
            self.replyID = nil
            self.replyStr = nil
        }
    }
    
    // 要素が無い時
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "表示できるツイートがありません。"
        let font = UIFont.systemFontOfSize(20)
        return NSAttributedString(string: text, attributes: [NSFontAttributeName: font])
    }
}
