//
//  ResultViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/02/18.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit

class ResultViewController: UIViewController {
    @IBOutlet var imageView: UIImageView!
    
    var image: UIImage?
    var data: NSData?
    var delegate: TweetViewControllerDelegate!
    
    let saveData:NSUserDefaults = NSUserDefaults.standardUserDefaults()
    
    // UIViewControllerの設定----------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        if image == nil {
            imageView.image = UIImage(named: "empty.png")
        } else {
            imageView.image = self.image
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    
    // ボタン関連-----------------------------------------------------------------
    // OKボタンのとき
    @IBAction func pushOK() {
        dismissViewControllerAnimated(true, completion: {
            self.delegate.changeImage(self.image!, data: self.data!)
        })
    }
    // Cancelボタンのとき
    @IBAction func pushCancel() {
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
    // Shareボタン
    @IBAction func shareImage() {
        let activityItems: [AnyObject]!
        activityItems = [image!]
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        let excludedActivityTypes = [UIActivityTypePostToTwitter, UIActivityTypePostToWeibo, UIActivityTypePostToTencentWeibo]
        activityVC.excludedActivityTypes = excludedActivityTypes
        // iPad用
        activityVC.popoverPresentationController?.sourceView = self.view
        activityVC.popoverPresentationController?.sourceRect = CGRectMake(0.0, 0.0, 20.0, 20.0)
        self.presentViewController(activityVC, animated: true, completion: nil)

    }
}
