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
    }
    enum Saveword {
        static let image = "tweet_image"
        static let twitter = "twitter_account"
        static let search = "search_word"
    }
}
