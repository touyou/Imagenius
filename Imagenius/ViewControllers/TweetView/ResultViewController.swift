//
//  ResultViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/02/18.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit

class ResultViewController: UIViewController, UIScrollViewDelegate {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var preScrollView: UIScrollView!
    
    var image: UIImage?
    var data: NSData?
    var delegate: TweetViewControllerDelegate!
    
    let saveData:NSUserDefaults = NSUserDefaults.standardUserDefaults()
    
    // UIViewControllerの設定----------------------------------------------------
    override func viewDidLoad() {
        super.viewDidLoad()
        if image == nil {
            imageView.image = UIImage(named: "empty.png")
        } else {
            imageView.image = self.image
        }
        self.preScrollView.delegate = self
        self.preScrollView.minimumZoomScale = 1
        self.preScrollView.maximumZoomScale = 4
        
        let doubleTapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(self.doubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        self.imageView.userInteractionEnabled = true
        self.imageView.addGestureRecognizer(doubleTapGesture)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    
    // ボタン関連-----------------------------------------------------------------
    // OKボタンのとき
    @IBAction func pushOK() {
        dismissViewControllerAnimated(true, completion: {
            // GIFかどうかの判断はSDWebImageのコードを参考に
            self.delegate.changeImage(self.image!, data: self.data!, isGIF: self.data!.isGIF())
        })
    }
    // Cancelボタンのとき
    @IBAction func pushCancel() {
        self.navigationController?.popToRootViewControllerAnimated(true)
    }
    // Shareボタン
    @IBAction func shareImage() {
        let activityItems: [AnyObject]!
        activityItems = [image!]
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        let excludedActivityTypes = [UIActivityTypePostToTwitter, UIActivityTypePostToWeibo, UIActivityTypePostToTencentWeibo]
        activityVC.excludedActivityTypes = excludedActivityTypes
        // iPad用
        activityVC.popoverPresentationController?.sourceView = self.view
        activityVC.popoverPresentationController?.sourceRect = CGRectMake(0.0, 0.0, 20.0, 20.0)
        self.presentViewController(activityVC, animated: true, completion: nil)
    }
    
    // 画像を拡大縮小できるためのいろいろ
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    // ダブルタップ
    func doubleTap(gesture: UITapGestureRecognizer) -> Void {
        if (self.preScrollView.zoomScale < self.preScrollView.maximumZoomScale) {
            let newScale:CGFloat = self.preScrollView.zoomScale * 3
            let zoomRect:CGRect = self.zoomRectForScale(newScale, center: gesture.locationInView(gesture.view))
            self.preScrollView.zoomToRect(zoomRect, animated: true)
        } else {
            self.preScrollView.setZoomScale(1.0, animated: true)
        }
    }
    // 領域
    func zoomRectForScale(scale:CGFloat, center: CGPoint) -> CGRect{
        var zoomRect: CGRect = CGRect()
        zoomRect.size.height = self.preScrollView.bounds.size.height / scale
        zoomRect.size.width = self.preScrollView.bounds.size.width / scale
        
        zoomRect.origin.x = center.x - zoomRect.size.width / 2.0
        zoomRect.origin.y = center.y - zoomRect.size.height / 2.0
        
        return zoomRect
    }
}

extension NSData {
    func isGIF() -> Bool {
        let bytes = UnsafePointer<Int8>(self.bytes)
        return self.length >= 6 && (strncmp(bytes, "GIF87a", 6) == 0 || strncmp(bytes, "GIF89a", 6) == 0)
    }
}