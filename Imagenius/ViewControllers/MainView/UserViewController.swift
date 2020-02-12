//
//  UserViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/04/07.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
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
            userTimeLine.register(UINib(nibName: "TweetTableViewCell", bundle: nil), forCellReuseIdentifier: "cell")
            userTimeLine.estimatedRowHeight = 200
            userTimeLine.rowHeight = UITableView.automaticDimension
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
            followButton.layer.borderColor = Settings.Colors.twitterColor.cgColor
        }
    }
    @IBOutlet weak var unfollowButton: UIButton! {
        didSet {
            unfollowButton.layer.cornerRadius = 5.0
            unfollowButton.layer.borderWidth = 1.0
            unfollowButton.layer.borderColor = Settings.Colors.twitterColor.cgColor
        }
    }
    @IBOutlet weak var followBtnLength: NSLayoutConstraint!
    
    var user: String!   // screen_name
    var idStr: String!
    
    var viewModel = UserViewModel()
    var avPlayerViewController: AVPlayerViewController!
    var tweetArray: [Tweet] = []
    var maxId: String!
    var replyID: String?
    var replyStr: String?
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(UserViewController.refresh), for: UIControl.Event.valueChanged)
        return refreshControl
    }()
    var imageData: NSMutableArray?
    var gifURL: URL!
    var selectedId: String!
    var myself: String!
    var reloadingFlag: Bool = false
    var muteText = [String]()
    var muteMode: Int!
    
    let saveData: UserDefaults = UserDefaults.standard
    let twitterManager = TwitterManager.shared
    // MARK: Rx
    final fileprivate let disposeBag = DisposeBag()
    
    // MARK: - UIViewControllerの設定
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 引っ張ってロードするやつ
        userTimeLine.addSubview(refreshControl)
        
        userIDLabel.text = "@\(self.user!)"
        // ボタン周り
        followButton.isHidden = true
        unfollowButton.isHidden = true
        followButton.rx.tap.subscribe({_ in self.follow()}).disposed(by: disposeBag)
        unfollowButton.rx.tap.subscribe({_ in self.unfollow()}).disposed(by: disposeBag)
        
        if saveData.object(forKey: Settings.Saveword.twitter) == nil {
            performSegue(withIdentifier: "showInfo", sender: nil)
        } else {
            title = "@\(self.user!)のツイート一覧"
            myself = twitterManager.currentSession?.userName
            
            if self.idStr == nil {
                self.getUserIdWithScreenName(self.user, comp: {
                    self.loadTweet()
                })
            } else {
                self.loadTweet()
            }
        }
        
        saveData.addObserver(self, forKeyPath: Settings.Saveword.twitter, options: [NSKeyValueObservingOptions.new, NSKeyValueObservingOptions.old], context: nil)
        saveData.addObserver(self, forKeyPath: Settings.Saveword.muteWord, options: [NSKeyValueObservingOptions.new, NSKeyValueObservingOptions.old], context: nil)
        saveData.addObserver(self, forKeyPath: Settings.Saveword.muteMode, options: [NSKeyValueObservingOptions.new, NSKeyValueObservingOptions.old], context: nil)
        
        if saveData.object(forKey: "muteWords") != nil {
            muteText = saveData.object(forKey: Settings.Saveword.muteWord) as! [String]
        } else {
            saveData.set(muteText, forKey: Settings.Saveword.muteWord)
        }
        
        if saveData.object(forKey: Settings.Saveword.muteMode) != nil {
            muteMode = saveData.object(forKey: Settings.Saveword.muteMode) as? Int
        } else {
            muteMode = 1
            saveData.set(muteMode, forKey: Settings.Saveword.muteMode)
        }
        
        viewModel.setViewController(self)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == Settings.Saveword.twitter {
            
            self.myself = twitterManager.currentSession?.userName
            if !self.reloadingFlag {
                if self.tweetArray.count != 0 {
                    let indexPath = IndexPath(row: 0, section: 0)
                    self.userTimeLine.scrollToRow(at: indexPath, at: UITableView.ScrollPosition.top, animated: false)
                }
                self.tweetArray = []
                self.loadTweet()
                self.reloadingFlag = true
            } else {
                self.reloadingFlag = false
            }
        } else if keyPath == Settings.Saveword.muteMode {
            muteMode = saveData.object(forKey: Settings.Saveword.muteMode) as? Int
            tweetArray = []
            loadTweet()
        } else if keyPath == Settings.Saveword.muteWord {
            muteText = saveData.array(forKey: Settings.Saveword.muteWord) as! [String]
            tweetArray = []
            loadTweet()
        }
    }
    
    override func didReceiveMemoryWarning() {
        let imageCache: SDImageCache = SDImageCache()
        imageCache.clearMemory()
        imageCache.clearDisk()
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
        } else if segue.identifier == "toTweetDetailView" {
            let tweetView = segue.destination as? TweetDetailViewController ?? TweetDetailViewController()
            tweetView.viewId = self.selectedId
            self.selectedId = nil
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    // MARK: - ボタン関連
    @IBAction func pushTweet() {
        self.replyStr = "@\(user!) "
        performSegue(withIdentifier: "toTweetView", sender: nil)
    }
    func unfollow() {
        
        twitterManager.unfollowUser(for: idStr, success: {
            
            self.unfollowButton.isHidden = true
            self.followButton.isHidden = false
            self.followBtnLength.constant = 100
        })
    }
    func follow() {
        
        twitterManager.followUser(for: idStr, success: {
            
            self.unfollowButton.isHidden = false
            self.followBtnLength.constant = 0
            self.followButton.isHidden = true
        })
    }
    
    // MARK: - TableView関連
    // 無し
    
    // MARK: - Utility
    // MARK: refresh処理
    @objc func refresh() {
        self.tweetArray = []
        loadTweet()
        self.refreshControl.endRefreshing()
    }
    // MARK: Tweetのロード
    func load(_ moreflag: Bool) {
        let failureHandler: ((Error?) -> Void) = { error in
            Utility.simpleAlert("Error: ユーザーのツイート一覧のロードに失敗しました。インターネット環境を確認してください。", presentView: self)
        }
        let successHandler: (([Tweet]) -> Void) = { tweets in
            
            if tweets.count < 1 {
                self.maxId = ""
            } else if tweets.count == 1 {
                if self.tweetArray.count >= 1 && self.maxId == self.tweetArray[self.tweetArray.count - 1].idStr {
                    return
                }
                if !self.isMute(tweets[0].text) {
                    self.tweetArray.append(tweets[0])
                    self.maxId = tweets[0].idStr
                } else {
                    self.maxId = ""
                }
            } else {
                for i in 0 ..< tweets.count - 1 {
                    if !self.isMute(tweets[i].text) {
                        self.tweetArray.append(tweets[i])
                    }
                }
                self.maxId = tweets[tweets.count - 1].idStr
            }
            
            // headerの設定
            if tweets.count >= 1 {
                let userInfo = tweets[0].user
                
                self.avatarImage.sd_setImage(with: userInfo.profileImageUrl, placeholderImage: nil, options: SDWebImageOptions.retryFailed)
                self.avatarImage.layer.cornerRadius = self.avatarImage.frame.size.width * 0.5
                self.avatarImage.clipsToBounds = true
                self.avatarImage.layer.borderColor = Settings.Colors.selectedColor.cgColor
                self.avatarImage.layer.borderWidth = 0.19
                
                self.userNameLabel.text = userInfo.name
                let descriptionText = userInfo.description + "\n" + "フォロー数 \(userInfo.friendsCount)   フォロワー数 \(userInfo.followersCount)"
                self.userDescription.text = descriptionText
                
                if userInfo.following {
                    
                    self.followButton.isHidden = true
                    self.followBtnLength.constant = 0
                    self.unfollowButton.isHidden = false
                } else if userInfo.followRequestSent {
                    
                    self.followButton.setTitle("フォロー許可待ち", for: UIControl.State())
                    self.followButton.isEnabled = false
                    self.followBtnLength.constant = 100
                    self.unfollowButton.isHidden = true
                    self.followButton.isHidden = false
                } else {
                    
                    self.followButton.isHidden = false
                    self.followBtnLength.constant = 100
                    self.unfollowButton.isHidden = true
                }
                
                if self.user == TwitterManager.shared.currentSession?.userName {
                    
                    self.followButton.isHidden = true
                    self.unfollowButton.isHidden = true
                }
            }
            
            self.viewModel.tweetArray = self.tweetArray
            self.userTimeLine.reloadData()
        }
        if !moreflag {
            
            TwitterManager.shared.getTimeline(for: idStr, count: 41, success: successHandler, failure: failureHandler)
        } else {
            
            TwitterManager.shared.getTimeline(for: idStr, count: 41, maxID: maxId, success: successHandler, failure: failureHandler)
        }
    }
    // MARK: Tweetをロードする
    func loadTweet() {
        if twitterManager.currentSession != nil {
            load(false)
        }
    }
    // MARK: さらに下を読み込む
    func loadMore() {
        if twitterManager.currentSession != nil {
            load(true)
        }
    }
    // MARK: screen_nameからUserIDを取得する
    func getUserIdWithScreenName(_ userName: String, comp: (() -> Void)? = nil) {
        let failureHandler: ((Error?) -> Void) = { error in
            Utility.simpleAlert("Error: ユーザーIDの取得に失敗しました。インターネット環境を確認してください。", presentView: self)
        }
        
        twitterManager.showUser(for: userName, success: { user in
            
            self.idStr = user.idStr
            comp!()
        }, failure: failureHandler)
    }
    
    // MARK: 単語ミュート
    func isMute(_ text: String) -> Bool {
        if muteMode == 1 { return false }
        let nsText = text as NSString
        for str in muteText {
            let regEx = NSRegularExpression.rx(str)
            if nsText.isMatch(regEx) { return true }
        }
        return false
    }
    
}

