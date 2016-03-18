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
        let imageData:NSData = UIImagePNGRepresentation(image!)!
        saveData.setObject(imageData, forKey: Settings.Saveword.image)
        if saveData.objectForKey(Settings.Saveword.search) != nil {
            saveData.setObject(nil, forKey: Settings.Saveword.search)
        }
        dismissViewControllerAnimated(true, completion: nil)
    }
    // Cancelボタンのとき
    @IBAction func pushCancel() {
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
}
