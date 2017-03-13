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

final class TwitterUtil {
    // MARK: login
    class func loginTwitter(_ present: UIViewController, success: ((ACAccount?) -> Void)? = nil) {
        let accountStore = ACAccountStore()
        var accounts = [ACAccount]()
        let accountType = accountStore.accountType(withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter)
        accountStore.requestAccessToAccounts(with: accountType, options: nil) { granted, _ in
            if granted {
                accounts = accountStore.accounts(with: accountType) as? [ACAccount] ?? []
                if accounts.count == 0 {
                    Utility.simpleAlert("Error: Twitterアカウントを設定してください。", presentView: present)
                } else {
                    self.showAndSelectTwitterAccountWithSelectionSheets(accounts, present: present, success: success)
                }
            } else {
                Utility.simpleAlert("Error: Twitterアカウントへのアクセスを許可してください。", presentView: present)
            }
        }
    }

    // MARK: Twitterアカウントの切り替え
    class func showAndSelectTwitterAccountWithSelectionSheets(_ accounts: [ACAccount], present: UIViewController, success: ((ACAccount?) -> Void)? = nil) {
        // アクションシートの設定
        let alertController = UIAlertController(title: "アカウント選択", message: "使用するTwitterアカウントを選択してください", preferredStyle: .actionSheet)
        let saveData: UserDefaults = UserDefaults.standard

        for i in 0 ..< accounts.count {
            let account = accounts[i]
            alertController.addAction(UIAlertAction(title: account.username, style: .default, handler: { (_) -> Void in
                // 選択したアカウントを返す
                for j in 0 ..< accounts.count {
                    if account == accounts[j] {
                        print(j)
                        saveData.set(j, forKey: Settings.Saveword.twitter)
                        break
                    }
                }
                success?(account)
            }))

        }

        // キャンセルボタンは何もせずにアクションシートを閉じる
        let CanceledAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(CanceledAction)

        // iPad用
        alertController.popoverPresentationController?.sourceView = present.view
        alertController.popoverPresentationController?.sourceRect = CGRect(x: 0.0, y: 0.0, width: 20.0, height: 20.0)

        // アクションシート表示
        present.present(alertController, animated: true, completion: nil)
    }

    // MARK: 画像がツイートに含まれているか？
    class func isContainMedia(_ tweet: JSON) -> Bool {
        if tweet["extended_entities"].object != nil {
            return true
        }
        return false
    }
}
