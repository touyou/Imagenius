//
//  UserViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/04/07.
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
import RxCocoa
import RxSwift

final class UserViewController: UIViewController, UITableViewDelegate {
    @IBOutlet weak var userTimeLine: UITableView! {
        didSet {
            userTimeLine.registerNib(UINib(nibName: "TweetTableViewCell", bundle: nil), forCellReuseIdentifier: "cell")
            userTimeLine.estimatedRowHeight = 200
            userTimeLine.rowHeight = UITableViewAutomaticDimension
            userTimeLine.emptyDataSetDelegate = self
            userTimeLine.emptyDataSetSource = self
            userTimeLine.dataSource = viewModel
            // cellを選択不可に
            userTimeLine.allowsSelection = false
            userTimeLine.tableFooterView = UIView()
        }
    }
    @IBOutlet weak var avatarImage: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userIDLabel: UILabel!
    @IBOutlet weak var userDescription: TTTAttributedLabel!
    @IBOutlet weak var followButton: UIButton! {
        didSet {
            followButton.layer.cornerRadius = 5.0
            followButton.layer.borderWidth = 1.0
            followButton.layer.borderColor = Settings.Colors.twitterColor.CGColor
        }
    }
    @IBOutlet weak var unfollowButton: UIButton! {
        didSet {
            unfollowButton.layer.cornerRadius = 5.0
            unfollowButton.layer.borderWidth = 1.0
            unfollowButton.layer.borderColor = Settings.Colors.twitterColor.CGColor
        }
    }
    @IBOutlet weak var followBtnLength: NSLayoutConstraint!

    var user: String!   // screen_name
    var idStr: String!

