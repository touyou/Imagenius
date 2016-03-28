//
//  InfoContainerViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/03/28.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import Accounts
import SwifteriOS

class InfoContainerViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    let saveData:NSUserDefaults = NSUserDefaults.standardUserDefaults()
    
    @IBAction func loginButton() {
        if saveData.objectForKey(Settings.Saveword.twitter) == nil {
            TwitterUtil.loginTwitter(self, success: { (ac)->() in
                self.saveData.setObject(true, forKey: Settings.Saveword.changed)
                // 元のViewに移行
                self.dismissViewControllerAnimated(true, completion: nil)
            })
        } else {
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
}
