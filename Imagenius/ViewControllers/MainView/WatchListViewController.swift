//
//  WatchListViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/09/26.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import SwifteriOS
import Accounts

final class WatchListViewController: MainViewController {
    var selectedListTitle: String!
    var selectedListID: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = selectedListTitle
    }
    
    override func load(_ moreflag: Bool) {
        
        let failureHandler: ((Error?) -> Void) = { error in
            
            Utility.simpleAlert("Error: リプライ通知のロードに失敗しました。インターネット環境を確認してください。", presentView: self)
        }
        let successHandler: (([Tweet]) -> Void) = { tweets in
            
            if tweets.count < 1 {
                
                self.maxId = ""
            } else if tweets.count == 1 {
                
                if self.tweetArray.count >= 1 && self.maxId == self.tweetArray[self.tweetArray.count - 1].idStr {
                    return
                }
                if !self.isMute(tweets[0].text) {
                    
                    self.tweetArray.append(tweets[0])
                    self.maxId = tweets[0].idStr
                } else {
                    self.maxId = ""
                }
            } else {
                
                for i in 0 ..< tweets.count - 1 {
                    
                    if !self.isMute(tweets[i].text) {
                        
                        self.tweetArray.append(tweets[i])
                    }
                }
                self.maxId = tweets[tweets.count - 1].idStr
            }
            self.viewModel.tweetArray = self.tweetArray
            self.timelineTableView.reloadData()
        }
        if !moreflag {
            
            twitterManager.loadListTweet(for: selectedListID, count: 41, success: successHandler, failure: failureHandler)
        } else {
            
            twitterManager.loadListTweet(for: selectedListID, count: 41, maxID: maxId, success: successHandler, failure: failureHandler)
        }

    }
}
