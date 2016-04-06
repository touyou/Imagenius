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
import SDWebImage

class MainViewController: UIViewController, UITableViewDelegate, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource, SWTableViewCellDelegate, TTTAttributedLabelDelegate {
    @IBOutlet var timelineTableView: UITableView!
    
    var viewModel = MainViewModel()
    var avPlayerViewController: AVPlayerViewController!
    var tweetArray: [JSONValue] = []
    var swifter: Swifter!
    var maxId: String!
    var replyID: String?
    var replyStr: String?
    var refreshControl: UIRefreshControl!
    var account: ACAccount?
    var accounts = [ACAccount]()
    var imageData: NSMutableArray?
    var gifURL: NSURL!
    
    let accountStore = ACAccountStore()
    let saveData:NSUserDefaults = NSUserDefaults.standardUserDefaults()
    
    // UIViewControllerの設定----------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        timelineTableView.estimatedRowHeight = 200
        timelineTableView.rowHeight = UITableViewAutomaticDimension
        timelineTableView.emptyDataSetDelegate = self
        timelineTableView.emptyDataSetSource = self
        timelineTableView.dataSource = viewModel
        // cellを選択不可に
        timelineTableView.allowsSelection = false
        timelineTableView.tableFooterView = UIView()
        
        
        // 引っ張ってロードするやつ
        refreshControl = UIRefreshControl()
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
        
        viewModel.setViewController(self)
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
    
    override func didReceiveMemoryWarning() {
        let imageCache: SDImageCache = SDImageCache()
        imageCache.clearMemory()
        imageCache.clearDisk()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "toTweetView" {
            let tweetView = segue.destinationViewController as! TweetViewController
            tweetView.replyID = self.replyID
            tweetView.replyStr = self.replyStr
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
    // ツイート編集画面に行く前にアカウント画像を取得しておく
    @IBAction func pushTweet() {
        performSegueWithIdentifier("toTweetView", sender: nil)
    }
    
    
    // TableView関連-------------------------------------------------------------
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
}
