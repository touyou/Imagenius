//
//  TweetViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/02/18.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit

class TweetViewController: UIViewController {
    @IBOutlet var stackView: UIStackView!
    
    @IBOutlet var countLabel: UILabel!
    @IBOutlet var tweetTextView: UITextView!
    @IBOutlet var searchField: UITextField!
    @IBOutlet var accountImage: UIButton!
    var tweetText: String?
    var tweetImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        stackView.autoresizesSubviews = true
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
        if searchField.text != nil {
            performSegueWithIdentifier("toImageView", sender: nil)
        } else {
            // let alertView = SCLAlertView()
        }
    }
    @IBAction func tweetButton() {
        // ツイート処理
        tweetText = tweetTextView.text
    }
    
    // segue prepare
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "toImageView" {
            let imageView = segue.destinationViewController as! ImageViewController
            imageView.searchWord = self.searchField.text!
            imageView.tweetText = self.tweetTextView.text
        }
    }
}
