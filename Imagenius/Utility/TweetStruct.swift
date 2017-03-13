//
//  TweetStruct.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/06/13.
//  Copyright © 2016年 touyou. All rights reserved.
//

// ツイートを構造体で管理する

import Foundation
import SwifteriOS

struct Tweet {
    var screenName: String?
    var screenNameNoat: String?
    var userName: String?
    var userImage: URL?
    var userId: String?
    var userBackgroundImage: URL?

    var text: String?
    var createdAt: String?
    var tweetImages: [URL]?
    var entitiesType: String?
    var extendedEntities: [JSON]?

    var favorited: Bool?
    var retweeted: Bool?
    var favoriteCount: Int?
    var retweetCount: Int?

    var idStr: String?
    var userMentions: [JSON]?
    var urlStr: String?

    var isMyself: Bool = false
    var isRetweet: Bool = false

    init() {
    }

    init(tweet: JSON) {
        self.init(tweet: tweet, myself: "")
    }

    init(tweet: JSON, myself: String) {
        if let retweet = tweet["retweeted_status"].object {
            isRetweet = true
            setTweet(retweet)
        } else {
            setTweet(tweet.object!)
        }
        judgeAccount(myself)
    }

    internal mutating func setTweet(_ tweet: [String: JSON]) {
        let user = tweet["user"]!

        // ユーザー情報
        screenNameNoat = user["screen_name"].string
        screenName = "@\(screenNameNoat ?? "")"
        userName = user["name"].string
        userImage = URL(string: user["profile_image_url_https"].string!)
        userId = user["id_str"].string
        userBackgroundImage = URL(string: user["profile_background_image_url"].string ?? "")

        // ツイート情報
        text = tweet["text"]?.string
        createdAt = Date().offsetFrom(dateTimeFromTwitterDate(tweet["created_at"]!.string!))
        favorited = tweet["favorited"]?.bool
        favoriteCount = tweet["favorite_count"]?.integer
        retweeted = tweet["retweeted"]?.bool
        retweetCount = tweet["retweet_count"]?.integer
        idStr = tweet["id_str"]?.string
        userMentions = tweet["entities"]!["user_mentions"].array
        urlStr = "https://twitter.com/\(screenNameNoat!)/status/\(idStr!)"

        // 添付ファイル情報
        guard let tweetMedia = tweet["extended_entities"] else {
            return
        }
        tweetImages = []
        for path in tweetMedia["media"].array ?? [] {
            tweetImages?.append(URL(string: path["media_url"].string!)!)
        }
        entitiesType = tweetMedia["media"][0]["type"].string
        extendedEntities = tweetMedia["media"].array
    }

    internal mutating func judgeAccount(_ myself: String) {
        if let screen = screenName {
            if screen == "@\(myself)" {
                isMyself = true
            }
        }
    }
}
