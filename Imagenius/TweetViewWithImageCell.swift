//
//  TweetViewWithImageCell.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/02/24.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import SwifteriOS
import TTTAttributedLabel

class TweetViewWithImageCell: UITableViewCell {

    @IBOutlet var tweetLabel: TTTAttributedLabel!
    @IBOutlet var userIDLabel: UILabel!
    @IBOutlet var userLabel: UILabel!
    @IBOutlet var userImgView: UIImageView!
    @IBOutlet var tweetImgView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    func setOutlet(tweet: JSONValue) {
        let userInfo = tweet["user"]
        
        self.tweetLabel.enabledTextCheckingTypes = NSTextCheckingType.Link.rawValue
        
        self.tweetLabel.text = tweet["text"].string
        self.userLabel.text = userInfo["name"].string
        let userID = userInfo["screen_name"].string!
        self.userIDLabel.text = "@\(userID)"
        let userImgPath:String = userInfo["profile_image_url_https"].string!
        let userImgURL:NSURL = NSURL(string: userImgPath)!
        let userImgPathData:NSData = NSData(contentsOfURL: userImgURL)!
        self.userImgView.image = UIImage(data: userImgPathData)
        let tweetImgPath:String = tweet["entities"]["media"]["media_url_https"].string!
        let tweetImgURL:NSURL = NSURL(string: tweetImgPath)!
        let tweetImgPathData:NSData = NSData(contentsOfURL: tweetImgURL)!
        self.tweetImgView.image = UIImage(data: tweetImgPathData)
    }
}
