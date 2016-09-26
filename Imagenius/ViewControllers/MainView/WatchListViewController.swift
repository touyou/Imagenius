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
                self.maxId = self.tweetArray[self.tweetArray.count - 1].idStr
            }
            self.viewModel.tweetArray = self.tweetArray
            self.timelineTableView.reloadData()
        }
        if !moreflag {
            self.swifter.listTweets(for: .id(selectedListID), sinceID: nil, maxID: nil, count: 41, includeEntities: true, includeRTs: true, success: successHandler, failure: failureHandler)
        } else {
            self.swifter.listTweets(for: .id(selectedListID), sinceID: nil, maxID: self.maxId, count: 41, includeEntities: true, includeRTs: true, success: successHandler, failure: failureHandler)
        }

    }
}
