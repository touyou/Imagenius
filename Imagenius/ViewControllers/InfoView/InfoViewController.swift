//
//  InfoViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/03/28.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit

final class InfoViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    var image: NSData!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        imageView.image = UIImage(data: image)
    }
}
