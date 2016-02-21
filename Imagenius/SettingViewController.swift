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
import SwifteriOS

class SettingViewController: UIViewController  {
    var swifter: Swifter
    
    let useACAccount = true
    
    required init?(coder aDecoder: NSCoder) {
        self.swifter = Swifter(consumerKey: "my_key", consumerSecret: "my_secret")
        super.init(coder: aDecoder)
    }
    
    // Loginボタン
    @IBAction func didTouchUpInsideLoginButton(sender: AnyObject) {
        let failureHandler: ((NSError) -> Void) = { error in
            Utility.simpleAlert("Error", presentView: self)
        }
        
        if useACAccount {
            let accountStore = ACAccountStore()
            let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
            
            accountStore.requestAccessToAccountsWithType(accountType, options: nil) { granted, error in
                if granted {
                    let twitterAccounts = accountStore.accountsWithAccountType(accountType)
                    if twitterAccounts?.count == 0 {
                        Utility.simpleAlert("Error: Twitterアカウントを設定してください。", presentView: self)
                    } else {
                        let twitterAccount = twitterAccounts[0] as! ACAccount
                        self.swifter = Swifter(account: twitterAccount)
                        self.performSegueWithIdentifier("toMainView", sender: nil)
                    }
                } else {
                    Utility.simpleAlert("Error", presentView: self)
                }
            }
        } else {
            let url = NSURL(string: "swifter://success")!
            swifter.authorizeWithCallbackURL(url, presentFromViewController: self, success: { _ in
                self.performSegueWithIdentifier("toMainView", sender: nil)
                }, failure: failureHandler)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "toMainView" {
            let mainView = segue.destinationViewController as! MainViewController
            mainView.swifter = self.swifter
        }
    }
}
