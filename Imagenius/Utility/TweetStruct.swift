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
    var screen_name: String = ""
    var user_name: String = ""
    var user_image: NSURL!
    var text: String = ""
    var tweet_images: [NSURL] = []
    var is_myself: Bool = false
    
    init(tweet: JSONValue) {
        
    }
}