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

class MainViewController: UIViewController, UITableViewDelegate {
    @IBOutlet weak var timelineTableView: UITableView! {
        didSet {
            timelineTableView.registerNib(UINib(nibName: "TweetTableViewCell", bundle: nil), forCellReuseIdentifier: "cell")

            timelineTableView.estimatedRowHeight = 200
            timelineTableView.rowHeight = UITableViewAutomaticDimension
            timelineTableView.emptyDataSetDelegate = self
            timelineTableView.emptyDataSetSource = self
            timelineTableView.dataSource = viewModel
            // cellを選択不可に
            timelineTableView.allowsSelection = false
            timelineTableView.tableFooterView = UIView()
        }
    }

    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(MainViewController.refresh), forControlEvents: UIControlEvents.ValueChanged)
        return refreshControl
    }()

    var viewModel = MainViewModel()
    var avPlayerViewController: AVPlayerViewController!
    var tweetArray: [Tweet] = []
    var swifter: Swifter!
    var maxId: String!
    var replyID: String?
    var replyStr: String?
    var account: ACAccount?
    var accounts = [ACAccount]()
    var imageData: NSMutableArray?
    var gifURL: NSURL!
    var selectedUser: String!
    var selectedId: String!
    var myself: String!

    let accountStore = ACAccountStore()
    let saveData: NSUserDefaults = NSUserDefaults.standardUserDefaults()

    // MARK: - UIViewControllerの設定
    override func viewDidLoad() {
        super.viewDidLoad()

        // 引っ張ってロードするやつ
        timelineTableView.addSubview(refreshControl)

        saveData.addObserver(self, forKeyPath: Settings.Saveword.twitter, options: [NSKeyValueObservingOptions.New, NSKeyValueObservingOptions.Old], context: nil)

        if saveData.objectForKey(Settings.Saveword.twitter) == nil {
            performSegueWithIdentifier("showInfo", sender: nil)
        } else {
            let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
            accountStore.requestAccessToAccountsWithType(accountType, options: nil) { granted, error in
                if granted {
                    self.accounts = self.accountStore.accountsWithAccountType(accountType) as? [ACAccount] ?? []
                    if self.accounts.count != 0 {
                        self.account = self.accounts[self.saveData.objectForKey(Settings.Saveword.twitter) as? Int ?? 0]
                        self.swifter = Swifter(account: self.account!)
                        self.myself = self.account?.username
                        self.loadTweet()
                    }
                }
            }
        }

        viewModel.setViewController(self)
    }

    // MARK: アカウントが切り替わった時点でページをリロードしている
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
        accountStore.requestAccessToAccountsWithType(accountType, options: nil) { granted, error in
            if granted {
                self.accounts = self.accountStore.accountsWithAccountType(accountType) as? [ACAccount] ?? []
                if self.accounts.count != 0 {
                    self.account = self.accounts[self.saveData.objectForKey(Settings.Saveword.twitter) as? Int ?? 0]
                    self.swifter = Swifter(account: self.account!)
                    self.tweetArray = []
                    self.myself = self.account?.username
                    self.loadTweet()
                }
            }
        }
    }

    // MARK: メモリーがいっぱいになったらSDWebImageのキャッシュを削除
    override func didReceiveMemoryWarning() {
        let imageCache: SDImageCache = SDImageCache()
        imageCache.clearMemory()
        imageCache.clearDisk()
    }

    // MARK: 各Viewへ移り変わるときに渡す値
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "toTweetView" {
            let tweetView = segue.destinationViewController as? TweetViewController ?? TweetViewController()
            tweetView.replyID = self.replyID
            tweetView.replyStr = self.replyStr
            self.replyID = nil
            self.replyStr = nil
        } else if segue.identifier == "toPreView" {
            let preView = segue.destinationViewController as? ImagePreViewController ?? ImagePreViewController()
            preView.pageData = self.imageData
            self.imageData = nil
        } else if segue.identifier == "toGifView" {
            let gifView = segue.destinationViewController as? GIFViewController ?? GIFViewController()
            gifView.url = self.gifURL
            self.gifURL = nil
        } else if segue.identifier == "toUserView" {
            let userView = segue.destinationViewController as? UserViewController ?? UserViewController()
            userView.user = self.selectedUser
            self.selectedUser = nil
            if self.selectedId != nil {
                userView.idStr = self.selectedId
                self.selectedId = nil
            }
        } else if segue.identifier == "toTweetDetailView" {
            let tweetView = segue.destinationViewController as? TweetDetailViewController ?? TweetDetailViewController()
            tweetView.viewId = self.selectedId
            self.selectedId = nil
        }
    }

    // MARK: ステータスバーを細く
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }


    // MARK: - ボタン関連
    @IBAction func pushTweet() {
        performSegueWithIdentifier("toTweetView", sender: nil)
    }
    @IBAction func pushUser() {
        selectedUser = self.account?.username
        performSegueWithIdentifier("toUserView", sender: nil)
    }


    // MARK - TableView関連
    // UITableViewDelegateが無いので空

    // MARK: - Utility
    // MARK: refresh処理
    func refresh() {
        self.tweetArray = []
        loadTweet()
        self.refreshControl.endRefreshing()
    }
    // MARK: Tweetのロード
    func load(moreflag: Bool) {
    }
    // MARK: Tweetをロードする
    func loadTweet() {
        if swifter != nil {
            load(false)
        }
    }
    // MARK: さらに下を読み込む
    func loadMore() {
        if swifter != nil {
            load(true)
        }
    }
}

