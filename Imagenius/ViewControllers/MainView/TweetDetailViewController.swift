//
//  TweetDetailViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/04/08.
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

final class TweetDetailViewController: UIViewController, UITableViewDelegate {
    @IBOutlet weak var timelineTableView: UITableView! {
        didSet {
            timelineTableView.register(UINib(nibName: "TweetTableViewCell", bundle: nil), forCellReuseIdentifier: "cell")
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

    var viewId: String!

    var viewModel = TweetDetailViewModel()
    var avPlayerViewController: AVPlayerViewController!
    var tweetArray: [[Tweet]] = [[], [], []]
    var swifter: Swifter!
    var maxId: String!
    var replyID: String?
    var replyStr: String?
    var refreshControl: UIRefreshControl!
    var account: ACAccount?
    var accounts = [ACAccount]()
    var imageData: NSMutableArray?
    var gifURL: URL!
    var selectedUser: String!
    var selectedId: String!
    var myself: String!
    var reloadingFlag: Bool = false

    let accountStore = ACAccountStore()
    let saveData: UserDefaults = UserDefaults.standard

    // MARK: - UIViewControllerの設定
    override func viewDidLoad() {
        super.viewDidLoad()

        // 引っ張ってロードするやつ
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(MainViewController.refresh), for: UIControlEvents.valueChanged)
        timelineTableView.addSubview(refreshControl)
        saveData.set(false, forKey: Settings.Saveword.changed)
        saveData.set(false, forKey: Settings.Saveword.changed2)

        if saveData.object(forKey: Settings.Saveword.twitter) == nil {
            performSegue(withIdentifier: "showInfo", sender: nil)
        } else {
            let accountType = accountStore.accountType(withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter)
            accountStore.requestAccessToAccounts(with: accountType, options: nil) { granted, error in
                if granted {
                    self.accounts = self.accountStore.accounts(with: accountType) as? [ACAccount] ?? []
                    if self.accounts.count != 0 {
                        self.account = self.accounts[self.saveData.object(forKey: Settings.Saveword.twitter) as? Int ?? 0]
                        self.swifter = Swifter(account: self.account!)
                        self.myself = self.account?.username
                        self.loadTweet()
                    }
                }
            }
        }

        saveData.addObserver(self, forKeyPath: Settings.Saveword.twitter, options: [NSKeyValueObservingOptions.new, NSKeyValueObservingOptions.old], context: nil)

        viewModel.setViewController(self)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let accountType = accountStore.accountType(withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter)
        accountStore.requestAccessToAccounts(with: accountType, options: nil) { granted, error in
            if granted {
                self.accounts = self.accountStore.accounts(with: accountType) as? [ACAccount] ?? []
                if self.accounts.count != 0 {
                    self.account = self.accounts[self.saveData.object(forKey: Settings.Saveword.twitter) as? Int ?? 0]
                    self.swifter = Swifter(account: self.account!)
                    self.myself = self.account?.username
                    if !self.reloadingFlag {
                        self.tweetArray = [[], [], []]
                        self.loadTweet()
                        self.reloadingFlag = true
                    } else {
                        self.reloadingFlag = false
                    }
                }
            }
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toTweetView" {
            let tweetView = segue.destination as? TweetViewController ?? TweetViewController()
            tweetView.replyID = self.replyID
            tweetView.replyStr = self.replyStr
            self.replyID = nil
            self.replyStr = nil
        } else if segue.identifier == "toPreView" {
            let preView = segue.destination as? ImagePreViewController ?? ImagePreViewController()
            preView.pageData = self.imageData
            self.imageData = nil
        } else if segue.identifier == "toGifView" {
            let gifView = segue.destination as? GIFViewController ?? GIFViewController()
            gifView.url = self.gifURL
            self.gifURL = nil
        } else if segue.identifier == "toUserView" {
            let userView = segue.destination as? UserViewController ?? UserViewController()
            userView.user = self.selectedUser
            self.selectedUser = nil
            if self.selectedId != nil {
                userView.idStr = self.selectedId
                self.selectedId = nil
            }
        }
    }

    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }


