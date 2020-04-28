//
//  SettingTableViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/03/14.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import MessageUI
import GoogleMobileAds

final class SettingTableViewController: UITableViewController, MFMailComposeViewControllerDelegate {
    // Google Ads関連
    @IBOutlet weak var bannerView: GADBannerView!

    let saveData: UserDefaults = UserDefaults.standard
    let twitterManager = TwitterManager.shared
    let labelTexts: [NSArray] = [["アカウントを切り替える", "アプリの使い方", "お気に入り画像を確認する", "引用リツイートの形式を変更する", "単語ミュート"], ["友達に教える", "App Storeで評価"], ["フィードバックを送信", "Twitterの利用規約を確認"]]

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.allowsMultipleSelection = false
        if saveData.object(forKey: Settings.Saveword.twitter) == nil {
            
            twitterManager.loginTwitter()
        }

        // Google Ads関連
        self.bannerView.adSize = kGADAdSizeSmartBannerPortrait
        
#if DEBUG
        self.bannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
#else
        self.bannerView.adUnitID = "ca-app-pub-2853999389157478/5283774064"
#endif
        
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
        cell.textLabel!.text = labelTexts[indexPath.section][indexPath.row] as? String
        return cell
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:// login処理
                twitterManager.switchAccount()
            case 1:
                performSegue(withIdentifier: "showInfo", sender: nil)
            case 2:
                performSegue(withIdentifier: "openFavoriteImage", sender: nil)
            case 3:
                performSegue(withIdentifier: "toChangeRTView", sender: nil)
            case 4:
                performSegue(withIdentifier: "muteSetting", sender: nil)
            default:
                break
            }
        case 1:
            switch indexPath.row {
            case 0:
                // 友達に教える
                Utility.shareSome(URL(string: "https://itunes.apple.com/us/app/imagenius/id1089595726?l=ja&ls=1&mt=8")!, text: "Imagenius", presentView: self)
            case 1:
                // App Store画面へ
                let itunesURL: String = "itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=1089595726"
                let url = URL(string: itunesURL)
                UIApplication.shared.open(url!)
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
