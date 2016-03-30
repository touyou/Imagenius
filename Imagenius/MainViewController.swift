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
import AVKit
import AVFoundation

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource, SWTableViewCellDelegate, TTTAttributedLabelDelegate {
    @IBOutlet var timelineTableView: UITableView!
    
    var avPlayerViewController: AVPlayerViewController!
    var tweetArray: [JSONValue] = []
    var swifter: Swifter!
    var maxId: String!
    var replyID: String?
    var replyStr: String?
    var refreshControl: UIRefreshControl!
    var accountImg: UIImage?
    var account: ACAccount?
    var accounts = [ACAccount]()
    var imageData: NSMutableArray?
    var gifURL: NSURL!
    
    let accountStore = ACAccountStore()
    let saveData:NSUserDefaults = NSUserDefaults.standardUserDefaults()
    
    // UIViewControllerの設定----------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        self.timelineTableView.estimatedRowHeight = 200
        self.timelineTableView.rowHeight = UITableViewAutomaticDimension
        self.timelineTableView.emptyDataSetDelegate = self
        self.timelineTableView.emptyDataSetSource = self
        // cellを選択不可に
        self.timelineTableView.allowsSelection = false
        self.timelineTableView.tableFooterView = UIView()
        
        // 引っ張ってロードするやつ
        refreshControl = UIRefreshControl()
        refreshControl.attributedTitle = NSAttributedString(string: "loading...")
        refreshControl.addTarget(self, action: #selector(MainViewController.refresh), forControlEvents: UIControlEvents.ValueChanged)
        timelineTableView.addSubview(refreshControl)
        saveData.setObject(false, forKey: Settings.Saveword.changed)
        saveData.setObject(false, forKey: Settings.Saveword.changed2)
        
        if saveData.objectForKey(Settings.Saveword.twitter) == nil {
            performSegueWithIdentifier("showInfo", sender: nil)
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
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if saveData.objectForKey(Settings.Saveword.changed) != nil {
            if saveData.objectForKey(Settings.Saveword.changed) as! Bool {
                let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
                accountStore.requestAccessToAccountsWithType(accountType, options: nil) { granted, error in
                    if granted {
                        self.accounts = self.accountStore.accountsWithAccountType(accountType) as! [ACAccount]
                        if self.accounts.count != 0 {
                            self.account = self.accounts[self.saveData.objectForKey(Settings.Saveword.twitter) as! Int]
                            self.swifter = Swifter(account: self.account!)
                            self.tweetArray = []
                            self.saveData.setObject(false, forKey: Settings.Saveword.changed)
                            self.saveData.setObject(true, forKey: Settings.Saveword.changed2)
                            self.loadTweet()
                        }
                    }
                }
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if saveData.objectForKey(Settings.Saveword.changed2) != nil {
            if saveData.objectForKey(Settings.Saveword.changed2) as! Bool {
                let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
                accountStore.requestAccessToAccountsWithType(accountType, options: nil) { granted, error in
                    if granted {
                        self.accounts = self.accountStore.accountsWithAccountType(accountType) as! [ACAccount]
                        if self.accounts.count != 0 {
                            self.account = self.accounts[self.saveData.objectForKey(Settings.Saveword.twitter) as! Int]
                            self.swifter = Swifter(account: self.account!)
                            self.tweetArray = []
                            self.saveData.setObject(false, forKey: Settings.Saveword.changed2)
                            self.loadTweet()
                        }
                    }
                }
            }
        }
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
        } else if segue.identifier == "toPreView" {
            let preView = segue.destinationViewController as! ImagePreViewController
            preView.pageData = self.imageData
            self.imageData = nil
        } else if segue.identifier == "toGifView" {
            let gifView = segue.destinationViewController as! GIFViewController
            gifView.url = self.gifURL
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    
    // ボタン関連-----------------------------------------------------------------
    // アカウント切り替えボタン
    @IBAction func accountChange(sender: AnyObject) {
        self.tweetArray = []
        TwitterUtil.loginTwitter(self, success: { (ac) -> () in
            self.account = ac
            self.swifter = Swifter(account: self.account!)
            self.loadTweet()
        })
    }
    // ツイート編集画面に行く前にアカウント画像を取得しておく
    @IBAction func pushTweet() {
        changeAccountImage()
        performSegueWithIdentifier("toTweetView", sender: nil)
    }
    
    
    // TableView関連-------------------------------------------------------------
    // 基本設定三つ
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tweetArray.count
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if tweetArray.count <= indexPath.row || indexPath.row < 0 {
            return UITableViewCell()
        }
        let tweet = tweetArray[indexPath.row]
        let favorited = tweet["favorited"].bool!
        let retweeted = tweet["retweeted"].bool!
        
        let cell: TweetVarViewCell = tableView.dequeueReusableCellWithIdentifier("TweetCellPrototype") as! TweetVarViewCell
        cell.tweetLabel.delegate = self
        cell.setOutlet(tweet, tweetHeight: self.view.bounds.width / 1.8)
        
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(MainViewController.tapped(_:)))
        cell.tweetImgView.addGestureRecognizer(tapGesture)
        cell.tweetImgView.tag = indexPath.row
        
        if (self.tweetArray.count - 1) == indexPath.row && self.maxId != "" {
            self.loadMore()
        }
        cell.rightUtilityButtons = self.rightButtons(favorited, retweeted: retweeted) as [AnyObject]
        cell.leftUtilityButtons = self.leftButtons() as [AnyObject]
        cell.delegate = self
        cell.layoutIfNeeded()
        return cell
    }
    // imageViewがタップされたら画像のURLを開く
    func tapped(sender: UITapGestureRecognizer) {
        if let theView = sender.view {
            let rowNum = theView.tag
            if tweetArray[rowNum]["extended_entities"]["media"][0]["type"].string == nil {
                
            }
            switch tweetArray[rowNum]["extended_entities"]["media"][0]["type"].string! {
            case "photo":
                let tempData = NSMutableArray()
                for data in tweetArray[rowNum]["extended_entities"]["media"].array! {
                    tempData.addObject(NSURL(string: data["media_url"].string!)!)
                }
                imageData = tempData
                performSegueWithIdentifier("toPreView", sender: nil)
            case "video":
                if let videoArray = tweetArray[rowNum]["extended_entities"]["media"][0]["video_info"]["variants"].array {
                    let alertController = UIAlertController(title: "ビットレートを選択", message: "再生したい動画のビットレートを選択してください。", preferredStyle: .ActionSheet)
                    for i in 0 ..< videoArray.count {
                        let videoInfo = videoArray[i]
                        if videoInfo["bitrate"].integer != nil {
                            alertController.addAction(UIAlertAction(title: "\(videoInfo["bitrate"].integer! / 1000)kbps", style: .Default, handler: { (action) -> Void in
                                self.avPlayerViewController = AVPlayerViewController()
                                self.avPlayerViewController.player = AVPlayer(URL: NSURL(string: videoInfo["url"].string!)!)
                                self.presentViewController(self.avPlayerViewController, animated: true, completion: nil)
                            }))
                        }
                    }
                    
                    // キャンセルボタンは何もせずにアクションシートを閉じる
                    let CanceledAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
                    alertController.addAction(CanceledAction)
                    // iPad用
                    alertController.popoverPresentationController?.sourceView = self.view
                    alertController.popoverPresentationController?.sourceRect = theView.frame
                    // アクションシート表示
                    self.presentViewController(alertController, animated: true, completion: nil)
                }
            case "animated_gif":
                // print(tweetArray[rowNum]["extended_entities"])
                if let videoURL = tweetArray[rowNum]["extended_entities"]["media"][0]["video_info"]["variants"][0]["url"].string {
                    gifURL = NSURL(string: videoURL)
                    performSegueWithIdentifier("toGifView", sender: nil)
                }
            default:
                if let tweetURL = tweetArray[rowNum]["extended_entities"]["media"][0]["url"].string {
                    Utility.openWebView(NSURL(string: tweetURL)!)
                    performSegueWithIdentifier("openWebView", sender: nil)
                }
            }
        }
    }
    // SWTableViewCell関連
    // 右のボタン
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
        rightUtilityButtons.addObject(addUtilityButtonWithColor(Settings.Colors.deleteColor, icon: UIImage(named: "caution")!))
        return rightUtilityButtons
    }
    // 左のボタン
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
    // 右スライドした時のボタンの挙動
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
        case 3:
            // block or spam
            let failureHandler: ((NSError) -> Void) = { error in
                Utility.simpleAlert("Error: ブロック・通報を完了できませんでした。インターネット環境を確認してください。", presentView: self)
            }
            let successHandler: ((user: Dictionary<String, JSONValue>?) -> Void) = { statuses in
                self.tweetArray = []
                self.loadTweet()
            }
            let screen_name = tweet["user"]["screen_name"].string!
            let alertController = UIAlertController(title: "ブロック・通報", message: "@\(screen_name)を", preferredStyle: .ActionSheet)
            alertController.addAction(UIAlertAction(title: "ブロックする", style: .Default, handler: {(action)->Void in
                let otherAlert = UIAlertController(title: "\(screen_name)をブロックする", message: "本当にブロックしますか？", preferredStyle: .Alert)
                otherAlert.addAction(UIAlertAction(title: "OK", style: .Default, handler: {(action)->Void in
                    self.swifter.postBlocksCreateWithScreenName(screen_name, includeEntities: true, success: successHandler, failure: failureHandler)
                }))
                otherAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                self.presentViewController(otherAlert, animated: true, completion: nil)
            }))
            alertController.addAction(UIAlertAction(title: "通報する", style: .Default, handler: {(action)->Void in
                let otherAlert = UIAlertController(title: "\(screen_name)を通報する", message: "本当に通報しますか？", preferredStyle: .Alert)
                otherAlert.addAction(UIAlertAction(title: "OK", style: .Default, handler: {(action)->Void in
                    self.swifter.postUsersReportSpamWithScreenName(screen_name, success: successHandler, failure: failureHandler)
                }))
                otherAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                self.presentViewController(otherAlert, animated: true, completion: nil)
            }))
            alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            
            // iPad用
            alertController.popoverPresentationController?.sourceView = self.view
            alertController.popoverPresentationController?.sourceRect = cell.contentView.frame
            
            self.presentViewController(alertController, animated: true, completion: nil)
        default:
            break
        }
    }
    // 左スライドした時のボタンの挙動
    func swipeableTableViewCell(cell: SWTableViewCell!, didTriggerLeftUtilityButtonWithIndex index: Int) {
        let cellIndexPath: NSIndexPath = self.timelineTableView.indexPathForCell(cell)!
        let tweet = tweetArray[cellIndexPath.row]
        switch index {
        case 0:
            let url = NSURL(string: "https://twitter.com/"+tweet["user"]["screen_name"].string!+"/status/"+tweet["id_str"].string!)!
            Utility.openWebView(url)
            performSegueWithIdentifier("openWebView", sender: nil)
            break
        case 1:
            let url = NSURL(string: "https://twitter.com/"+tweet["user"]["screen_name"].string!)!
            Utility.openWebView(url)
            performSegueWithIdentifier("openWebView", sender: nil)
        default:
            break
        }
    }
    // DZNEmptyDataSetの設定
    func descriptionForEmptyDataSet(scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "表示できるツイートがありません。"
        let font = UIFont.systemFontOfSize(20)
        return NSAttributedString(string: text, attributes: [NSFontAttributeName: font])
    }
    func buttonTitleForEmptyDataSet(scrollView: UIScrollView!, forState state: UIControlState) -> NSAttributedString! {
        return NSAttributedString(string: "リロードする")
    }
    func emptyDataSetDidTapButton(scrollView: UIScrollView!) {
        loadTweet()
    }
    // TTTAttributedLabelDelegate
    func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
        Utility.openWebView(url)
        performSegueWithIdentifier("openWebView", sender: nil)
    }

    
    // Utility------------------------------------------------------------------
    // refresh処理
    func refresh() {
        self.tweetArray = []
        loadTweet()
        self.refreshControl.endRefreshing()
    }
    // Tweetのロード
    func load(moreflag: Bool) {
    }
    // Tweetをロードする
    func loadTweet() {
        if swifter != nil {
            load(false)
        }
    }
    // さらに下を読み込む
    func loadMore() {
        if swifter != nil {
            load(true)
        }
    }
    // ユーザーのプロフ画像を読み込む
    func changeAccountImage() {
        let failureHandler: ((NSError) -> Void) = { error in
            Utility.simpleAlert("Error: プロフィール画像を取得できませんでした。インターネット環境を確認してください。", presentView: self)
        }
        swifter.getUsersShowWithScreenName(account!.username, success: {(user) -> Void in
            if let userDict = user {
                if let userImage = userDict["profile_image_url_https"] {
                    self.accountImg = UIImage(data: NSData(contentsOfURL: NSURL(string: userImage.string!)!)!)!
                }
            }
            }, failure: failureHandler)
    }
}
