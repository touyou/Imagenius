//
//  TwitterUtil.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/02/22.
//  Copyright © 2016年 touyou. All rights reserved.
//

import Foundation
import UIKit
import Accounts
class TwitterUtil {
    
    class func loginTwitter(present: UIViewController) {
        let accountStore = ACAccountStore()
        var accounts = [ACAccount]()
        let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
        accountStore.requestAccessToAccountsWithType(accountType, options: nil) { granted, error in
            if granted {
                accounts = accountStore.accountsWithAccountType(accountType) as! [ACAccount]
                if accounts.count == 0 {
                    Utility.simpleAlert("Error: Twitterアカウントを設定してください。", presentView: present)
                } else {
                    self.showAndSelectTwitterAccountWithSelectionSheets(accounts, present: present)
                }
            } else {
                Utility.simpleAlert("Error", presentView: present)
            }
        }
    }
    
    // Twitterアカウントの切り替え
    class func showAndSelectTwitterAccountWithSelectionSheets(accounts: [ACAccount], present: UIViewController) {
        // アクションシートの設定
        let alertController = UIAlertController(title: "Select Account", message: "Please select twitter account", preferredStyle: .ActionSheet)
        let saveData: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        
        for var i=0; i<accounts.count; i++ {
            let account = accounts[i]
            alertController.addAction(UIAlertAction(title: account.username, style: .Default, handler: { (action) -> Void in
                // 選択したアカウントを返す
                for var j=0; j<accounts.count; j++ {
                    if account == accounts[j] {
                        print(j)
                        saveData.setObject(j, forKey: Settings.Saveword.twitter)
                        break
                    }
                }
            }))
            
        }
        
        // キャンセルボタンは何もせずにアクションシートを閉じる
        let CanceledAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(CanceledAction)
        
        // アクションシート表示
        present.presentViewController(alertController, animated: true, completion: nil)
    }
}