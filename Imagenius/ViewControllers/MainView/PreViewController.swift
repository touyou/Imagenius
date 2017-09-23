//
//  PreViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/03/07.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit

final class PreViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var preImageView: UIImageView!
    @IBOutlet weak var preScrollView: UIScrollView!
    var imageData: Data!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.preScrollView.delegate = self
        self.preScrollView.minimumZoomScale = 1
        self.preScrollView.maximumZoomScale = 4
        self.preScrollView.isScrollEnabled = true

        let doubleTapGesture: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action:#selector(self.doubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        self.preImageView.isUserInteractionEnabled = true
        self.preImageView.addGestureRecognizer(doubleTapGesture)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.preImageView.image = UIImage(data: imageData)
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return preImageView
    }

    // MARK: ダブルタップ
    @objc func doubleTap(_ gesture: UITapGestureRecognizer) {
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
