//
//  TweetVarViewCell.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/03/04.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import SwifteriOS
import TTTAttributedLabel
import SWTableViewCell
import SDWebImage

final class TweetVarViewCell: SWTableViewCell {
    @IBOutlet weak var tweetLabel: TTTAttributedLabel!
    @IBOutlet weak var userIDLabel: UILabel!
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var userImgView: UIImageView!
    @IBOutlet weak var tweetImgView: UIImageView!
    @IBOutlet weak var tweetSubView: UIView!
    @IBOutlet weak var subViewHeight: NSLayoutConstraint!
    @IBOutlet weak var imageCountLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!

    // MARK: - TableViewCellが生成された時
    override func awakeFromNib() {
        super.awakeFromNib()
        // URL検知するように設定
        self.tweetLabel.enabledTextCheckingTypes = NSTextCheckingType.Link.rawValue
        self.tweetLabel.extendsLinkTouchArea = false
        // リンク
        self.tweetLabel.linkAttributes = [
            kCTForegroundColorAttributeName: Settings.Colors.twitterColor,
            NSUnderlineStyleAttributeName: NSNumber(long: NSUnderlineStyle.StyleNone.rawValue)
        ]
        subViewHeight.constant = 0
        self.tweetImgView.userInteractionEnabled = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    // MARK: - TTTAttributedLabel関連
    // MARK: mention link
    func highrightMentionsInLabel(label: TTTAttributedLabel) {
        let text: NSString = label.text!
        let mentionExpression = try? NSRegularExpression(pattern: "(?<=^|\\s)(@\\w+)", options: [])
        let matches = mentionExpression!.matchesInString(label.text!, options: [], range: NSMakeRange(0, text.length))
        for match in matches {
            let matchRange = match.rangeAtIndex(1)
            let mentionString = text.substringWithRange(matchRange)
            let user = mentionString.substringFromIndex(mentionString.startIndex.advancedBy(1))
            let linkURLString = NSString(format: "account:%@", user)
            label.addLinkToURL(NSURL(string: linkURLString as String), withRange: matchRange)
        }
    }
    // MARK: hashtag link
    func highrightHashtagsInLabel(label: TTTAttributedLabel) {
        let text: NSString = label.text!
        let mentionExpression = try? NSRegularExpression(pattern: "(?<=^|\\s)(#\\w+)", options: [])
        let matches = mentionExpression!.matchesInString(label.text!, options: [], range: NSMakeRange(0, text.length))
        for match in matches {
            let matchRange = match.rangeAtIndex(0)
            let hashtagString = text.substringWithRange(matchRange)
            let word = hashtagString.substringFromIndex(hashtagString.startIndex.advancedBy(1))
            let linkURLString = NSString(format: "https://twitter.com/hashtag/%@", word.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!)
            label.addLinkToURL(NSURL(string: linkURLString as String), withRange: matchRange)
        }
    }

    // MARK: - 要素の設定
    func setOutlet(tweet: Tweet, tweetHeight: CGFloat) {
        if tweet.isRetweet {
            // なにかいい案があれば
        }

        self.tweetLabel.text = Utility.convertSpecialCharacters(tweet.text ?? "")
        self.highrightHashtagsInLabel(tweetLabel)
        self.highrightMentionsInLabel(tweetLabel)

        self.userLabel.text = tweet.userName ?? ""
        self.userIDLabel.text = tweet.screenName ?? "@"
        let userImgURL: NSURL = tweet.userImage ?? NSURL()

        self.userImgView.sd_setImageWithURL(userImgURL, placeholderImage: UIImage(named: "user_empty"), options: SDWebImageOptions.RetryFailed)

        self.userImgView.layer.cornerRadius = self.userImgView.frame.size.width * 0.5
        self.userImgView.clipsToBounds = true
        self.userImgView.layer.borderColor = Settings.Colors.selectedColor.CGColor
        self.userImgView.layer.borderWidth = 0.19

        self.timeLabel.text = tweet.createdAt!

        // こっから下で画像の枚数とそれに応じたレイアウトを行う
        guard let tweetMedia = tweet.extendedEntities else {
            subViewHeight.constant = 0
            tweetSubView.hidden = true
            self.updateConstraintsIfNeeded()
            return
        }

        // 画像の枚数
        let imageCount = tweetMedia.count
        // 画像の高さを設定する
        subViewHeight.constant = tweetHeight
        // 角丸にする
        tweetSubView.hidden = false
        tweetSubView.layer.cornerRadius = tweetSubView.frame.width * 0.017
        tweetSubView.clipsToBounds = true
        // 周りに線を入れる
        tweetSubView.layer.borderColor = Settings.Colors.selectedColor.CGColor
        tweetSubView.layer.borderWidth = 0.19
        // 一枚目のURLからNSURLをつくる
        // とりあえず一枚目だけツイート画面でプレビューする
        let tweetImgURL: NSURL = tweet.tweetImages![0]
        // 画像を表示するモード(Storyboardで設定するのと同じ)
        self.tweetImgView.contentMode = .ScaleAspectFill
        // 画像を設定(SDWebImageを使っているので、使わない場合はUIImageにダウンロードすればいい)
        self.tweetImgView.sd_setImageWithURL(tweetImgURL, placeholderImage: nil, options: SDWebImageOptions.RetryFailed)

        switch tweet.entitiesType ?? "" {
        case "photo":
            imageCountLabel.text = "\(imageCount)枚の写真"
        case "video":
            imageCountLabel.text = "動画"
        case "animated_gif":
            imageCountLabel.text = "GIF"
        default:
            imageCountLabel.text = ""
        }
        self.updateConstraintsIfNeeded()
    }
}
