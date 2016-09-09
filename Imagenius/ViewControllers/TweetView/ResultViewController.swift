//
//  ResultViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/02/18.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit

final class ResultViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var preScrollView: UIScrollView!

    var image: UIImage?
    var data: Data?
    var delegate: TweetViewControllerDelegate!

    let saveData: UserDefaults = UserDefaults.standard

    // MARK: - UIViewControllerの設定
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
        self.imageView.isUserInteractionEnabled = true
        self.imageView.addGestureRecognizer(doubleTapGesture)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }


    // MARK: - ボタン関連
    // MARK: OKボタンのとき
    @IBAction func pushOK() {
        dismiss(animated: true, completion: {
            // GIFかどうかの判断はSDWebImageのコードを参考に
            self.delegate.changeImage(self.image!, data: self.data!, isGIF: self.data!.isGIF())
        })
    }
    // MARK: Cancelボタンのとき
    @IBAction func pushCancel() {
        self.navigationController?.popToRootViewController(animated: true)
    }
    // MARK: Shareボタン
    @IBAction func shareImage() {
        let activityItems: [AnyObject]!
        activityItems = [image!]
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        let excludedActivityTypes = [UIActivityType.postToTwitter, UIActivityType.postToWeibo, UIActivityType.postToTencentWeibo]
        activityVC.excludedActivityTypes = excludedActivityTypes
        // iPad用
        activityVC.popoverPresentationController?.sourceView = self.view
        activityVC.popoverPresentationController?.sourceRect = CGRect(x: 0.0, y: 0.0, width: 20.0, height: 20.0)
        self.present(activityVC, animated: true, completion: nil)
    }
    // MARK: お気に入りボタン
    @IBAction func favoriteImageBtn() {
        var message: String = "この画像をお気に入り登録しますか？"
        
        if self.data!.isGIF() {
            message = "GIFはお気に入り登録すると通常の画像に変換されます。よろしいですか？"
        }
        
        let alertController = UIAlertController(title: "お気に入り登録", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            let favoriteImage = FavoriteImage.create()
            favoriteImage.image = self.image
            favoriteImage.save()
            Utility.simpleAlert("登録しました。", presentView: self)
        }))
        present(alertController, animated: true, completion: nil)
    }
}

extension ResultViewController: UIScrollViewDelegate {
    // MARK: 画像を拡大縮小できるためのいろいろ
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    // MARK: ダブルタップ
    func doubleTap(_ gesture: UITapGestureRecognizer) -> Void {
        if self.preScrollView.zoomScale < self.preScrollView.maximumZoomScale {
            let newScale: CGFloat = self.preScrollView.zoomScale * 3
            let zoomRect: CGRect = self.zoomRectForScale(newScale, center: gesture.location(in: gesture.view))
            self.preScrollView.zoom(to: zoomRect, animated: true)
        } else {
            self.preScrollView.setZoomScale(1.0, animated: true)
        }
    }
    // MARK: 領域
    func zoomRectForScale(_ scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect: CGRect = CGRect()
        zoomRect.size.height = self.preScrollView.bounds.size.height / scale
        zoomRect.size.width = self.preScrollView.bounds.size.width / scale

        zoomRect.origin.x = center.x - zoomRect.size.width / 2.0
        zoomRect.origin.y = center.y - zoomRect.size.height / 2.0

        return zoomRect
    }
}

extension Data {
    func isGIF() -> Bool {
        let bytes = (self as NSData).bytes.bindMemory(to: Int8.self, capacity: self.count)
        return self.count >= 6 && (strncmp(bytes, "GIF87a", 6) == 0 || strncmp(bytes, "GIF89a", 6) == 0)
    }
}
