//
//  ResultViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/02/18.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import SwifteriOS

class ResultViewController: UIViewController {
    @IBOutlet var imageView: UIImageView!
    var image: UIImage?
    var tweetText: String?
    var searchWord: String = ""
    
    var swifter:Swifter!
    
    let saveData:NSUserDefaults = NSUserDefaults.standardUserDefaults()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if image == nil {
            imageView.image = UIImage(named: "empty.png")
        } else {
            imageView.image = self.image
        }
    }
    
    // OKボタンのとき
    @IBAction func pushOK() {
        performSegueWithIdentifier("toTweetView", sender: nil)
    }
    // Cancelボタンのとき
    @IBAction func pushCancel() {
        performSegueWithIdentifier("backImageView", sender: nil)
    }
    
    // TweetViewに画像情報を渡してあげる
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "toTweetView" {
            let tweetView = segue.destinationViewController as! TweetViewController
            tweetView.tweetImage = self.image
            tweetView.tweetText = self.tweetText
            tweetView.swifter = self.swifter
        } else if segue.identifier == "backImageView" {
            let imageView = segue.destinationViewController as! ImageViewController
            imageView.tweetText = self.tweetText
            imageView.searchWord = self.searchWord
            imageView.swifter = self.swifter
        }
    }
    
}
