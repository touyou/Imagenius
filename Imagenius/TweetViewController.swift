//
//  TweetViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/02/18.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import SwifteriOS

class TweetViewController: UIViewController {
    @IBOutlet var countLabel: UILabel!
    @IBOutlet var tweetTextView: UITextView!
    @IBOutlet var searchField: UITextField!
    @IBOutlet var accountImage: UIButton!
    var tweetText: String?
    var tweetImage: UIImage?
    
    var swifter:Swifter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
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
    func handleKeyboardWillShowNotification(notification: NSNotification) {
        let userInfo = notification.userInfo!
        _ = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        // let myBoundSize: CGSize = UIScreen.mainScreen().bounds.size
        
    }
    
    func handleKeyboardWillHideNotification(notification: NSNotification) {
    }
    
    // ボタン関係
    @IBAction func cancelButton() {
        performSegueWithIdentifier("backMainView", sender: nil)
    }
    @IBAction func accountButton() {
        // アカウントの切り替えできたらいいな
    }
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
        if (tweetText == nil || tweetText == "") && tweetImage == nil {
            Utility.simpleAlert("画像かテキストを入力してください。", presentView: self)
            return
        }
        if (tweetText == nil || tweetText == "") && tweetImage != nil {
            swifter.postStatusUpdate("", media: UIImagePNGRepresentation(tweetImage!)!)
            performSegueWithIdentifier("backMainView", sender: nil)
            return
        }
        if tweetImage == nil {
            swifter.postStatusUpdate(tweetText!)
            performSegueWithIdentifier("backMainView", sender: nil)
            return
        }
        swifter.postStatusUpdate(tweetText!, media: UIImagePNGRepresentation(tweetImage!)!)
        performSegueWithIdentifier("backMainView", sender: nil)
    }
    
    // segue prepare
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "toImageView" {
            let imageView = segue.destinationViewController as! ImageViewController
            imageView.searchWord = self.searchField.text!
            imageView.tweetText = self.tweetTextView.text
            imageView.swifter = self.swifter
        } else if segue.identifier == "backMainView" {
            let mainView = segue.destinationViewController as! MainViewController
            mainView.swifter = self.swifter
        }
    }
}
