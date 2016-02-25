//
//  ColorManager.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/02/22.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit

enum Settings {
    enum Colors {
        // static letにすると一度だけしか生成されない
        static let mainColor = UIColor()
        static let favColor = UIColor(red: 232/255, green: 28/255, blue: 79/255, alpha: 1.0)
        static let replyColor = UIColor(red: 84/255, green: 233/255, blue: 244/255, alpha: 1.0)
        static let retweetColor = UIColor(red: 25/255, green: 207/255, blue: 134/255, alpha: 1.0)
        static let selectedColor = UIColor(red: 170/255, green: 184/255, blue: 194/255, alpha: 1.0)
        static let deleteColor = UIColor(red: 1.0, green: 0, blue: 0, alpha: 1.0)
        static let twitterColor = UIColor(red: 85/255, green: 172/255, blue: 238/255, alpha:1.0)
        static let userColor = UIColor(red: 230/255, green: 151/255, blue: 24/255, alpha: 1.0)
    }
    enum Saveword {
        static let image = "tweet_image"
        static let twitter = "twitter_account"
        static let search = "search_word"
    }
}
