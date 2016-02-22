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
    var accountStore = ACAccountStore()
    var accounts = [ACAccount]()
    
    init() {
    }
    
    func loginTwitter(present: UIViewController) -> ACAccount? {
        let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
        accountStore.requestAccessToAccountsWithType(accountType, options: nil) { granted, error in
            if granted {
                self.accounts = self.accountStore.accountsWithAccountType(accountType) as! [ACAccount]
                if self.accounts.count == 0 {
                    Utility.simpleAlert("Error: Twitterアカウントを設定してください。", presentView: present)
                } else {
                    let account =  self.showAndSelectTwitterAccountWithSelectionSheets(present)
                    return account
                }
            } else {
                Utility.simpleAlert("Error", presentView: present)
            }
        }
        return nil
    }
    
    // Twitterアカウントの切り替え
    func showAndSelectTwitterAccountWithSelectionSheets(present: UIViewController) -> ACAccount? {
        // アクションシートの設定
        let alertController = UIAlertController(title: "Select Account", message: "Please select twitter account", preferredStyle: .ActionSheet)
        
        for account in accounts {
            alertController.addAction(UIAlertAction(title: account.username, style: .Default, handler: { (action) -> Void in
                // 選択したアカウントをtwAccountに保存
                return account
            }))
            
        }
        
        // キャンセルボタンは何もせずにアクションシートを閉じる
        let CanceledAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alertController.addAction(CanceledAction)
        
        // アクションシート表示
        present.presentViewController(alertController, animated: true, completion: nil)
        return nil
    }
}