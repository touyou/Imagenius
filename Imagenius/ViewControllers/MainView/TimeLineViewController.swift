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
    
    override func viewDidAppear(animated: Bool) {
        loadList()
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
        accountStore.requestAccessToAccountsWithType(accountType, options: nil) { granted, error in
            if granted {
                self.accounts = self.accountStore.accountsWithAccountType(accountType) as? [ACAccount] ?? []
                if self.accounts.count != 0 {
                    self.account = self.accounts[self.saveData.objectForKey(Settings.Saveword.twitter) as? Int ?? 0]
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
            let failureHandler: ((NSError) -> Void) = { error in
                Utility.simpleAlert("Error: リストのロードに失敗しました。インターネット環境を確認してください。", presentView: self)
            }
            let successHandler: (([JSONValue]?) -> Void) = { statuses in
                guard let modes = statuses else { return }
                self.modeList = ["ホーム"]
                self.listIDs = []
                self.selectedMode = 0
                for mode in modes {
                    self.modeList.append(mode["name"].string!)
                    self.listIDs.append(mode["id_str"].string!)
                }
            }
            self.swifter.getListsSubscribedByUserWithScreenName(self.account?.username ?? "", reverse: true, success: successHandler, failure: failureHandler)
        }

    }
    
    override func load(moreflag: Bool) {
        let failureHandler: ((NSError) -> Void) = { error in
            Utility.simpleAlert("Error: タイムラインのロードに失敗しました。インターネット環境を確認してください。", presentView: self)
        }
        let successHandler: (([JSONValue]?) -> Void) = { statuses in
            guard let tweets = statuses else { return }

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
                self.swifter.getStatusesHomeTimelineWithCount(41, includeEntities: true, success: successHandler, failure: failureHandler)
            } else {
                self.swifter.getStatusesHomeTimelineWithCount(41, sinceID: nil, maxID: self.maxId, trimUser: nil, contributorDetails: nil, includeEntities: true, success: successHandler, failure: failureHandler)
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
                self.swifter.getListsStatusesWithListID(listIDs[selectedMode - 1], ownerScreenName: self.account?.username ?? "", sinceID: nil, maxID: nil, count: 41, includeEntities: true, includeRTs: true, success: successHandler, failure: failureHandler)
            } else {
                self.swifter.getListsStatusesWithListID(listIDs[selectedMode - 1], ownerScreenName: self.account?.username ?? "", sinceID: nil, maxID: self.maxId, count: 41, includeEntities: true, includeRTs: true, success: successHandler, failure: failureHandler)
            }
        }
    }
    
    @IBAction func pushModeBtn() {
        let alertController = UIAlertController(title: "タイムライン切り替え", message: nil, preferredStyle: .ActionSheet)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        for mode in modeList {
            alertController.addAction(UIAlertAction(title: mode, style: .Default, handler: {(action) -> Void in
                self.modeBtn.title = mode
                self.tweetArray = []
                self.loadTweet()
            }))
        }
        
        alertController.popoverPresentationController?.sourceView = self.view
        alertController.popoverPresentationController?.sourceRect = modeBtn.accessibilityFrame
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
}
