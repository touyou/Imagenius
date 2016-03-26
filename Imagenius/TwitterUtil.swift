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
import SwifteriOS

class TwitterUtil {
    // login
    class func loginTwitter(present: UIViewController, success: ((ACAccount?) -> ())? = nil) {
        let accountStore = ACAccountStore()
        var accounts = [ACAccount]()
        let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
        accountStore.requestAccessToAccountsWithType(accountType, options: nil) { granted, error in
            if granted {
                accounts = accountStore.accountsWithAccountType(accountType) as! [ACAccount]
                if accounts.count == 0 {
                    Utility.simpleAlert("Error: Twitterアカウントを設定してください。", presentView: present)
                } else {
                    self.showAndSelectTwitterAccountWithSelectionSheets(accounts, present: present, success: success)
                }
            } else {
                Utility.simpleAlert("Error", presentView: present)
            }
        }
    }
    
    // Twitterアカウントの切り替え
    class func showAndSelectTwitterAccountWithSelectionSheets(accounts: [ACAccount], present: UIViewController, success: ((ACAccount?)->())? = nil) {
        // アクションシートの設定
        let alertController = UIAlertController(title: "アカウント選択", message: "使用するTwitterアカウントを選択してください", preferredStyle: .ActionSheet)
        let saveData: NSUserDefaults = NSUserDefaults.standardUserDefaults()
        
        for i in 0 ..< accounts.count {
            let account = accounts[i]
            alertController.addAction(UIAlertAction(title: account.username, style: .Default, handler: { (action) -> Void in
                // 選択したアカウントを返す
                for j in 0 ..< accounts.count {
                    if account == accounts[j] {
                        print(j)
                        saveData.setObject(j, forKey: Settings.Saveword.twitter)
                        break
                    }
                }
                success?(account)
            }))
            
        }
        
        // キャンセルボタンは何もせずにアクションシートを閉じる
        let CanceledAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(CanceledAction)
        
        // iPad用
        alertController.popoverPresentationController?.sourceView = present.view
        alertController.popoverPresentationController?.sourceRect = CGRectMake(0.0, 0.0, 20.0, 20.0)
        
        // アクションシート表示
        present.presentViewController(alertController, animated: true, completion: nil)
    }
    
    // 画像がツイートに含まれているか？
    class func isContainMedia(tweet: JSONValue) -> Bool {
        if tweet["extended_entities"].object != nil {
            return true
        }
        return false
    }
}