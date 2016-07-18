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
    var screen_name: String?
    var screen_name_noat: String?
    var user_name: String?
    var user_image: NSURL?
    var user_id: String?
    
    var text: String?
    var created_at: String?
    var tweet_images: [NSURL]?
    var entities_type: String?
    var extended_entities: [JSONValue]?
    
    var favorited: Bool?
    var retweeted: Bool?
    var favorite_count: Int?
    var retweet_count: Int?
    
    var id_str: String?
    var user_mentions: [JSONValue]?
    
    var is_myself: Bool = false
    var is_retweet: Bool = false
    
    init() {
    }
    
    init(tweet: JSONValue) {
        self.init(tweet: tweet, myself: "")
    }
    
    init(tweet: JSONValue, myself: String) {
        if let retweet = tweet["retweeted_status"].object {
            is_retweet = true
            setTweet(retweet)
        } else {
            setTweet(tweet.object!)
        }
        judgeAccount(myself)
    }
    
    internal mutating func setTweet(tweet: Dictionary<String, JSONValue>) {
        let user = tweet["user"]!
        
        // ユーザー情報
        screen_name_noat = user["screen_name"].string
        screen_name = "@\(screen_name_noat ?? "")"
        user_name = user["name"].string
        user_image = NSURL(string: user["profile_image_url_https"].string!)
        user_id = user["id_str"].string
        
        // ツイート情報
        text = tweet["text"]?.string
        created_at = NSDate().offsetFrom(dateTimeFromTwitterDate(tweet["created_at"]!.string!))
        favorited = tweet["favorited"]?.bool
        favorite_count = tweet["favorite_count"]?.integer
        retweeted = tweet["retweeted"]?.bool
        retweet_count = tweet["retweet_count"]?.integer
        id_str = tweet["id_str"]?.string
        user_mentions = tweet["entities"]!["user_mentions"].array
        
        // 添付ファイル情報
        guard let tweetMedia = tweet["extended_entities"] else {
            return
        }
        tweet_images = []
        for path in tweetMedia["media"].array ?? [] {
            tweet_images?.append(NSURL(string: path["media_url"].string!)!)
        }
        entities_type = tweetMedia[0]["type"].string
        extended_entities = tweetMedia["media"].array
    }
    
    internal mutating func judgeAccount(myself: String) {
        if let screen = screen_name {
            if screen == "@\(myself)" {
                is_myself = true
            }
        }
    }
}