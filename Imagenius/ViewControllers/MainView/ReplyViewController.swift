//
//  ReplyViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/02/24.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import SwifteriOS
import Accounts

final class ReplyViewController: MainViewController {
    override func load(_ moreflag: Bool) {
        let failureHandler: ((Error) -> Void) = { error in
            Utility.simpleAlert("Error: リプライ通知のロードに失敗しました。インターネット環境を確認してください。", presentView: self)
        }
        let successHandler: ((JSON) -> Void) = { statuses in
            guard let tweets = statuses.array else { return }
            
            if tweets.count < 1 {
                self.maxId = ""
            } else if tweets.count == 1 {
                if self.tweetArray.count >= 1 && self.maxId == self.tweetArray[self.tweetArray.count - 1].idStr ?? "" {
                    return
                }
                if !self.isMute(tweets[0]["text"].string ?? "") {
                    self.tweetArray.append(Tweet(tweet: tweets[0], myself: self.myself))
                    self.maxId = tweets[0]["id_str"].string
                } else {
                    self.maxId = ""
                }
            } else {
                for i in 0 ..< tweets.count - 1 {
                    if !self.isMute(tweets[i]["text"].string ?? "") {
                        self.tweetArray.append(Tweet(tweet: tweets[i], myself: self.myself))
                    }
                }
                self.maxId = tweets[tweets.count - 1]["id_str"].string
            }
            self.viewModel.tweetArray = self.tweetArray
            self.timelineTableView.reloadData()
        }
        if !moreflag {
            self.swifter.getMentionsTimlineTweets(count: 41, includeEntities: true, success: successHandler, failure: failureHandler)
        } else {
            self.swifter.getMentionsTimlineTweets(count: 41, sinceID: nil, maxID: self.maxId, trimUser: nil, contributorDetails: nil, includeEntities: true, success: successHandler, failure: failureHandler)
        }
    }
}
