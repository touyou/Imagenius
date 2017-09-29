//
//  ViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/02/10.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import TTTAttributedLabel
import DZNEmptyDataSet
import SWTableViewCell
import AVKit
import AVFoundation
import SDWebImage
import RegExCategories

class MainViewController: UIViewController, UITableViewDelegate {
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
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(MainViewController.refresh), for: UIControlEvents.valueChanged)
        return refreshControl
    }()
    
    var viewModel = MainViewModel()
    var avPlayerViewController: AVPlayerViewController!
    var tweetArray: [Tweet] = []
    var maxId: String!
    var replyID: String?
    var replyStr: String?
    var imageData: NSMutableArray?
    var gifURL: URL!
    var selectedUser: String!
    var selectedId: String!
    var myself: String!
    var reloadingFlag: Bool = false
    var muteText = [String]()
    var muteMode: Int!
    
    let twitterManager = TwitterManager.shared
    let saveData: UserDefaults = UserDefaults.standard
    
    // MARK: - UIViewControllerの設定
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 引っ張ってロードするやつ
        timelineTableView.addSubview(refreshControl)
        
        saveData.addObserver(self, forKeyPath: Settings.Saveword.twitter, options: [NSKeyValueObservingOptions.new, NSKeyValueObservingOptions.old], context: nil)
        saveData.addObserver(self, forKeyPath: Settings.Saveword.muteWord, options: [NSKeyValueObservingOptions.new, NSKeyValueObservingOptions.old], context: nil)
        saveData.addObserver(self, forKeyPath: Settings.Saveword.muteMode, options: [NSKeyValueObservingOptions.new, NSKeyValueObservingOptions.old], context: nil)
        
        if saveData.object(forKey: Settings.Saveword.twitter) == nil {
            
            performSegue(withIdentifier: "showInfo", sender: nil)
        } else {
            
            if let _ = twitterManager.currentSession {
                
                twitterManager.loadHomeTimelineTweet(count: 1, success: { tweets in
                    
                    print(tweets)
                })
            } else {
                
                twitterManager.loginTwitter()
            }
        }
        
        if saveData.object(forKey: "muteWords") != nil {
            muteText = saveData.object(forKey: Settings.Saveword.muteWord) as! [String]
        } else {
            saveData.set(muteText, forKey: Settings.Saveword.muteWord)
        }
        
        if saveData.object(forKey: Settings.Saveword.muteMode) != nil {
            muteMode = saveData.object(forKey: Settings.Saveword.muteMode) as! Int
        } else {
            muteMode = 1
            saveData.set(muteMode, forKey: Settings.Saveword.muteMode)
        }
        
        viewModel.setViewController(self)
    }
    
    // MARK: アカウントが切り替わった時点でページをリロードしている
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == Settings.Saveword.twitter {
            
            if !self.reloadingFlag {
                
                if self.tweetArray.count != 0 {
                    
                    let indexPath = IndexPath(row: 0, section: 0)
                    self.timelineTableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.top, animated: false)
                }
                self.tweetArray = []
                self.loadTweet()
                self.reloadingFlag = true
            } else {
                self.reloadingFlag = false
            }
        } else if keyPath == Settings.Saveword.muteMode {
            
            muteMode = saveData.object(forKey: Settings.Saveword.muteMode) as! Int
            tweetArray = []
            loadTweet()
        } else if keyPath == Settings.Saveword.muteWord {
            
            muteText = saveData.array(forKey: Settings.Saveword.muteWord) as! [String]
            tweetArray = []
            loadTweet()
        }
    }
    
    // MARK: メモリーがいっぱいになったらSDWebImageのキャッシュを削除
    override func didReceiveMemoryWarning() {
        let imageCache: SDImageCache = SDImageCache()
        imageCache.clearMemory()
        imageCache.clearDisk()
    }
    
    // MARK: 各Viewへ移り変わるときに渡す値
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
        } else if segue.identifier == "toTweetDetailView" {
            let tweetView = segue.destination as? TweetDetailViewController ?? TweetDetailViewController()
            tweetView.viewId = self.selectedId
            self.selectedId = nil
        }
    }
    
    // MARK: ステータスバーを細く
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    // MARK: - ボタン関連
    @IBAction func pushTweet() {
        performSegue(withIdentifier: "toTweetView", sender: nil)
    }
    @IBAction func pushUser() {
        
        selectedUser = twitterManager.currentSession!.userName
        performSegue(withIdentifier: "toUserView", sender: nil)
    }
    
    // MARK: - Utility
    // MARK: refresh処理
    @objc func refresh() {
        self.tweetArray = []
        loadTweet()
        self.refreshControl.endRefreshing()
    }
    // MARK: Tweetのロード
    func load(_ moreflag: Bool) {
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
    func loginDone() {}
    
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
extension MainViewController: DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "表示できるツイートがありません。"
        let font = UIFont.systemFont(ofSize: 20)
        return NSAttributedString(string: text, attributes: [NSAttributedStringKey.font: font])
    }
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
        return NSAttributedString(string: "リロードする")
    }
    func emptyDataSetDidTapButton(_ scrollView: UIScrollView!) {
        loadTweet()
    }
}

