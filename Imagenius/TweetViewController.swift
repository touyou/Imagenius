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
    
    var MAX_WORD: Int = 140
    var tweetText: String?
    var tweetImage: UIImage?
    var swifter:Swifter!
    let saveData:NSUserDefaults = NSUserDefaults.standardUserDefaults()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if saveData.objectForKey("twitter") == nil {
            TwitterUtil.loginTwitter(self)
        }
        let accountStore = ACAccountStore()
        var accounts = [ACAccount]()
        var account: ACAccount?
        let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
        accountStore.requestAccessToAccountsWithType(accountType, options: nil) { granted, error in
            if granted {
                accounts = accountStore.accountsWithAccountType(accountType) as! [ACAccount]
                if accounts.count != 0 {
                    account = accounts[self.saveData.objectForKey("twitter") as! Int]
                    self.swifter = Swifter(account: account!)
                }
            }
        }
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "handleKeyboardWillShowNotification:", name: UIKeyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: "handleKeyboardWillHideNotification:", name: UIKeyboardWillHideNotification, object: nil)
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
        let userInfo = notification.userInfo!
        _ = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
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
        TwitterUtil.loginTwitter(self)
        let accountStore = ACAccountStore()
        var accounts = [ACAccount]()
        var account: ACAccount?
        let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
        accountStore.requestAccessToAccountsWithType(accountType, options: nil) { granted, error in
            if granted {
                accounts = accountStore.accountsWithAccountType(accountType) as! [ACAccount]
                if accounts.count != 0 {
                    account = accounts[self.saveData.objectForKey("twitter") as! Int]
                    self.swifter = Swifter(account: account!)
                }
            }
        }
    }
    // 画像検索へ
    @IBAction func searchButton() {
        if searchField.text != "" {
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
            swifter.postStatusUpdate(tweetText!)
            dismissViewControllerAnimated(true, completion: nil)
            return
        }
        swifter.postStatusUpdate(tweetText!, media: UIImagePNGRepresentation(tweetImage!)!)
        dismissViewControllerAnimated(true, completion: nil)
    }
}
