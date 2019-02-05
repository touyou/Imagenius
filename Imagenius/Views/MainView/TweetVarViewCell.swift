//
//  TweetVarViewCell.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/03/04.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import TTTAttributedLabel
import SWTableViewCell
import SDWebImage

final class TweetVarViewCell: SWTableViewCell {
    @IBOutlet weak var tweetLabel: TTTAttributedLabel! {
        didSet {
            // URL検知するように設定
            tweetLabel.enabledTextCheckingTypes = NSTextCheckingResult.CheckingType.link.rawValue
            tweetLabel.extendsLinkTouchArea = false
            // リンク
            tweetLabel.linkAttributes = [
                kCTForegroundColorAttributeName as AnyHashable: Settings.Colors.twitterColor,
                NSAttributedStringKey.underlineStyle: NSNumber(value: NSUnderlineStyle.styleNone.rawValue as Int)
            ]
        }
    }
    @IBOutlet weak var userIDLabel: UILabel!
    @IBOutlet weak var userLabel: UILabel!
    @IBOutlet weak var userImgView: UIImageView!
    @IBOutlet weak var tweetImgView: UIImageView! {
        didSet {
            tweetImgView.isUserInteractionEnabled = true
        }
    }
    @IBOutlet weak var tweetSubView: UIView! {
        didSet {
            tweetSubView.isHidden = true
        }
    }
    @IBOutlet weak var subViewHeight: NSLayoutConstraint!
    @IBOutlet weak var imageCountLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var rtImageView: UIImageView!
    @IBOutlet weak var rtUserImageView: UIImageView!

    // MARK: - TableViewCellが生成された時
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    // MARK: - TTTAttributedLabel関連
    // MARK: mention link
    func highrightMentionsInLabel(_ label: TTTAttributedLabel) {
        let text: NSString = label.text as! NSString
        let mentionExpression = try? NSRegularExpression(pattern: "(?<=^|\\s)(@\\w+)", options: [])
        let matches = mentionExpression!.matches(in: label.text as! String, options: [], range: NSMakeRange(0, text.length))
        for match in matches {
            let matchRange = match.range(at: 1)
            let mentionString = text.substring(with: matchRange)
            let user = String(mentionString.suffix(from: mentionString.index(mentionString.startIndex, offsetBy: 1)))
            let linkURLString = NSString(format: "account:%@", user)
            label.addLink(to: URL(string: linkURLString as String), with: matchRange)
        }
    }
    // MARK: hashtag link
    func highrightHashtagsInLabel(_ label: TTTAttributedLabel) {
        let text: NSString = label.text as! NSString
        let mentionExpression = try? NSRegularExpression(pattern: "(?<=^|\\s)(#\\w+)", options: [])
        let matches = mentionExpression!.matches(in: label.text as! String, options: [], range: NSMakeRange(0, text.length))
        for match in matches {
            let matchRange = match.range(at: 0)
            let hashtagString = text.substring(with: matchRange)
            let word = hashtagString.suffix(from: hashtagString.index(hashtagString.startIndex, offsetBy: 1))
            let linkURLString = NSString(format: "https://twitter.com/hashtag/%@", word.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!)
            label.addLink(to: URL(string: linkURLString as String), with: matchRange)
        }
    }

