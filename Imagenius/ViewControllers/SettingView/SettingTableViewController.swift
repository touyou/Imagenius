//
//  SettingTableViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/03/14.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import SwifteriOS
import Accounts
import MessageUI
import GoogleMobileAds


final class SettingTableViewController: UITableViewController, MFMailComposeViewControllerDelegate {
    // Google Ads関連
    @IBOutlet weak var bannerView: GADBannerView!

    var swifter: Swifter!
    var account: ACAccount?
    var accounts = [ACAccount]()

    let accountStore = ACAccountStore()
    let saveData: UserDefaults = UserDefaults.standard
    let labelTexts: [NSArray] = [["アカウントを切り替える", "アプリの使い方", "お気に入り画像を確認する"], ["友達に教える", "App Storeで評価"], ["フィードバックを送信", "Twitterの利用規約を確認"]]

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.allowsMultipleSelection = false
        if saveData.object(forKey: Settings.Saveword.twitter) == nil {
            TwitterUtil.loginTwitter(self, success: { (ac) -> () in
                self.account = ac
                self.swifter = Swifter(account: self.account!)
            })
        } else {
            let accountType = accountStore.accountType(withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter)
            accountStore.requestAccessToAccounts(with: accountType, options: nil) { granted, error in
                if granted {
                    self.accounts = self.accountStore.accounts(with: accountType) as? [ACAccount] ?? []
                    if self.accounts.count != 0 {
                        self.account = self.accounts[self.saveData.object(forKey: Settings.Saveword.twitter) as? Int ?? 0]
                        self.swifter = Swifter(account: self.account!)
                    }
                }
            }
        }

        // Google Ads関連
        self.bannerView.adSize = kGADAdSizeSmartBannerPortrait
        // for test
        // self.bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        // for sale
        self.bannerView.adUnitID = "ca-app-pub-2853999389157478/5283774064"
        self.bannerView.rootViewController = self
        self.bannerView.load(GADRequest())
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    // MARK: - tableView関連
    override func numberOfSections(in tableView: UITableView) -> Int {
        return labelTexts.count
    }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return labelTexts[section].count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingButton")! as UITableViewCell
        cell.textLabel!.text = labelTexts[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row] as? String
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (indexPath as NSIndexPath).section {
        case 0:
            switch (indexPath as NSIndexPath).row {
            case 0:// login処理
                TwitterUtil.loginTwitter(self, success: { [unowned self] (ac) -> () in
                    self.account = ac
                    self.swifter = Swifter(account: self.account!)
                    self.navigationController?.popViewController(animated: true)
                })
            case 1:
                performSegue(withIdentifier: "showInfo", sender: nil)
            case 2:
                performSegue(withIdentifier: "openFavoriteImage", sender: nil)
            default:
                break
            }
        case 1:
            switch (indexPath as NSIndexPath).row {
            case 0:
                // 友達に教える
                Utility.shareSome(URL(string: "https://itunes.apple.com/us/app/imagenius/id1089595726?l=ja&ls=1&mt=8")!, text: "Imagenius", presentView: self)
            case 1:
                // App Store画面へ
                let itunesURL: String = "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=1089595726"
                let url = URL(string: itunesURL)
                UIApplication.shared.openURL(url!)
            default:
                break
            }
        case 2:
            switch (indexPath as NSIndexPath).row {
            case 0:
                // メール送信
                if !MFMailComposeViewController.canSendMail() {
                    print("Email Send Failed")
                    break
                }
                let mailViewController = MFMailComposeViewController()
                let toRecipients = ["touyou.dev@gmail.com"]
                mailViewController.navigationBar.tintColor = UIColor.white
                mailViewController.mailComposeDelegate = self
                mailViewController.setToRecipients(toRecipients)
                mailViewController.setMessageBody("", isHTML: false)
                self.present(mailViewController, animated: true, completion: nil)
            case 1:
                // twitter利用規約へ
                Utility.openWebView(URL(string: "https://twitter.com/tos")!)
                performSegue(withIdentifier: "openWebView", sender: nil)
            default:
                break
            }
        default:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    // MARK: - mailView関連
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        self.dismiss(animated: true, completion: nil)
    }
}
