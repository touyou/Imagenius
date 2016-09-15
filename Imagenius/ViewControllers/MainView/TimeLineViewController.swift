//
//  TimeLineViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/02/24.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import SwifteriOS
import Accounts

final class TimeLineViewController: MainViewController {
    @IBOutlet weak var modeBtn: UIBarButtonItem!
    var modeList: [String] = ["ホーム"]
    var listIDs = [String]()
    var selectedMode: Int = 0
    
    override func viewDidAppear(_ animated: Bool) {
        loadList()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let accountType = accountStore.accountType(withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter)
        accountStore.requestAccessToAccounts(with: accountType, options: nil) { granted, error in
            if granted {
                self.accounts = self.accountStore.accounts(with: accountType) as? [ACAccount] ?? []
                if self.accounts.count != 0 {
                    self.account = self.accounts[self.saveData.object(forKey: Settings.Saveword.twitter) as? Int ?? 0]
                    self.swifter = Swifter(account: self.account!)
                    self.myself = self.account?.username
                    if !self.reloadingFlag {
                        self.tweetArray = []
                        self.loadTweet()
                        self.loadList()
                        self.reloadingFlag = true
                    } else {
                        self.reloadingFlag = false
                    }
                }
            }
        }
    }
    
    override func loginDone() {
        loadList()
    }
    
    func loadList() {
        modeBtn.title = "ホーム"

        if swifter != nil {
            let failureHandler: ((Error) -> Void) = { error in
                Utility.simpleAlert("Error: リストのロードに失敗しました。インターネット環境を確認してください。", presentView: self)
            }
            let successHandler: ((JSON) -> Void) = { statuses in
                guard let modes = statuses.array else { return }
                self.modeList = ["ホーム"]
                self.listIDs = []
                self.selectedMode = 0
                for mode in modes {
                    self.modeList.append(mode["name"].string!)
                    self.listIDs.append(mode["id_str"].string!)
                }
            }
            self.swifter.getSubscribedLists(for: .screenName(self.account?.username ?? ""), reverse: true, success: successHandler, failure: failureHandler)
        }

    }
    
    override func load(_ moreflag: Bool) {
        let failureHandler: ((Error) -> Void) = { error in
            print(error)
            Utility.simpleAlert("Error: タイムラインのロードに失敗しました。インターネット環境を確認してください。", presentView: self)
        }
        let successHandler: ((JSON) -> Void) = { statuses in
            guard let tweets = statuses.array else { return }

            if tweets.count < 1 {
                self.maxId = ""
            } else if tweets.count == 1 {
                if self.tweetArray.count >= 1 && self.maxId == self.tweetArray[self.tweetArray.count - 1].idStr ?? "" {
                    return
                }
                self.tweetArray.append(Tweet(tweet: tweets[0], myself: self.myself))
                self.maxId = tweets[0]["id_str"].string
            } else {
                for i in 0 ..< tweets.count - 1 {
                    self.tweetArray.append(Tweet(tweet: tweets[i], myself: self.myself))
                }
                self.maxId = tweets[tweets.count - 1]["id_str"].string
            }
            self.viewModel.tweetArray = self.tweetArray
            self.timelineTableView.reloadData()
        }
        if modeBtn.title == "ホーム" {
            if !moreflag {
                self.swifter.getHomeTimeline(count: 41, includeEntities: true, success: successHandler, failure: failureHandler)
            } else {
                self.swifter.getHomeTimeline(count: 41, sinceID: nil, maxID: self.maxId, trimUser: nil, contributorDetails: nil, includeEntities: true, success: successHandler, failure: failureHandler)
            }
        } else {
            var count: Int = 0
            for mode in modeList {
                if mode == modeBtn.title {
                    selectedMode = count
                    break
                }
                count += 1
            }
            if !moreflag {
                self.swifter.listTweets(for: .id(listIDs[selectedMode - 1]), sinceID: nil, maxID: nil, count: 41, includeEntities: true, includeRTs: true, success: successHandler, failure: failureHandler)
            } else {
                self.swifter.listTweets(for: .id(listIDs[selectedMode - 1]), sinceID: nil, maxID: self.maxId, count: 41, includeEntities: true, includeRTs: true, success: successHandler, failure: failureHandler)
            }
        }
    }
    
    @IBAction func pushModeBtn() {
        let alertController = UIAlertController(title: "タイムライン切り替え", message: nil, preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        for mode in modeList {
            alertController.addAction(UIAlertAction(title: mode, style: .default, handler: {(action) -> Void in
                self.modeBtn.title = mode
                self.tweetArray = []
                self.loadTweet()
            }))
        }
        
        alertController.popoverPresentationController?.sourceView = self.view
        alertController.popoverPresentationController?.sourceRect = modeBtn.accessibilityFrame
        
        self.present(alertController, animated: true, completion: nil)
    }
}
