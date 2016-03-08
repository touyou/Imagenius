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

class TweetViewController: UIViewController, UITextViewDelegate {
    @IBOutlet var countLabel: UILabel!
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
    var accountImg: UIImage?
    var swifter:Swifter!
    var account: ACAccount?
    var accounts = [ACAccount]()
    
    let accountStore = ACAccountStore()
    let saveData:NSUserDefaults = NSUserDefaults.standardUserDefaults()
    
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
        if replyStr != nil {
            tweetTextView.text = replyStr
            tweetTextView.textColor = Settings.Colors.textBlackColor
        } else {
            tweetTextView.text = "何をつぶやく？"
            tweetTextView.textColor = UIColor.lightGrayColor()
        }
        searchField.placeholder = "画像を検索する"
        
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

        if saveData.objectForKey(Settings.Saveword.image) != nil {
            tweetImageHeight.constant = 110
            tweetImage = UIImage(data: (saveData.objectForKey(Settings.Saveword.image) as? NSData)!)
            tweetImageView.image = tweetImage
            saveData.setObject(nil, forKey: Settings.Saveword.image)
        } else {
            tweetImageHeight.constant = 0
        }
        
        if accountImg == nil {
            self.accountImage.setTitle("login", forState: .Normal)
        }
        
        searchField.text = ""
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "handleKeyboardWillShowNotification:", name: UIKeyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: "handleKeyboardWillHideNotification:", name: UIKeyboardWillHideNotification, object: nil)
        self.view.layoutIfNeeded()
    }
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        notificationCenter.removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    
    // ボタン関係-----------------------------------------------------------------
    // 投稿せずに終了
    @IBAction func cancelButton() {
        dismissViewControllerAnimated(true, completion: nil)
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
            saveData.setObject(searchField.text!, forKey: Settings.Saveword.search)
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
        if (tweetText == nil || tweetText == "") && tweetImage != nil {
            swifter.postStatusUpdate("", media: UIImagePNGRepresentation(tweetImage!)!)
            dismissViewControllerAnimated(true, completion: nil)
            return
        }
        if tweetImage == nil {
            swifter.postStatusUpdate(tweetText!, inReplyToStatusID: replyID)
            dismissViewControllerAnimated(true, completion: nil)
            return
        }
        swifter.postStatusUpdate(tweetText!, media: UIImagePNGRepresentation(tweetImage!)!, inReplyToStatusID: replyID)
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    // キーボード関係の処理---------------------------------------------------------
    // returnでキーボードを閉じる
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        view.endEditing(true)
        return true
    }
    // キーボードがあらわれた時の処理
    func handleKeyboardWillShowNotification(notification: NSNotification) {
    }
    // キーボードがいなくなった時の処理
    func handleKeyboardWillHideNotification(notification: NSNotification) {
    }
    
    // textViewのプレースホルダー--------------------------------------------------
    // 編集はじめ
    func textViewDidBeginEditing(textView: UITextView) {
        if textView.textColor == UIColor.lightGrayColor() {
            textView.text = replyStr
            textView.textColor = Settings.Colors.textBlackColor
        }
    }
    // 編集中
    // func textViewDidChange(textView: UITextView) {
    // }
    // 編集終わり
    func textViewDidEndEditing(textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "何をつぶやく？"
            textView.textColor = UIColor.lightGrayColor()
        }
    }
    
    // Utility------------------------------------------------------------------
    // アカウントの画像を切替える
    func changeAccountImage() {
        let failureHandler: ((NSError) -> Void) = { error in
            Utility.simpleAlert(String(error.localizedFailureReason), presentView: self)
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
}