    // MARK: - ボタン関連
    @IBAction func pushTweet() {
        self.replyID = self.viewId
        if tweetArray[1].count != 0 {
            self.replyStr = "@\(tweetArray[1][0].screenNameNoat) "
            if (tweetArray[1][0].userMentions ?? []).count != 0 {
                for u in tweetArray[1][0].userMentions! {
                    if u["screen_name"].string! != self.account?.username {
                        replyStr?.append("@\(u["screen_name"].string!) ")
                    }
                }
            }
        }
        performSegue(withIdentifier: "toTweetView", sender: nil)
    }


    // MARK: - TableView関連
    // 無し

    // MARK: - Utility
    // MARK: refresh処理
    func refresh() {
        self.tweetArray = [[], [], []]
        loadTweet()
        self.refreshControl.endRefreshing()
    }
    // MARK: Tweetのロード
    func load(_ moreflag: Bool) {
        let failureHandler: ((NSError) -> Void) = { error in
            Utility.simpleAlert("Error: ツイートのロードに失敗しました。インターネット環境を確認してください。", presentView: self)
        }
        var successHandler: ((Dictionary<String, JSONValue>?) -> Void)!
        successHandler = { status in
            guard let tweet = status else { return }
            var tw = Tweet()
            tw.setTweet(tweet)
            tw.judgeAccount(self.myself)
            self.tweetArray[0].insert(tw, at: 0)

            if let next_id = tweet["in_reply_to_status_id_str"]!.string {
                self.swifter.getStatusesShowWithID(next_id, count: nil, trimUser: nil, includeMyRetweet: nil, includeEntities: true, success: successHandler, failure: failureHandler)
            } else {
                self.viewModel.setTweetArray(self.tweetArray)
                self.timelineTableView.reloadData()
            }
        }
        swifter.getStatusesShowWithID(viewId, count: nil, trimUser: nil, includeMyRetweet: nil, includeEntities: true, success: {
            status in
            guard let tweet = status else { return }
            var tw = Tweet()
            tw.setTweet(tweet)
            tw.judgeAccount(self.myself)
            self.tweetArray[1].append(tw)

            if let next_id = tweet["in_reply_to_status_id_str"]!.string {
                self.swifter.getStatusesShowWithID(next_id, count: nil, trimUser: nil, includeMyRetweet: nil, includeEntities: true, success: successHandler, failure: failureHandler)
            } else {
                self.viewModel.setTweetArray(self.tweetArray)
                self.timelineTableView.reloadData()
            }
            }, failure: failureHandler)
    }
    // MARK: Tweetをロードする
    func loadTweet() {
        if swifter != nil {
            load(false)
        }
    }
}

// MARK: - DZNEmptyDataSetの設定
extension TweetDetailViewController: DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "表示できるツイートがありません。"
        let font = UIFont.systemFont(ofSize: 20)
        return NSAttributedString(string: text, attributes: [NSFontAttributeName: font])
    }
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
        return NSAttributedString(string: "リロードする")
    }
    func emptyDataSetDidTapButton(_ scrollView: UIScrollView!) {
        loadTweet()
    }
}

