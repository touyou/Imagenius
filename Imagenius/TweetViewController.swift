//
//  TweetViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/02/18.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit

class TweetViewController: UIViewController {
    @IBOutlet var countLabel: UILabel!
    @IBOutlet var tweetTextView: UITextView!
    @IBOutlet var searchField: UITextField!
    @IBOutlet var accountImage: UIButton!
    var tweetText: String?
    var tweetImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // ボタン関係
    @IBAction func cancelButton() {
        self.dismissViewControllerAnimated(true, completion: nil)
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