    // MARK: - 要素の設定
    func setOutlet(_ tweet: Tweet, tweetHeight: CGFloat) {

        let original = tweet
        if let tweet = tweet.retweetedStatus {
            
            tweetLabel.text = Utility.convertSpecialCharacters(tweet.text)
            highrightHashtagsInLabel(tweetLabel)
            highrightMentionsInLabel(tweetLabel)
            
            userLabel.text = tweet.user.name
            userIDLabel.text = "@\(tweet.user.screenName)"
            let userImgURL: URL = tweet.user.profileImageUrl
            
            userImgView.sd_setImage(with: userImgURL, placeholderImage: UIImage(named: "user_empty"), options: SDWebImageOptions.retryFailed)
            
            userImgView.layer.cornerRadius = self.userImgView.frame.size.width * 0.5
            userImgView.clipsToBounds = true
            userImgView.layer.borderColor = Settings.Colors.selectedColor.cgColor
            userImgView.layer.borderWidth = 0.19
            userImgView.isHidden = false
            
            timeLabel.text = tweet.createdAt.offsetFrom()
            
            rtImageView.isHidden = true
            let rtUserImgURL = original.user.profileImageUrl
            rtUserImageView.sd_setImage(with: rtUserImgURL, placeholderImage: nil, options: SDWebImageOptions.retryFailed)
            rtUserImageView.layer.cornerRadius = self.rtUserImageView.frame.size.width * 0.5
            rtUserImageView.clipsToBounds = true
            
            // こっから下で画像の枚数とそれに応じたレイアウトを行う
            guard let tweetMedia = tweet.extendedEntities?.media else {
                subViewHeight.constant = 0
                tweetSubView.isHidden = true
                updateConstraintsIfNeeded()
                return
            }
            
            // 画像の枚数
            let imageCount = tweetMedia.count
            // 画像の高さを設定する
            subViewHeight.constant = tweetHeight
            
            // 角丸にする
            tweetSubView.isHidden = false
            tweetSubView.layer.cornerRadius = tweetSubView.frame.width * 0.017
            tweetSubView.clipsToBounds = true
            // 周りに線を入れる
            tweetSubView.layer.borderColor = Settings.Colors.selectedColor.cgColor
            tweetSubView.layer.borderWidth = 0.19
            // 一枚目のURLからNSURLをつくる
            // とりあえず一枚目だけツイート画面でプレビューする
            let tweetImgURL: URL = tweetMedia[0].mediaUrl
            // 画像を表示するモード(Storyboardで設定するのと同じ)
            tweetImgView.contentMode = .scaleAspectFill
            // 画像を設定(SDWebImageを使っているので、使わない場合はUIImageにダウンロードすればいい)
            tweetImgView.sd_setImage(with: tweetImgURL, placeholderImage: nil, options: SDWebImageOptions.retryFailed)
            
            switch tweet.extendedEntities?.type ?? "" {
            case "photo":
                imageCountLabel.text = "\(imageCount)枚の写真"
            case "video":
                imageCountLabel.text = "動画"
            case "animated_gif":
                imageCountLabel.text = "GIF"
            default:
                imageCountLabel.text = ""
            }
            updateConstraintsIfNeeded()
        } else {
            
            tweetLabel.text = Utility.convertSpecialCharacters(tweet.text)
            highrightHashtagsInLabel(tweetLabel)
            highrightMentionsInLabel(tweetLabel)
            
            userLabel.text = tweet.user.name
            userIDLabel.text = "@\(tweet.user.screenName)"
            let userImgURL: URL = tweet.user.profileImageUrl
            
            userImgView.sd_setImage(with: userImgURL, placeholderImage: UIImage(named: "user_empty"), options: SDWebImageOptions.retryFailed)
            
            userImgView.layer.cornerRadius = self.userImgView.frame.size.width * 0.5
            userImgView.clipsToBounds = true
            userImgView.layer.borderColor = Settings.Colors.selectedColor.cgColor
            userImgView.layer.borderWidth = 0.19
            userImgView.isHidden = false
            
            timeLabel.text = tweet.createdAt.offsetFrom()
            
            rtImageView.isHidden = true
            rtUserImageView.image = nil
            
            // こっから下で画像の枚数とそれに応じたレイアウトを行う
            guard let tweetMedia = tweet.extendedEntities?.media else {
                subViewHeight.constant = 0
                tweetSubView.isHidden = true
                updateConstraintsIfNeeded()
                return
            }
            
            // 画像の枚数
            let imageCount = tweetMedia.count
            // 画像の高さを設定する
            subViewHeight.constant = tweetHeight
            
            // 角丸にする
            tweetSubView.isHidden = false
            tweetSubView.layer.cornerRadius = tweetSubView.frame.width * 0.017
            tweetSubView.clipsToBounds = true
            // 周りに線を入れる
            tweetSubView.layer.borderColor = Settings.Colors.selectedColor.cgColor
            tweetSubView.layer.borderWidth = 0.19
            // 一枚目のURLからNSURLをつくる
            // とりあえず一枚目だけツイート画面でプレビューする
            let tweetImgURL: URL = tweetMedia[0].mediaUrl
            // 画像を表示するモード(Storyboardで設定するのと同じ)
            tweetImgView.contentMode = .scaleAspectFill
            // 画像を設定(SDWebImageを使っているので、使わない場合はUIImageにダウンロードすればいい)
            tweetImgView.sd_setImage(with: tweetImgURL, placeholderImage: nil, options: SDWebImageOptions.retryFailed)
            
            switch tweet.extendedEntities?.type ?? "" {
            case "photo":
                imageCountLabel.text = "\(imageCount)枚の写真"
            case "video":
                imageCountLabel.text = "動画"
            case "animated_gif":
                imageCountLabel.text = "GIF"
            default:
                imageCountLabel.text = ""
            }
            updateConstraintsIfNeeded()
        }
    }
}