    var viewModel = UserViewModel()
    var avPlayerViewController: AVPlayerViewController!
    var tweetArray: [Tweet] = []
    var swifter: Swifter!
    var maxId: String!
    var replyID: String?
    var replyStr: String?
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(UserViewController.refresh), forControlEvents: UIControlEvents.ValueChanged)
        return refreshControl
    }()
    var account: ACAccount?
    var accounts = [ACAccount]()
    var imageData: NSMutableArray?
    var gifURL: NSURL!
    var selectedId: String!
    var myself: String!
    var reloadingFlag: Bool = false

    let accountStore = ACAccountStore()
    let saveData: NSUserDefaults = NSUserDefaults.standardUserDefaults()
    // MARK: Rx
    final private let disposeBag = DisposeBag()

    // MARK: - UIViewControllerの設定
    override func viewDidLoad() {
        super.viewDidLoad()

        // 引っ張ってロードするやつ
        userTimeLine.addSubview(refreshControl)

        userIDLabel.text = "@\(self.user)"
        // ボタン周り
        followButton.hidden = true
        unfollowButton.hidden = true
        followButton.rx_tap.subscribe({event in self.follow()}).addDisposableTo(disposeBag)
        unfollowButton.rx_tap.subscribe({event in self.unfollow()}).addDisposableTo(disposeBag)

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
                        self.title = "@\(self.user)のツイート一覧"
                        
                        self.myself = self.account?.username
                        
                        if self.idStr == nil {
                            self.getUserIdWithScreenName(self.user, comp: {
                                self.loadTweet()
                            })
                        } else {
                            self.loadTweet()
                        }
                    }
                }
            }
        }

        saveData.addObserver(self, forKeyPath: Settings.Saveword.twitter, options: [NSKeyValueObservingOptions.New, NSKeyValueObservingOptions.Old], context: nil)

        viewModel.setViewController(self)
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
        accountStore.requestAccessToAccountsWithType(accountType, options: nil) { granted, error in
            if granted {
                self.accounts = self.accountStore.accountsWithAccountType(accountType) as? [ACAccount] ?? []
                if self.accounts.count != 0 {
                    self.account = self.accounts[self.saveData.objectForKey(Settings.Saveword.twitter) as? Int ?? 0]
                    self.swifter = Swifter(account: self.account!)
                    self.myself = self.account?.username
                    if !self.reloadingFlag {
                        self.tweetArray = []
                        self.loadTweet()
                        self.reloadingFlag = true
                    } else {
                        self.reloadingFlag = false
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
        } else if segue.identifier == "toTweetDetailView" {
            let tweetView = segue.destinationViewController as? TweetDetailViewController ?? TweetDetailViewController()
            tweetView.viewId = self.selectedId
            self.selectedId = nil
        }
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

    // MARK: - ボタン関連
    @IBAction func pushTweet() {
        self.replyStr = "@\(user) "
        performSegueWithIdentifier("toTweetView", sender: nil)
    }
    func unfollow() {
        self.swifter.postDestroyFriendshipWithID(self.idStr, success: { user in
            self.unfollowButton.hidden = true
            self.followButton.hidden = false
            self.followBtnLength.constant = 100
        })
    }
    func follow() {
        self.swifter.postCreateFriendshipWithID(self.idStr, success: { user in
            self.unfollowButton.hidden = false
            self.followBtnLength.constant = 0
            self.followButton.hidden = true
        })
    }

    // MARK: - TableView関連
    // 無し

    // MARK: - Utility
    // MARK: refresh処理
    func refresh() {
        self.tweetArray = []
        loadTweet()
        self.refreshControl.endRefreshing()
    }
    // MARK: Tweetのロード
    func load(moreflag: Bool) {
        let failureHandler: ((NSError) -> Void) = { error in
            Utility.simpleAlert("Error: ユーザーのツイート一覧のロードに失敗しました。インターネット環境を確認してください。", presentView: self)
        }
        let successHandler: (([JSONValue]?) -> Void) = { statuses in
            guard let tweets = statuses else { return }

            if tweets.count < 1 {
                self.maxId = ""
            } else if tweets.count == 1 {
                if self.tweetArray.count >= 1 && self.maxId == self.tweetArray[self.tweetArray.count - 1].idStr ?? "" {
                    return
                }
                self.tweetArray.append(Tweet(tweet: tweets[0], myself: self.myself))
                self.maxId = tweets[0]["id_str"].string
            } else {
                for i in 0 ..< tweets.count - 1 {
                    self.tweetArray.append(Tweet(tweet: tweets[i], myself: self.myself))
                }
                self.maxId = tweets[tweets.count - 1]["id_str"].string
            }

            // headerの設定
            if tweets.count >= 1 {
                let userInfo = tweets[0]["user"]

                self.avatarImage.sd_setImageWithURL(NSURL(string: userInfo["profile_image_url_https"].string!), placeholderImage: nil, options: SDWebImageOptions.RetryFailed)
                self.avatarImage.layer.cornerRadius = self.avatarImage.frame.size.width * 0.5
                self.avatarImage.clipsToBounds = true
                self.avatarImage.layer.borderColor = Settings.Colors.selectedColor.CGColor
                self.avatarImage.layer.borderWidth = 0.19

                self.userNameLabel.text = userInfo["name"].string!
                self.userDescription.text = userInfo["description"].string!
                if userInfo["following"].bool != nil {
                    if userInfo["following"].bool! {
                        self.followButton.hidden = true
                        self.followBtnLength.constant = 0
                        self.unfollowButton.hidden = false
                    } else if userInfo["follow_request_sent"].bool! {
                        self.followButton.setTitle("フォロー許可待ち", forState: .Normal)
                        self.followButton.enabled = false
                        self.followBtnLength.constant = 100
                        self.unfollowButton.hidden = true
                        self.followButton.hidden = false
                    } else {
                        self.followButton.hidden = false
                        self.followBtnLength.constant = 100
                        self.unfollowButton.hidden = true
                    }
                } else {
                    self.followButton.hidden = true
                    self.unfollowButton.hidden = true
                }
                if self.user == self.account?.username! {
                    self.followButton.hidden = true
                    self.unfollowButton.hidden = true
                }
            }

            self.viewModel.tweetArray = self.tweetArray
            self.userTimeLine.reloadData()
        }
        if !moreflag {
            self.swifter.getStatusesUserTimelineWithUserID(idStr, count: 41, includeEntities: true, success: successHandler, failure: failureHandler)
        } else {
            self.swifter.getStatusesUserTimelineWithUserID(idStr, sinceID: nil, maxID: self.maxId, trimUser: nil, contributorDetails: nil, count: 41, includeEntities: true, success: successHandler, failure: failureHandler)
        }
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
    // MARK: screen_nameからUserIDを取得する
    func getUserIdWithScreenName(userName: String, comp: (()->())? = nil) {
        let failureHandler: ((NSError) -> Void) = { error in
            Utility.simpleAlert("Error: ユーザーIDの取得に失敗しました。インターネット環境を確認してください。", presentView: self)
        }

        self.swifter.getUsersShowWithScreenName(userName, includeEntities: false, success: {
            statuses in
            guard let userInfo = statuses else { return }
            self.idStr = userInfo["id_str"]?.string!
            comp!()
            }, failure: failureHandler)
    }
}

// MARK: - DZNEmptyDataSetの設定
extension UserViewController: DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
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
extension UserViewController: SWTableViewCellDelegate {
    // MARK: 右のボタン
    func rightButtons(tweet: Tweet) -> NSArray {
        let rightUtilityButtons: NSMutableArray = NSMutableArray()
        if tweet.favorited ?? false {
            rightUtilityButtons.addObject(addUtilityButtonWithColor(Settings.Colors.favColor, icon: UIImage(named: "like-action")!, text: String(tweet.favoriteCount ?? 0)))
        } else {
            rightUtilityButtons.addObject(addUtilityButtonWithColor(Settings.Colors.selectedColor, icon: UIImage(named: "like-action")!, text: String(tweet.favoriteCount ?? 0)))
        }
        rightUtilityButtons.addObject(addUtilityButtonWithColor(Settings.Colors.twitterColor, icon: UIImage(named: "reply-action_0")!))
        if tweet.retweeted ?? false {
            rightUtilityButtons.addObject(addUtilityButtonWithColor(Settings.Colors.retweetColor, icon: UIImage(named: "retweet-action")!, text: String(tweet.retweetCount ?? 0)))
        } else {
            rightUtilityButtons.addObject(addUtilityButtonWithColor(Settings.Colors.selectedColor, icon: UIImage(named: "retweet-action")!, text: String(tweet.retweetCount ?? 0)))
        }
        if tweet.isMyself {
            rightUtilityButtons.addObject(addUtilityButtonWithColor(Settings.Colors.deleteColor, icon: UIImage(named: "trash")!))
        } else {
            rightUtilityButtons.addObject(addUtilityButtonWithColor(Settings.Colors.deleteColor, icon: UIImage(named: "caution")!))
        }
        return rightUtilityButtons
    }
    // MARK: 左のボタン
    func leftButtons() -> NSArray {
        let leftUtilityButtons: NSMutableArray = NSMutableArray()
        leftUtilityButtons.addObject(addUtilityButtonWithColor(Settings.Colors.twitterColor, icon: UIImage(named: "TwitterLogo_white_1")!))
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
        let cellIndexPath: NSIndexPath = self.userTimeLine.indexPathForCell(cell)!
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
                    replyStr?.appendContentsOf("@\(u["screen_name"].string!) ")
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
            // ツイートの削除
            if tweet.isMyself {
                let failureHandler: ((NSError) -> Void) = { error in
                    Utility.simpleAlert("Error: ツイートの削除に失敗しました。インターネット環境を確認してください。", presentView: self)
                }
                let successHandler: ((user: Dictionary<String, JSONValue>?) -> Void) = { statuses in
                    self.tweetArray = []
                    self.loadTweet()
                }
                let alertController = UIAlertController(title: "ツイートの削除", message: "このツイートを削除しますか？", preferredStyle: .Alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
                    self.swifter.postStatusesDestroyWithID(tweet.idStr ?? "", success: successHandler, failure: failureHandler)
                }))
                alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                presentViewController(alertController, animated: true, completion: nil)
                
                break
            }
            
            // block or spam
            let failureHandler: ((NSError) -> Void) = { error in
                Utility.simpleAlert("Error: ブロック・通報を完了できませんでした。インターネット環境を確認してください。", presentView: self)
            }
            let successHandler: ((user: Dictionary<String, JSONValue>?) -> Void) = { statuses in
                self.tweetArray = []
                self.loadTweet()
            }
            let screen_name = tweet.screenNameNoat ?? ""
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
        let cellIndexPath: NSIndexPath = self.userTimeLine.indexPathForCell(cell)!
        let tweet = tweetArray[cellIndexPath.row]
        switch index {
        case 0:
            selectedId = tweet.idStr ?? ""
            performSegueWithIdentifier("toTweetDetailView", sender: nil)
            break
        default:
            break
        }
    }
}

// MARK: - TTTAttributedLabelDelegate
extension UserViewController: TTTAttributedLabelDelegate {
    func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
        if let userRange = url.URLString.rangeOfString("account:") {
            user = url.URLString.substringFromIndex(userRange.endIndex)
            getUserIdWithScreenName(user, comp: {
                self.tweetArray = []
                self.title = "@\(self.user)のツイート一覧"
                self.userIDLabel.text = "@\(self.user)"
                self.loadTweet()
            })
        } else {
            Utility.openWebView(url)
            performSegueWithIdentifier("openWebView", sender: nil)
        }
    }
}
