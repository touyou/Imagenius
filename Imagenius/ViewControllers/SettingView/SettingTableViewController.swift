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
    let saveData: NSUserDefaults = NSUserDefaults.standardUserDefaults()
    let labelTexts: [NSArray] = [["アカウントを切り替える", "アプリの使い方"], ["友達に教える", "App Storeで評価"], ["フィードバックを送信", "Twitterの利用規約を確認"]]

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.allowsMultipleSelection = false
        if saveData.objectForKey(Settings.Saveword.twitter) == nil {
            TwitterUtil.loginTwitter(self, success: { (ac) -> () in
                self.account = ac
                self.swifter = Swifter(account: self.account!)
            })
        } else {
            let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
            accountStore.requestAccessToAccountsWithType(accountType, options: nil) { granted, error in
                if granted {
                    self.accounts = self.accountStore.accountsWithAccountType(accountType) as? [ACAccount] ?? []
                    if self.accounts.count != 0 {
                        self.account = self.accounts[self.saveData.objectForKey(Settings.Saveword.twitter) as? Int ?? 0]
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
        self.bannerView.loadRequest(GADRequest())
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

    // MARK: - tableView関連
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return labelTexts.count
    }
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return labelTexts[section].count
    }
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("settingButton")! as UITableViewCell
        cell.textLabel!.text = labelTexts[indexPath.section][indexPath.row] as? String
        return cell
    }
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:// login処理
                TwitterUtil.loginTwitter(self, success: { [unowned self] (ac) -> () in
                    self.account = ac
                    self.swifter = Swifter(account: self.account!)
                    self.navigationController?.popViewControllerAnimated(true)
                })
            case 1:
                performSegueWithIdentifier("showInfo", sender: nil)
            default:
                break
            }
        case 1:
            switch indexPath.row {
            case 0:
                // 友達に教える
                Utility.shareSome(NSURL(string: "https://itunes.apple.com/us/app/imagenius/id1089595726?l=ja&ls=1&mt=8")!, text: "Imagenius", presentView: self)
            case 1:
                // App Store画面へ
                let itunesURL: String = "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=1089595726"
                let url = NSURL(string: itunesURL)
                UIApplication.sharedApplication().openURL(url!)
            default:
                break
            }
        case 2:
            switch indexPath.row {
            case 0:
                // メール送信
                if !MFMailComposeViewController.canSendMail() {
                    print("Email Send Failed")
                    break
                }
                let mailViewController = MFMailComposeViewController()
                let toRecipients = ["touyou.dev@gmail.com"]
                mailViewController.navigationBar.tintColor = UIColor.whiteColor()
                mailViewController.mailComposeDelegate = self
                mailViewController.setToRecipients(toRecipients)
                mailViewController.setMessageBody("", isHTML: false)
                self.presentViewController(mailViewController, animated: true, completion: nil)
            case 1:
                // twitter利用規約へ
                Utility.openWebView(NSURL(string: "https://twitter.com/tos")!)
                performSegueWithIdentifier("openWebView", sender: nil)
            default:
                break
            }
        default:
            break
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    // MARK: - mailView関連
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
