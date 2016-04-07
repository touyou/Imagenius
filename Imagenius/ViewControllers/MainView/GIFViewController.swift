//
//  GIFViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/03/26.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import AVFoundation

class GIFViewController: UIViewController {
    // TwitterのGIFはmp4ファイルなので動画の再生をループさせてGIFっぽく見せる
    @IBOutlet var contentView: UIView!
    
    var playerItem: AVPlayerItem!
    var videoPlayer: AVPlayer!
    var layer: AVPlayerLayer!
    var avAsset: AVAsset!
    var audioSession: AVAudioSession!
    var url: NSURL!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // 初期化
        avAsset = AVAsset(URL: url)
        playerItem = AVPlayerItem(asset: avAsset)
        videoPlayer = AVPlayer(playerItem: playerItem)
        audioSession = AVAudioSession.sharedInstance()
        try! audioSession.setCategory(AVAudioSessionCategoryAmbient)
        // ループにする
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GIFViewController.playerItemDidReachEnd(_:)), name: AVPlayerItemDidPlayToEndTimeNotification, object: self.videoPlayer.currentItem)
        
        videoPlayer.play()
        
        // tap時に再生と停止を切り替える
        let tapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(GIFViewController.tapped(_:)))
        self.contentView.addGestureRecognizer(tapGesture)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        let videoPlayerView = AVPlayerView(frame: self.contentView.bounds)
        layer = videoPlayerView.layer as! AVPlayerLayer
        layer.videoGravity = AVLayerVideoGravityResizeAspect
        layer.player = videoPlayer
        self.contentView.layer.addSublayer(layer)
        
        // 端末の向きがかわったらNotificationを呼ばす設定.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(GIFViewController.onOrientationChange(_:)), name: UIDeviceOrientationDidChangeNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        videoPlayer.pause()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    func playerItemDidReachEnd(notification: NSNotification) {
        self.videoPlayer.seekToTime(kCMTimeZero)
        self.videoPlayer.play()
    }
    
    func onOrientationChange(notification: NSNotification) {
        layer.removeFromSuperlayer()
        let videoPlayerView = AVPlayerView(frame: self.contentView.bounds)
        layer = videoPlayerView.layer as! AVPlayerLayer
        layer.videoGravity = AVLayerVideoGravityResizeAspect
        layer.player = videoPlayer
        self.contentView.layer.addSublayer(layer)
    }
    
    func tapped(sender: UITapGestureRecognizer) {
        if self.videoPlayer.rate != 0.0 {
            self.videoPlayer.pause()
        } else {
            self.videoPlayer.play()
        }
    }
}
