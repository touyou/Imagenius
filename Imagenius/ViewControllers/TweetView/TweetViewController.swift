//
//  TweetViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/02/18.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import SwifteriOS
import Accounts
import GoogleMobileAds
import RxSwift
import RxCocoa
import SDWebImage

protocol TweetViewControllerDelegate {
    func changeImage(image: UIImage, data: NSData)
}

class TweetViewController: UIViewController, TweetViewControllerDelegate {
    @IBOutlet var countLabel: UILabel!
    @IBOutlet var placeHolderLabel: UILabel!
    @IBOutlet var tweetTextView: UITextView!
    @IBOutlet var searchField: UITextField!
    @IBOutlet var accountImage: UIButton!
    @IBOutlet var tweetImageView: UIImageView!
    @IBOutlet var scvBackGround: UIScrollView!
    @IBOutlet var tweetImageHeight: NSLayoutConstraint!
    // Google Ads関連
    @IBOutlet var bannerView: GADBannerView!
    
    var MAX_WORD: Int = 140
    var tweetText: String?
    var replyStr: String?
    var replyID: String?
    var tweetImage: UIImage?
    var tweetImageData: NSData?
    var accountImg: UIImage?
    var swifter:Swifter!
    var account: ACAccount?
    var accounts = [ACAccount]()
    
    let accountStore = ACAccountStore()
    let saveData:NSUserDefaults = NSUserDefaults.standardUserDefaults()
    let disposeBag = DisposeBag()
    