// MARK: - SWTableViewCell関連
extension MainViewController: SWTableViewCellDelegate {
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
        let tweet = tweetArray[cellIndexPath.row]
        switch index {
        case 0:
            // fav
            if tweet.favorited {
                
                twitterManager.unfavoriteTweet(for: tweet.idStr, success: {
                    
                    (cell.rightUtilityButtons[0] as? UIButton ?? UIButton()).backgroundColor = Settings.Colors.selectedColor
                    (cell.rightUtilityButtons[0] as? UIButton ?? UIButton()).setTitle("\(tweet.favoriteCount - 1)", for: UIControlState())
                })
                break
            }
            twitterManager.favoriteTweet(for: tweet.idStr , success: {
                
                (cell.rightUtilityButtons[0] as? UIButton ?? UIButton()).backgroundColor = Settings.Colors.favColor
                (cell.rightUtilityButtons[0] as? UIButton ?? UIButton()).setTitle("\(tweet.favoriteCount + 1)", for: UIControlState())
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
                    (cell.rightUtilityButtons[0] as? UIButton ?? UIButton()).setTitle("\((tweet.retweetCount) - 1)", for: UIControlState())
                })
                break
            }
            let alertController = UIAlertController(title: "リツイート", message: "リツイートの種類を選択してください。", preferredStyle: .actionSheet)
            alertController.addAction(title: "公式リツイート", style: .default, handler: {(_) -> Void in
                
                TwitterManager.shared.retweetTweet(for: tweet.idStr, success: {
                    
                    (cell.rightUtilityButtons[2] as? UIButton ?? UIButton()).backgroundColor = Settings.Colors.retweetColor
                    (cell.rightUtilityButtons[0] as? UIButton ?? UIButton()).setTitle("\((tweet.retweetCount) + 1)", for: UIControlState())
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
            let failureHandler: ((Error) -> Void) = { error in
                Utility.simpleAlert("Error: ブロック・通報を完了できませんでした。インターネット環境を確認してください。", presentView: self)
            }
            let successHandler: (() -> Void) = {
                
                self.tweetArray = []
                self.loadTweet()
            }
            let screenName: String = tweet.user.screenName
            let alertController = UIAlertController(title: "ブロック・通報", message: "@\(screenName)を", preferredStyle: .actionSheet)
            alertController.addAction(title: "ブロックする", style: .default, handler: {(_) -> Void in
                
                let otherAlert = UIAlertController(title: "\(screenName)をブロックする", message: "本当にブロックしますか？", preferredStyle: .alert)
                otherAlert.addAction(title: "OK", style: .default, handler: {(_) -> Void in
                    
                    TwitterManager.shared.blockUser(for: screenName, success: successHandler, failure: failureHandler)
                }).addAction(title: "Cancel", style: .cancel).show()
            }).addAction(title: "通報する", style: .default, handler: {(_) -> Void in
                
                let otherAlert = UIAlertController(title: "\(screenName)を通報する", message: "本当に通報しますか？", preferredStyle: .alert)
                otherAlert.addAction(title: "OK", handler: { _ in
                    
                    TwitterManager.shared.reportSpam(for: screenName, success: successHandler, failure: failureHandler)
                }).addAction(title: "Cancel", style: .cancel).show()
            }).addAction(title: "Cancel", style: .cancel).show()
        default:
            break
        }
    }
    // MARK: 左スライドした時のボタンの挙動
    func swipeableTableViewCell(_ cell: SWTableViewCell!, didTriggerLeftUtilityButtonWith index: Int) {
        let cellIndexPath: IndexPath = self.timelineTableView.indexPath(for: cell)!
        let tweet = tweetArray[(cellIndexPath as NSIndexPath).row]
        switch index {
        case 0:
            
            selectedId = tweet.idStr
            performSegue(withIdentifier: "toTweetDetailView", sender: nil)
            break
        case 1:
            
            selectedUser = tweet.user.screenName
            selectedId = tweet.user.idStr
            performSegue(withIdentifier: "toUserView", sender: nil)
        default:
            break
        }
    }
}

// MARK: - TTTAttributedLabelDelegate
extension MainViewController: TTTAttributedLabelDelegate {
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        if let userRange = url.absoluteString.range(of: "account:") {
            selectedUser = url.absoluteString.substring(from: userRange.upperBound)
            performSegue(withIdentifier: "toUserView", sender: nil)
        } else {
            Utility.openWebView(url)
            performSegue(withIdentifier: "openWebView", sender: nil)
        }
    }
}
