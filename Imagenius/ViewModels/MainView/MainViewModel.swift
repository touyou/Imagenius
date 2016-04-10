//
//  MainViewModel.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/04/06.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SwifteriOS
import AVKit
import AVFoundation

class MainViewModel: NSObject, UITableViewDataSource {
    
    final var tweetArray = [JSONValue]()
    final private var viewController: MainViewController!
    final private let model = MainModel()
    var audioSession: AVAudioSession!
    
    override init() {
        super.init()
        audioSession = AVAudioSession.sharedInstance()
    }
    
    func setViewController(vc: MainViewController) {
        viewController = vc
    }
    func setTweetArray(array: [JSONValue]) {
        tweetArray = array
    }
    
    // MARK: - TableView
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tweetArray.count
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if tweetArray.count <= indexPath.row || indexPath.row < 0 {
            return UITableViewCell()
        }
        let tweet = tweetArray[indexPath.row]
        let favorited = tweet["favorited"].bool!
        let retweeted = tweet["retweeted"].bool!
        let f_num = tweet["favorite_count"].integer!
        let r_num = tweet["retweet_count"].integer!
        
        let cell: TweetVarViewCell = tableView.dequeueReusableCellWithIdentifier("cell") as! TweetVarViewCell
        cell.tweetLabel.delegate = viewController
        cell.setOutlet(tweet, tweetHeight: viewController.view.bounds.width / 1.8)
        
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tapped(_:)))
        cell.tweetImgView.addGestureRecognizer(tapGesture)
        cell.tweetImgView.tag = indexPath.row
        
        if (self.tweetArray.count - 1) == indexPath.row && viewController.maxId != "" {
            viewController.loadMore()
        }
        cell.rightUtilityButtons = viewController.rightButtons(favorited, retweeted: retweeted, f_num: f_num, r_num: r_num) as [AnyObject]
        cell.leftUtilityButtons = viewController.leftButtons() as [AnyObject]
        cell.delegate = viewController
        cell.layoutIfNeeded()
        return cell
    }
    
    // imageViewがタップされたら画像のURLを開く
    func tapped(sender: UITapGestureRecognizer) {
        if let theView = sender.view {
            let rowNum = theView.tag
            if tweetArray[rowNum]["extended_entities"]["media"][0]["type"].string == nil {}
            switch tweetArray[rowNum]["extended_entities"]["media"][0]["type"].string! {
            case "photo":
                let tempData = NSMutableArray()
                for data in tweetArray[rowNum]["extended_entities"]["media"].array! {
                    tempData.addObject(NSData(contentsOfURL: NSURL(string: data["media_url"].string!)!)!)
                }
                viewController.imageData = tempData
                viewController.performSegueWithIdentifier("toPreView", sender: nil)
            case "video":
                if let videoArray = tweetArray[rowNum]["extended_entities"]["media"][0]["video_info"]["variants"].array {
                    let alertController = UIAlertController(title: "ビットレートを選択", message: "再生したい動画のビットレートを選択してください。", preferredStyle: .ActionSheet)
                    for i in 0 ..< videoArray.count {
                        let videoInfo = videoArray[i]
                        if videoInfo["bitrate"].integer != nil {
                            alertController.addAction(UIAlertAction(title: "\(videoInfo["bitrate"].integer! / 1000)kbps", style: .Default, handler: { (action) -> Void in
                                self.viewController.avPlayerViewController = AVPlayerViewController()
                                self.viewController.avPlayerViewController.player = AVPlayer(URL: NSURL(string: videoInfo["url"].string!)!)
                                self.viewController.presentViewController(self.viewController.avPlayerViewController, animated: true, completion: {
                                    try! self.audioSession.setCategory(AVAudioSessionCategorySoloAmbient)
                                    self.viewController.avPlayerViewController.player?.play()
                                })
                            }))
                        }
                    }
                    
                    // キャンセルボタンは何もせずにアクションシートを閉じる
                    let CanceledAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
                    alertController.addAction(CanceledAction)
                    // iPad用
                    alertController.popoverPresentationController?.sourceView = viewController.view
                    alertController.popoverPresentationController?.sourceRect = theView.frame
                    // アクションシート表示
                    viewController.presentViewController(alertController, animated: true, completion: nil)
                }
            case "animated_gif":
                // print(tweetArray[rowNum]["extended_entities"])
                if let videoURL = tweetArray[rowNum]["extended_entities"]["media"][0]["video_info"]["variants"][0]["url"].string {
                    viewController.gifURL = NSURL(string: videoURL)
                    viewController.performSegueWithIdentifier("toGifView", sender: nil)
                }
            default:
                if let tweetURL = tweetArray[rowNum]["extended_entities"]["media"][0]["url"].string {
                    Utility.openWebView(NSURL(string: tweetURL)!)
                    viewController.performSegueWithIdentifier("openWebView", sender: nil)
                }
            }
        }
    }
}