// MARK: - SWTableViewCell関連
extension TweetDetailViewController: SWTableViewCellDelegate {
    // MARK: 右のボタン
    func rightButtons(_ tweet: Tweet) -> NSArray {
        let rightUtilityButtons: NSMutableArray = NSMutableArray()
        if tweet.favorited ?? false {
            rightUtilityButtons.add(addUtilityButtonWithColor(Settings.Colors.favColor, icon: UIImage(named: "like-action")!, text: String(tweet.favoriteCount ?? 0)))
        } else {
            rightUtilityButtons.add(addUtilityButtonWithColor(Settings.Colors.selectedColor, icon: UIImage(named: "like-action")!, text: String(tweet.favoriteCount ?? 0)))
        }
        rightUtilityButtons.add(addUtilityButtonWithColor(Settings.Colors.twitterColor, icon: UIImage(named: "reply-action_0")!))
        if tweet.retweeted ?? false {
            rightUtilityButtons.add(addUtilityButtonWithColor(Settings.Colors.retweetColor, icon: UIImage(named: "retweet-action")!, text: String(tweet.retweetCount ?? 0)))
        } else {
            rightUtilityButtons.add(addUtilityButtonWithColor(Settings.Colors.selectedColor, icon: UIImage(named: "retweet-action")!, text: String(tweet.retweetCount ?? 0)))
        }
        if tweet.isMyself {
            rightUtilityButtons.add(addUtilityButtonWithColor(Settings.Colors.deleteColor, icon: UIImage(named: "trash")!))
        } else {
            rightUtilityButtons.add(addUtilityButtonWithColor(Settings.Colors.deleteColor, icon: UIImage(named: "caution")!))
        }
        return rightUtilityButtons
    }
    // MARK: 左のボタン
    func leftButtons() -> NSArray {
        let leftUtilityButtons: NSMutableArray = NSMutableArray()
        leftUtilityButtons.add(addUtilityButtonWithColor(Settings.Colors.twitterColor, icon: UIImage(named: "TwitterLogo_white_1")!))
        leftUtilityButtons.add(addUtilityButtonWithColor(Settings.Colors.userColor, icon: UIImage(named: "use_white")!))
        return leftUtilityButtons
    }
    // MARK: ボタンの追加(なんかObj-CのNSMutableArray拡張ヘッダーが上手く反映できてないので)
    func addUtilityButtonWithColor(_ color: UIColor, icon: UIImage, text: String? = nil) -> UIButton {
        let button: UIButton = UIButton(type: UIButtonType.custom)
        button.backgroundColor = color
        button.tintColor = UIColor.white
        button.setTitle(text, for: UIControlState())
        button.setImage(icon, for: UIControlState())
        return button
    }
    // MARK: 右スライドした時のボタンの挙動
    func swipeableTableViewCell(_ cell: SWTableViewCell!, didTriggerRightUtilityButtonWith index: Int) {
        let cellIndexPath: IndexPath = self.timelineTableView.indexPath(for: cell)!
        let tweet = tweetArray[(cellIndexPath as NSIndexPath).section][(cellIndexPath as NSIndexPath).row]
        switch index {
        case 0:
            // fav
            if tweet.favorited ?? false {
                swifter.postDestroyFavoriteWithID(tweet.idStr ?? "", success: {
                    statuses in
                    (cell.rightUtilityButtons[0] as? UIButton ?? UIButton()).backgroundColor = Settings.Colors.selectedColor
                    (cell.rightUtilityButtons[0] as? UIButton ?? UIButton()).setTitle("\((tweet.favoriteCount ?? 1) - 1)", for: UIControlState())
                })
                break
            }
            swifter.postCreateFavoriteWithID(tweet.idStr ?? "", success: {
                statuses in
                (cell.rightUtilityButtons[0] as? UIButton ?? UIButton()).backgroundColor = Settings.Colors.favColor
                (cell.rightUtilityButtons[0] as? UIButton ?? UIButton()).setTitle("\((tweet.favoriteCount ?? 0) + 1)", for: UIControlState())
            })
            break
        case 1:
            // reply
            replyID = tweet.idStr ?? ""
            replyStr = "@\(tweet.screenNameNoat ?? "") "
            if (tweet.userMentions ?? []).count != 0 {
                for u in tweet.userMentions! {
                    if u["screen_name"].string! != self.account?.username {
                        replyStr?.append("@\(u["screen_name"].string!) ")
                    }
                }
            }
            performSegue(withIdentifier: "toTweetView", sender: nil)
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
                (cell.rightUtilityButtons[0] as? UIButton ?? UIButton()).setTitle("\((tweet.retweetCount ?? 0) + 1)", for: UIControlState())
            })
            break
        case 3:
            // ツイートの削除
            if tweet.isMyself {
                let failureHandler: ((NSError) -> Void) = { error in
                    Utility.simpleAlert("Error: ツイートの削除に失敗しました。インターネット環境を確認してください。", presentView: self)
                }
                let successHandler: ((_ user: Dictionary<String, JSONValue>?) -> Void) = { statuses in
                    self.tweetArray = []
                    self.loadTweet()
                }
                let alertController = UIAlertController(title: "ツイートの削除", message: "このツイートを削除しますか？", preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
                    self.swifter.postStatusesDestroyWithID(tweet.idStr ?? "", success: successHandler, failure: failureHandler)
                }))
                alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                present(alertController, animated: true, completion: nil)
                
                break
            }
            
            // block or spam
            let failureHandler: ((NSError) -> Void) = { error in
                Utility.simpleAlert("Error: ブロック・通報を完了できませんでした。インターネット環境を確認してください。", presentView: self)
            }
            let successHandler: ((_ user: Dictionary<String, JSONValue>?) -> Void) = { statuses in
                self.tweetArray = []
                self.loadTweet()
            }
            let screen_name = tweet.screenNameNoat ?? ""
            let alertController = UIAlertController(title: "ブロック・通報", message: "@\(screen_name)を", preferredStyle: .actionSheet)
            alertController.addAction(UIAlertAction(title: "ブロックする", style: .default, handler: {(action) -> Void in
                let otherAlert = UIAlertController(title: "\(screen_name)をブロックする", message: "本当にブロックしますか？", preferredStyle: .alert)
                otherAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: {(action) -> Void in
                    self.swifter.postBlocksCreateWithScreenName(screen_name, includeEntities: true, success: successHandler, failure: failureHandler)
                }))
                otherAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(otherAlert, animated: true, completion: nil)
            }))
            alertController.addAction(UIAlertAction(title: "通報する", style: .default, handler: {(action) -> Void in
                let otherAlert = UIAlertController(title: "\(screen_name)を通報する", message: "本当に通報しますか？", preferredStyle: .alert)
                otherAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: {(action) -> Void in
                    self.swifter.postUsersReportSpamWithScreenName(screen_name, success: successHandler, failure: failureHandler)
                }))
                otherAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                self.present(otherAlert, animated: true, completion: nil)
            }))
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

            // iPad用
            alertController.popoverPresentationController?.sourceView = self.view
            alertController.popoverPresentationController?.sourceRect = cell.contentView.frame

            self.present(alertController, animated: true, completion: nil)
        default:
            break
        }
    }
    // MARK: 左スライドした時のボタンの挙動
    func swipeableTableViewCell(_ cell: SWTableViewCell!, didTriggerLeftUtilityButtonWith index: Int) {
        let cellIndexPath: IndexPath = self.timelineTableView.indexPath(for: cell)!
        let tweet = tweetArray[(cellIndexPath as NSIndexPath).section][(cellIndexPath as NSIndexPath).row]
        switch index {
        case 0:
            viewId = tweet.idStr ?? ""
            refresh()
            break
        case 1:
            selectedUser = tweet.screenNameNoat ?? ""
            selectedId = tweet.userId ?? ""
            performSegue(withIdentifier: "toUserView", sender: nil)
        default:
            break
        }
    }
}

// MARK: - TTTAttributedLabelDelegate
extension TweetDetailViewController: TTTAttributedLabelDelegate {
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        if let userRange = url.URLString.range(of: "account:") {
            selectedUser = url.URLString.substring(from: userRange.upperBound)
            performSegue(withIdentifier: "toUserView", sender: nil)
        } else {
            Utility.openWebView(url)
            performSegue(withIdentifier: "openWebView", sender: nil)
        }
    }
}
