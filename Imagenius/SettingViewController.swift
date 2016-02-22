//
//  SettingViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/02/21.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import Accounts
import Social

class SettingViewController: UIViewController  {
    let saveData:NSUserDefaults = NSUserDefaults.standardUserDefaults()
    
    var twAccount = ACAccount()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // Loginボタン
    @IBAction func didTouchUpInsideLoginButton(sender: AnyObject) {
        twAccount = TwitterUtil.loginTwitter(self)
    }
    
    
}
