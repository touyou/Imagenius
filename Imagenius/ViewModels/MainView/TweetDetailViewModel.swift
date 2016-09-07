//
//  TweetDetailViewModel.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/04/08.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SwifteriOS
import AVKit
import AVFoundation

final class TweetDetailViewModel: NSObject {
    final var tweetArray = [[Tweet]]()
    final fileprivate var viewController: TweetDetailViewController!
    var audioSession: AVAudioSession!

    override init() {
        super.init()
        audioSession = AVAudioSession.sharedInstance()
    }

    func setViewController(_ viewController: TweetDetailViewController) {
        self.viewController = viewController
    }
    func setTweetArray(_ array: [[Tweet]]) {
        tweetArray = array
    }

    // MARK: imageViewがタップされたら画像のURLを開く
    func tapped(_ sender: UITapGestureRecognizer) {
        if let theView = sender.view {
            let rowNum: Int!
            let secNum: Int!
            if theView.tag >= 10000 {
                rowNum = theView.tag - 10000
                secNum = 1
            } else {
                rowNum = theView.tag
                secNum = 0
            }
            guard let type = tweetArray[secNum][rowNum].entitiesType else {
                return
            }
            switch type {
            case "photo":
                let tempData = NSMutableArray()
                for data in tweetArray[secNum][rowNum].tweetImages! {
                    tempData.add(try! Data(contentsOf: data as URL))
                }
                viewController.imageData = tempData
                viewController.performSegue(withIdentifier: "toPreView", sender: nil)
            case "video":
                if let videoArray = tweetArray[secNum][rowNum].extendedEntities![0]["video_info"]["variants"].array {
                    let alertController = UIAlertController(title: "ビットレートを選択", message: "再生したい動画のビットレートを選択してください。", preferredStyle: .actionSheet)
                    for i in 0 ..< videoArray.count {
                        let videoInfo = videoArray[i]
                        if videoInfo["bitrate"].integer != nil {
                            alertController.addAction(UIAlertAction(title: "\(videoInfo["bitrate"].integer! / 1000)kbps", style: .default, handler: { (action) -> Void in
                                self.viewController.avPlayerViewController = AVPlayerViewController()
                                self.viewController.avPlayerViewController.player = AVPlayer(url: URL(string: videoInfo["url"].string!)!)
                                self.viewController.present(self.viewController.avPlayerViewController, animated: true, completion: {
                                    try! self.audioSession.setCategory(AVAudioSessionCategorySoloAmbient)
                                    self.viewController.avPlayerViewController.player?.play()
                                })
                            }))
                        }
                    }

                    // キャンセルボタンは何もせずにアクションシートを閉じる
                    let CanceledAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                    alertController.addAction(CanceledAction)
                    // iPad用
                    alertController.popoverPresentationController?.sourceView = viewController.view
                    alertController.popoverPresentationController?.sourceRect = theView.frame
                    // アクションシート表示
                    viewController.present(alertController, animated: true, completion: nil)
                }
            case "animated_gif":
                if let videoURL = tweetArray[secNum][rowNum].extendedEntities![0]["video_info"]["variants"][0]["url"].string {
                    viewController.gifURL = URL(string: videoURL)
                    viewController.performSegue(withIdentifier: "toGifView", sender: nil)
                }
            default:
                if let tweetURL = tweetArray[secNum][rowNum].extendedEntities![0]["url"].string {
                    Utility.openWebView(URL(string: tweetURL)!)
                    viewController.performSegue(withIdentifier: "openWebView", sender: nil)
                }
            }
        }
    }
}

// MARK: - TableView
extension TweetDetailViewModel: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return tweetArray.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tweetArray[section].count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tweetArray[(indexPath as NSIndexPath).section].count <= (indexPath as NSIndexPath).row || (indexPath as NSIndexPath).row < 0 {
            return UITableViewCell()
        }

        let tweet = tweetArray[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row]

        let cell: TweetVarViewCell = tableView.dequeueReusableCell(withIdentifier: "cell") as? TweetVarViewCell ?? TweetVarViewCell()
        cell.tweetLabel.delegate = viewController
        cell.setOutlet(tweet, tweetHeight: viewController.view.bounds.width / 1.8)

        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tapped(_:)))
        cell.tweetImgView.addGestureRecognizer(tapGesture)
        cell.tweetImgView.tag = (indexPath as NSIndexPath).row + 10000 * (indexPath as NSIndexPath).section

        cell.rightUtilityButtons = viewController.rightButtons(tweet) as [AnyObject]
        cell.leftUtilityButtons = viewController.leftButtons() as [AnyObject]
        cell.delegate = viewController
        cell.layoutIfNeeded()
        return cell
    }
}
