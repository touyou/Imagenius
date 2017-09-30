//
//  InfoContainerViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/03/28.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import Accounts

final class InfoContainerViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    let saveData: UserDefaults = UserDefaults.standard
    let twitterManager = TwitterManager.shared

    @IBAction func loginButton() {
        if saveData.object(forKey: Settings.Saveword.twitter) == nil {
            twitterManager.loginTwitter {
                self.saveData.set(true, forKey: Settings.Saveword.changed)
                // 元のViewに移行
                self.dismiss(animated: true, completion: nil)
            }
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
}
