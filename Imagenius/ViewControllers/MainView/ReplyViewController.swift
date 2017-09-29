//
//  ReplyViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/02/24.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import Accounts

final class ReplyViewController: MainViewController {
    
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
            
            twitterManager.loadMentionsTimelineTweet(count: 41, success: successHandler)
        } else {
            
            twitterManager.loadMentionsTimelineTweet(count: 41, maxID: self.maxId, success: successHandler, failure: failureHandler)
        }
    }
}
