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
        saveData.setObject(self.image!, forKey: "tweet_image")
        dismissViewControllerAnimated(true, completion: nil)
    }
    // Cancelボタンのとき
    @IBAction func pushCancel() {
        
    }
}