    // UIViewControllerの設定----------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        if saveData.objectForKey(Settings.Saveword.twitter) == nil {
            TwitterUtil.loginTwitter(self, success: { (ac) -> () in
                self.account = ac
                self.swifter = Swifter(account: self.account!)
                self.changeAccountImage()
            })
        } else {
            let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
            accountStore.requestAccessToAccountsWithType(accountType, options: nil) { granted, error in
                if granted {
                    self.accounts = self.accountStore.accountsWithAccountType(accountType) as! [ACAccount]
                    if self.accounts.count != 0 {
                        self.account = self.accounts[self.saveData.objectForKey(Settings.Saveword.twitter) as! Int]
                        self.swifter = Swifter(account: self.account!)
                        self.changeAccountImage()
                    }
                }
            }
        }
        // レイアウト
        if replyStr != nil {
            tweetTextView.text = replyStr
        }
        searchField.placeholder = "画像を検索する"
        tweetImageHeight.constant = 0
        
        // RxSwiftで文字数を監視
        tweetTextView.rx_text
            .map { "\($0.characters.count)" }
            .bindTo(countLabel.rx_text)
            .addDisposableTo(disposeBag)
        tweetTextView.rx_text
            .map {
                if $0.characters.count == 0 {
                    self.placeHolderLabel.text = "何をつぶやく？"
                } else if $0.characters.count > self.MAX_WORD {
                    self.placeHolderLabel.text = nil
                    self.countLabel.textColor = Settings.Colors.mainColor
                } else {
                    self.placeHolderLabel.text = nil
                    self.countLabel.textColor = Settings.Colors.selectedColor
                }
            }
            .subscribe {}
            .addDisposableTo(disposeBag)
        
        // Google Ads関連
        self.bannerView.adSize = kGADAdSizeSmartBannerPortrait
        // for test
        // self.bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        // for sale
        self.bannerView.adUnitID = "ca-app-pub-2853999389157478/5283774064"
        self.bannerView.rootViewController = self
        self.bannerView.loadRequest(GADRequest())
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if accountImg == nil {
            self.accountImage.setTitle("login", forState: .Normal)
        }
        
        searchField.text = ""
        
        self.view.layoutIfNeeded()
    }
    
    override func didReceiveMemoryWarning() {
        let imageCache: SDImageCache = SDImageCache()
        imageCache.clearMemory()
        imageCache.clearDisk()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "toImageView" {
            let navViewCtrl: UINavigationController = segue.destinationViewController as! UINavigationController
            let tiqavViewCtrl: TiqavImageViewController = navViewCtrl.viewControllers[0] as! TiqavImageViewController
            tiqavViewCtrl.searchWord = searchField.text!
            tiqavViewCtrl.delegate = self
        }
    }
    
    // ボタン関係-----------------------------------------------------------------
    // 投稿せずに終了
    @IBAction func cancelButton() {
        tweetText = tweetTextView.text
        if (tweetText == nil || tweetText == "") && tweetImage == nil {
            self.dismissViewControllerAnimated(true, completion: nil)
        } else {
            let alertController = UIAlertController(title: "編集内容が破棄されます。", message: "よろしいですか？", preferredStyle: .Alert)
            alertController.addAction(UIAlertAction(title: "はい", style: .Default, handler: {
                action in
                self.dismissViewControllerAnimated(true, completion: nil)
            }))
            alertController.addAction(UIAlertAction(title: "いいえ", style: .Cancel, handler: nil))
            self.presentViewController(alertController, animated: true, completion: nil)
        }
    }
    // アカウントを切り替える
    @IBAction func accountButton() {
        // アカウントの切り替え
        TwitterUtil.loginTwitter(self, success: { (ac) -> () in
            self.account = ac
            self.swifter = Swifter(account: self.account!)
            self.saveData.setObject(true, forKey: Settings.Saveword.changed)
            self.changeAccountImage()
        })
    }
    // 画像検索へ
    @IBAction func searchButton() {
        if searchField.text != "" {
            performSegueWithIdentifier("toImageView", sender: nil)
        } else {
            Utility.simpleAlert("検索ワードを入力してください。", presentView: self)
        }
    }
    // ツイート処理
    @IBAction func tweetButton() {
        // ここに140字以上の処理を書く
        tweetText = tweetTextView.text
        if (tweetText!.characters.count > MAX_WORD) {
            Utility.simpleAlert("140字を超えています。", presentView: self)
            return
        }
        if (tweetText == nil || tweetText == "") && tweetImage == nil {
            Utility.simpleAlert("画像かテキストを入力してください。", presentView: self)
            return
        }
        if (tweetText == nil || tweetText == "") && tweetImageData != nil {
            swifter.postStatusUpdate("", media: tweetImageData!)
            dismissViewControllerAnimated(true, completion: nil)
            return
        }
        if tweetImageData == nil {
            swifter.postStatusUpdate(tweetText!, inReplyToStatusID: replyID)
            dismissViewControllerAnimated(true, completion: nil)
            return
        }
        swifter.postStatusUpdate(tweetText!, media: tweetImageData!, inReplyToStatusID: replyID)
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    // キーボード関係の処理---------------------------------------------------------
    // returnでキーボードを閉じる
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        view.endEditing(true)
        return true
    }
    
    // Utility------------------------------------------------------------------
    // アカウントの画像を切替える
    func changeAccountImage() {
        let failureHandler: ((NSError) -> Void) = { error in
            Utility.simpleAlert("Error: プロフィール画像を取得できませんでした。インターネット環境を確認してください。", presentView: self)
        }
        swifter.getUsersShowWithScreenName(account!.username, success: {(user) -> Void in
            if let userDict = user {
                if let userImage = userDict["profile_image_url_https"] {
                    self.accountImg = Utility.resizeImage(UIImage(data: NSData(contentsOfURL: NSURL(string: userImage.string!)!)!)!, size: CGSize(width: 50, height: 50))
                    self.accountImage.layer.cornerRadius = self.accountImage.frame.size.width * 0.5
                    self.accountImage.clipsToBounds = true
                    self.accountImage.setImage(self.accountImg, forState: .Normal)
                }
            }
        }, failure: failureHandler)
    }
    // ツイートに添付する画像
    func changeImage(image: UIImage, data: NSData) {
        tweetImageHeight.constant = 110
        tweetImage = image
        tweetImageView.image = tweetImage
        tweetImageData = data
    }
}
