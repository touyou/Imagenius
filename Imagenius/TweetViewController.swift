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

class TweetViewController: UIViewController {
    @IBOutlet var countLabel: UILabel!
    @IBOutlet var tweetTextView: UITextView!
    @IBOutlet var searchField: UITextField!
    @IBOutlet var accountImage: UIButton!
    @IBOutlet var tweetImageView: UIImageView!
    @IBOutlet var scvBackGround: UIScrollView!
    @IBOutlet var tweetImageHeight: NSLayoutConstraint!
    
    var MAX_WORD: Int = 140
    var tweetText: String?
    var replyStr: String?
    var replyID: String?
    var tweetImage: UIImage?
    var accountImg: UIImage?
    var swifter:Swifter!
    var account: ACAccount?
    let accountStore = ACAccountStore()
    var accounts = [ACAccount]()
    let saveData:NSUserDefaults = NSUserDefaults.standardUserDefaults()
    
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
        }
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
    
    // キーボード関係の処理
    // returnでキーボードを閉じる
    func textFieldShouldReturn(textField: UITextField!) -> Bool {
        view.endEditing(true)
        return true
    }
    // キーボードがあらわれたら上にあげる
    func handleKeyboardWillShowNotification(notification: NSNotification) {
        // let userInfo = notification.userInfo!
        // _ = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        // let myBoundSize: CGSize = UIScreen.mainScreen().bounds.size
        
    }
    // キーボードがいなくなったら下に下げる
    func handleKeyboardWillHideNotification(notification: NSNotification) {
    }
    
    // ボタン関係
    // 投稿せずに終了
    @IBAction func cancelButton() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    // アカウントを切り替える
    @IBAction func accountButton() {
        // アカウントの切り替えできたらいいな
        TwitterUtil.loginTwitter(self, success: { (ac) -> () in
            self.account = ac
            self.swifter = Swifter(account: self.account!)
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
    @IBAction func tweetButton() {
        // ツイート処理
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