// MARK: - DZNEmptyDataSetの設定
extension UserViewController: DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "表示できるツイートがありません。"
        let font = UIFont.systemFont(ofSize: 20)
        return NSAttributedString(string: text, attributes: [NSAttributedString.Key.font: font])
    }
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControl.State) -> NSAttributedString! {
        return NSAttributedString(string: "リロードする")
    }
    func emptyDataSetDidTapButton(_ scrollView: UIScrollView!) {
        loadTweet()
    }
}

// MARK: - SWTableViewCell関連
extension UserViewController: SWTableViewCellDelegate {
    // MARK: 右のボタン
    func rightButtons(_ tweet: Tweet) -> NSArray {
        let rightUtilityButtons: NSMutableArray = NSMutableArray()
        if tweet.favorited {
            rightUtilityButtons.add(addUtilityButtonWithColor(Settings.Colors.favColor, icon: UIImage(named: "like-action")!, text: String(tweet.favoriteCount)))
        } else {
            rightUtilityButtons.add(addUtilityButtonWithColor(Settings.Colors.selectedColor, icon: UIImage(named: "like-action")!, text: String(tweet.favoriteCount)))
        }
        rightUtilityButtons.add(addUtilityButtonWithColor(Settings.Colors.twitterColor, icon: UIImage(named: "reply-action_0")!))
        if tweet.retweeted {
            rightUtilityButtons.add(addUtilityButtonWithColor(Settings.Colors.retweetColor, icon: UIImage(named: "retweet-action")!, text: String(tweet.retweetCount)))
        } else {
            rightUtilityButtons.add(addUtilityButtonWithColor(Settings.Colors.selectedColor, icon: UIImage(named: "retweet-action")!, text: String(tweet.retweetCount)))
        }
        if tweet.isMe ?? false {
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
        return leftUtilityButtons
    }
    // MARK: ボタンの追加(なんかObj-CのNSMutableArray拡張ヘッダーが上手く反映できてないので)
    func addUtilityButtonWithColor(_ color: UIColor, icon: UIImage, text: String? = nil) -> UIButton {
        let button: UIButton = UIButton(type: UIButton.ButtonType.custom)
        button.backgroundColor = color
        button.tintColor = UIColor.white
        button.setTitle(text, for: UIControl.State())
        button.setImage(icon, for: UIControl.State())
        return button
    }
    // MARK: 右スライドした時のボタンの挙動
    func swipeableTableViewCell(_ cell: SWTableViewCell!, didTriggerRightUtilityButtonWith index: Int) {
        let cellIndexPath: IndexPath = self.userTimeLine.indexPath(for: cell)!
        let tweet = tweetArray[cellIndexPath.row]
        switch index {
        case 0:
            // fav
            if tweet.favorited {
                
                twitterManager.unfavoriteTweet(for: tweet.idStr, success: {
                    
                    (cell.rightUtilityButtons[0] as? UIButton ?? UIButton()).backgroundColor = Settings.Colors.selectedColor
                    (cell.rightUtilityButtons[0] as? UIButton ?? UIButton()).setTitle("\(tweet.favoriteCount - 1)", for: UIControl.State())
                })
                break
            }
            twitterManager.favoriteTweet(for: tweet.idStr , success: {
                
                (cell.rightUtilityButtons[0] as? UIButton ?? UIButton()).backgroundColor = Settings.Colors.favColor
                (cell.rightUtilityButtons[0] as? UIButton ?? UIButton()).setTitle("\(tweet.favoriteCount + 1)", for: UIControl.State())
            })
            break
        case 1:
            // reply
            replyID = tweet.idStr
            replyStr = "@\(tweet.user.screenName) "
            if tweet.entities.mentions.count != 0 {
                
                for u in tweet.entities.mentions
                    where u.screenName != twitterManager.currentSession?.userName {
                        
                        replyStr?.append("@\(u.screenName) ")
                }
            }
            performSegue(withIdentifier: "toTweetView", sender: nil)
            break
        case 2:
            
            // retweet
            if tweet.retweeted {
                
                twitterManager.unretweetTweet(for: tweet.idStr, success: {
                    
                    (cell.rightUtilityButtons[2] as? UIButton ?? UIButton()).backgroundColor = Settings.Colors.selectedColor
                    (cell.rightUtilityButtons[0] as? UIButton ?? UIButton()).setTitle("\((tweet.retweetCount) - 1)", for: UIControl.State())
                })
                break
            }
            let alertController = UIAlertController(title: "リツイート", message: "リツイートの種類を選択してください。", preferredStyle: .actionSheet)
            alertController.addAction(title: "公式リツイート", style: .default, handler: {(_) -> Void in
                
                TwitterManager.shared.retweetTweet(for: tweet.idStr, success: {
                    
                    (cell.rightUtilityButtons[2] as? UIButton ?? UIButton()).backgroundColor = Settings.Colors.retweetColor
                    (cell.rightUtilityButtons[0] as? UIButton ?? UIButton()).setTitle("\((tweet.retweetCount) + 1)", for: UIControl.State())
                })
            })
                .addAction(title: "引用リツイート", style: .default, handler: {(_) -> Void in
                    var rtMode: Int = 5
                    if self.saveData.object(forKey: "rtMode") != nil {
                        
                        rtMode = self.saveData.object(forKey: "rtMode") as! Int
                    } else {
                        
                        self.saveData.set(rtMode, forKey: "rtMode")
                    }
                    if rtMode >= Settings.RTWord.count {
                        switch (rtMode) {
                        case 4:
                            self.replyStr = "\"" + tweet.text + "\""
                        case 5:
                            self.replyStr = tweet.urlStr
                        default: break
                        }
                    } else {
                        self.replyStr = Settings.RTWord[rtMode] + tweet.text
                    }
                    self.performSegue(withIdentifier: "toTweetView", sender: nil)
                })
                .addAction(title: "Cancel", style: .cancel, handler: nil)
                .show()
            break
        case 3:
            
            // ツイートの削除
            if tweet.isMe ?? false {
                let failureHandler: ((Error?) -> Void) = { error in
                    Utility.simpleAlert("Error: ツイートの削除に失敗しました。インターネット環境を確認してください。", presentView: self)
                }
                let successHandler: (() -> Void) = {
                    
                    self.tweetArray = []
                    self.loadTweet()
                }
                let alertController = UIAlertController(title: "ツイートの削除", message: "このツイートを削除しますか？", preferredStyle: .alert)
                alertController.addAction(title: "OK", style: .default, handler: { (_) -> Void in
                    
                    TwitterManager.shared.destroyTweet(for: tweet.idStr, success: successHandler, failure: failureHandler)
                })
                    .addAction(title: "Cancel", style: .cancel, handler: nil)
                    .show()
                
                break
            }
            
            // block or spam
            let failureHandler: ((Error?) -> Void) = { error in
                Utility.simpleAlert("Error: ブロック・通報を完了できませんでした。インターネット環境を確認してください。", presentView: self)
            }
            let successHandler: (() -> Void) = {
                
                self.tweetArray = []
                self.loadTweet()
            }
            let screenName: String = tweet.user.screenName
            let alertController = UIAlertController(title: "ブロック・通報", message: "@\(screenName)を", preferredStyle: .actionSheet)
            alertController.addAction(title: "ブロックする", style: .default, handler: { _ in
                
                let message: String? = "本当にブロックしますか？"
                var alert = UIAlertController(title: "@" + screenName + "をブロックする", message: message, preferredStyle: .alert)
                alert = alert.addAction(title: "OK", handler: { _ in
                        
                        TwitterManager.shared.blockUser(for: screenName, success: successHandler, failure: failureHandler)
                    })
                    .addAction(title: "Cancel", style: .cancel, handler: nil)
                alert.show()
            }).addAction(title: "通報する", style: .default, handler: { _ in
                
                var alert = UIAlertController(title: "@" + screenName + "を通報する", message: "本当に通報しますか？", preferredStyle: .alert)
                alert = alert.addAction(title: "OK", handler: { _ in
                        
                        TwitterManager.shared.reportUser(for: screenName, success: successHandler, failure: failureHandler)
                    })
                    .addAction(title: "Cancel", style: .cancel, handler: nil)
                alert.show()
            })
                .addAction(title: "Cancel", style: .cancel, handler: nil)
                .show()
        default:
            break
        }
    }
    // MARK: 左スライドした時のボタンの挙動
    func swipeableTableViewCell(_ cell: SWTableViewCell!, didTriggerLeftUtilityButtonWith index: Int) {
        let cellIndexPath: IndexPath = self.userTimeLine.indexPath(for: cell)!
        let tweet = tweetArray[(cellIndexPath as NSIndexPath).row]
        switch index {
        case 0:
            selectedId = tweet.idStr
            performSegue(withIdentifier: "toTweetDetailView", sender: nil)
            break
        default:
            break
        }
    }
}

// MARK: - TTTAttributedLabelDelegate
extension UserViewController: TTTAttributedLabelDelegate {
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        if let userRange = url.absoluteString.range(of: "account:") {
            
            user = String(url.absoluteString.suffix(from: userRange.upperBound))
            getUserIdWithScreenName(user, comp: {
                self.tweetArray = []
                self.title = "@\(self.user!)のツイート一覧"
                self.userIDLabel.text = "@\(self.user!)"
                self.loadTweet()
            })
        } else {
            Utility.openWebView(url)
            performSegue(withIdentifier: "openWebView", sender: nil)
        }
    }
}