// MARK: - DZNEmptyDataSetの設定
extension MainViewController: DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
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
}

// MARK: - SWTableViewCell関連
extension MainViewController: SWTableViewCellDelegate {
    // MARK: 右のボタン
    func rightButtons(favorited: Bool, retweeted: Bool, favoriteCount: Int, retweetCount: Int) -> NSArray {
        let rightUtilityButtons: NSMutableArray = NSMutableArray()
        if favorited {
            rightUtilityButtons.addObject(addUtilityButtonWithColor(Settings.Colors.favColor, icon: UIImage(named: "like-action")!, text: String(favoriteCount)))
        } else {
            rightUtilityButtons.addObject(addUtilityButtonWithColor(Settings.Colors.selectedColor, icon: UIImage(named: "like-action")!, text: String(favoriteCount)))
        }
        rightUtilityButtons.addObject(addUtilityButtonWithColor(Settings.Colors.twitterColor, icon: UIImage(named: "reply-action_0")!))
        if retweeted {
            rightUtilityButtons.addObject(addUtilityButtonWithColor(Settings.Colors.retweetColor, icon: UIImage(named: "retweet-action")!, text: String(retweetCount)))
        } else {
            rightUtilityButtons.addObject(addUtilityButtonWithColor(Settings.Colors.selectedColor, icon: UIImage(named: "retweet-action")!, text: String(retweetCount)))
        }
        rightUtilityButtons.addObject(addUtilityButtonWithColor(Settings.Colors.deleteColor, icon: UIImage(named: "caution")!))
        return rightUtilityButtons
    }
    // MARK: 左のボタン
    func leftButtons() -> NSArray {
        let leftUtilityButtons: NSMutableArray = NSMutableArray()
        leftUtilityButtons.addObject(addUtilityButtonWithColor(Settings.Colors.twitterColor, icon: UIImage(named: "TwitterLogo_white_1")!))
        leftUtilityButtons.addObject(addUtilityButtonWithColor(Settings.Colors.userColor, icon: UIImage(named: "use_white")!))
        return leftUtilityButtons
    }
    // MARK: ボタンの追加(なんかObj-CのNSMutableArray拡張ヘッダーが上手く反映できてないので)
    func addUtilityButtonWithColor(color: UIColor, icon: UIImage, text: String? = nil) -> UIButton {
        let button: UIButton = UIButton(type: UIButtonType.Custom)
        button.backgroundColor = color
        button.tintColor = UIColor.whiteColor()
        button.setTitle(text, forState: .Normal)
        button.setImage(icon, forState: .Normal)
        return button
    }
    // MARK: 右スライドした時のボタンの挙動
    func swipeableTableViewCell(cell: SWTableViewCell!, didTriggerRightUtilityButtonWithIndex index: Int) {
        let cellIndexPath: NSIndexPath = self.timelineTableView.indexPathForCell(cell)!
        let tweet = tweetArray[cellIndexPath.row]
        switch index {
        case 0:
            // fav
            if tweet.favorited ?? false {
                swifter.postDestroyFavoriteWithID(tweet.idStr ?? "", success: {
                    statuses in
                    (cell.rightUtilityButtons[0] as? UIButton ?? UIButton()).backgroundColor = Settings.Colors.selectedColor
                    (cell.rightUtilityButtons[0] as? UIButton ?? UIButton()).setTitle("\((tweet.favoriteCount ?? 1) - 1)", forState: .Normal)
                })
                break
            }
            swifter.postCreateFavoriteWithID(tweet.idStr ?? "", success: {
                statuses in
                (cell.rightUtilityButtons[0] as? UIButton ?? UIButton()).backgroundColor = Settings.Colors.favColor
                (cell.rightUtilityButtons[0] as? UIButton ?? UIButton()).setTitle("\((tweet.favoriteCount ?? 0) + 1)", forState: .Normal)
            })
            break
        case 1:
            // reply
            replyID = tweet.idStr ?? ""
            replyStr = "\(tweet.screenName ?? "@") "
            if (tweet.userMentions ?? []).count != 0 {
                for u in tweet.userMentions! {
                    if u["screen_name"].string! != self.account?.username {
                        replyStr?.appendContentsOf("@\(u["screen_name"].string!) ")
                    }
                }
            }
            performSegueWithIdentifier("toTweetView", sender: nil)
            break
        case 2:
            // retweet
            if tweet.retweeted ?? false {
                // (cell.rightUtilityButtons[2] as! UIButton).backgroundColor = Settings.Colors.selectedColor
                break
            }
            swifter.postStatusRetweetWithID(tweet.idStr ?? "", success: {
                statuses in
                (cell.rightUtilityButtons[2] as? UIButton ?? UIButton()).backgroundColor = Settings.Colors.retweetColor
                (cell.rightUtilityButtons[0] as? UIButton ?? UIButton()).setTitle("\((tweet.retweetCount ?? 0) + 1)", forState: .Normal)
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
            let screen_name: String = tweet.screenNameNoat ?? ""
            let alertController = UIAlertController(title: "ブロック・通報", message: "@\(screen_name)を", preferredStyle: .ActionSheet)
            alertController.addAction(UIAlertAction(title: "ブロックする", style: .Default, handler: {(action) -> Void in
                let otherAlert = UIAlertController(title: "\(screen_name)をブロックする", message: "本当にブロックしますか？", preferredStyle: .Alert)
                otherAlert.addAction(UIAlertAction(title: "OK", style: .Default, handler: {(action) -> Void in
                    self.swifter.postBlocksCreateWithScreenName(screen_name, includeEntities: true, success: successHandler, failure: failureHandler)
                }))
                otherAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                self.presentViewController(otherAlert, animated: true, completion: nil)
            }))
            alertController.addAction(UIAlertAction(title: "通報する", style: .Default, handler: {(action) -> Void in
                let otherAlert = UIAlertController(title: "\(screen_name)を通報する", message: "本当に通報しますか？", preferredStyle: .Alert)
                otherAlert.addAction(UIAlertAction(title: "OK", style: .Default, handler: {(action) -> Void in
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
    // MARK: 左スライドした時のボタンの挙動
    func swipeableTableViewCell(cell: SWTableViewCell!, didTriggerLeftUtilityButtonWithIndex index: Int) {
        let cellIndexPath: NSIndexPath = self.timelineTableView.indexPathForCell(cell)!
        let tweet = tweetArray[cellIndexPath.row]
        switch index {
        case 0:
            selectedId = tweet.idStr ?? ""
            performSegueWithIdentifier("toTweetDetailView", sender: nil)
            break
        case 1:
            selectedUser = tweet.screenNameNoat ?? ""
            selectedId = tweet.userId ?? ""
            performSegueWithIdentifier("toUserView", sender: nil)
        default:
            break
        }
    }
}

// MARK: - TTTAttributedLabelDelegate
extension MainViewController: TTTAttributedLabelDelegate {
    func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
        if let userRange = url.URLString.rangeOfString("account:") {
            selectedUser = url.URLString.substringFromIndex(userRange.endIndex)
            performSegueWithIdentifier("toUserView", sender: nil)
        } else {
            Utility.openWebView(url)
            performSegueWithIdentifier("openWebView", sender: nil)
        }
    }
}
