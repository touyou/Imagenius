//
//  AVPlayerView.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/03/26.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import AVFoundation

final class AVPlayerView: UIView {

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    override class func layerClass() -> AnyClass {
        return AVPlayerLayer.self
    }
}
