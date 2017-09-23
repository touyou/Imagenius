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

final class MainViewModel: NSObject {

    final var tweetArray = [Tweet]()
    final fileprivate var viewController: MainViewController!
    final fileprivate let model = MainModel()
    var audioSession: AVAudioSession!

    override init() {
        super.init()
        audioSession = AVAudioSession.sharedInstance()
    }

    func setViewController(_ viewController: MainViewController) {
        self.viewController = viewController
    }
    func setTweetArray(_ array: [Tweet]) {
        tweetArray = array
    }

    // imageViewがタップされたら画像のURLを開く
    @objc func tapped(_ sender: UITapGestureRecognizer) {
        if let theView = sender.view {
            let rowNum = theView.tag
            guard let type = tweetArray[rowNum].extendedEntities?.media.first?.type else {
                return
            }
            switch type {
            case "photo":
                let tempData = NSMutableArray()
                for data in (tweetArray[rowNum].extendedEntities?.tweetImages ?? []) {
                    tempData.add(try! Data(contentsOf: data as URL))
                }
                viewController.imageData = tempData
                viewController.performSegue(withIdentifier: "toPreView", sender: nil)
            case "video":
                if let videoArray = tweetArray[rowNum].extendedEntities?.media.first?.videoInfo.variants {
                    var alertController = UIAlertController(title: "ビットレートを選択", message: "再生したい動画のビットレートを選択してください。", preferredStyle: .actionSheet)
                    for i in 0 ..< videoArray.count {
                        let videoInfo = videoArray[i]
                        if videoInfo.bitrate != nil {
                            alertController = alertController.addAction(title: "\(videoInfo.bitrate! / 1000)kbps", style: .default, handler: { (_) -> Void in
                                self.viewController.avPlayerViewController = AVPlayerViewController()
                                self.viewController.avPlayerViewController.player = AVPlayer(url: videoInfo.url)
                                self.viewController.present(self.viewController.avPlayerViewController, animated: true, completion: {
                                    try! self.audioSession.setCategory(AVAudioSessionCategorySoloAmbient)
                                    self.viewController.avPlayerViewController.player?.play()
                                })
                            })
                        }
                    }

                    alertController.addAction(title: "Cancel", style: .cancel).show()
                }
            case "animated_gif":
                // print(tweetArray[rowNum]["extended_entities"])
                if let videoURL = tweetArray[rowNum].extendedEntities?.media.first?.videoInfo.variants.first?.url {
                    viewController.gifURL = videoURL
                    viewController.performSegue(withIdentifier: "toGifView", sender: nil)
                }
            default:
                if let tweetURL = tweetArray[rowNum].extendedEntities?.media.first?.url {
                    Utility.openWebView(tweetURL)
                    viewController.performSegue(withIdentifier: "openWebView", sender: nil)
                }
            }
        }
    }
}

// MARK: - TableView
extension MainViewModel: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tweetArray.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tweetArray.count <= indexPath.row || indexPath.row < 0 {
            return UITableViewCell()
        }
        let tweet = tweetArray[indexPath.row]

        let cell: TweetVarViewCell = tableView.dequeueReusableCell(withIdentifier: "cell") as? TweetVarViewCell ?? TweetVarViewCell()
        cell.tweetLabel.delegate = viewController
        cell.setOutlet(tweet, tweetHeight: viewController.view.bounds.width / 1.8)

        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.tapped(_:)))
        cell.tweetImgView.addGestureRecognizer(tapGesture)
        cell.tweetImgView.tag = indexPath.row

        if (self.tweetArray.count - 1) == indexPath.row && viewController.maxId != "" {
            viewController.loadMore()
        }
        cell.rightUtilityButtons = viewController.rightButtons(tweet) as [AnyObject]
        cell.leftUtilityButtons = viewController.leftButtons() as [AnyObject]
        cell.delegate = viewController
        cell.layoutIfNeeded()
        return cell
    }
}
