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

class ReplyViewController: MainViewController {
    override func load(moreflag: Bool) {
        let failureHandler: ((NSError) -> Void) = { error in
            Utility.simpleAlert("Error: リプライ通知のロードに失敗しました。インターネット環境を確認してください。", presentView: self)
        }
        let successHandler: (([JSONValue]?) -> Void) = { statuses in
            guard let tweets = statuses else { return }
            
            if tweets.count < 1 {
                self.maxId = ""
            } else if tweets.count == 1 {
                if self.tweetArray.count >= 1 && self.maxId == self.tweetArray[self.tweetArray.count - 1]["id_str"].string {
                    return
                }
                self.tweetArray.append(tweets[0])
                self.maxId = tweets[0]["id_str"].string
            } else {
                for i in 0 ..< tweets.count - 1{
                    self.tweetArray.append(tweets[i])
                }
                self.maxId = tweets[tweets.count - 1]["id_str"].string
            }
            self.viewModel.tweetArray = self.tweetArray
            self.timelineTableView.reloadData()
        }
        if !moreflag {
            self.swifter.getStatusesMentionTimelineWithCount(41, includeEntities: true, success: successHandler, failure: failureHandler)
        } else {
            self.swifter.getStatusesMentionTimelineWithCount(41, sinceID: nil, maxID: self.maxId, trimUser: nil, contributorDetails: nil, includeEntities: true, success: successHandler, failure: failureHandler)
        }
    }
}
