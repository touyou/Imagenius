//
//  PreViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/03/07.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit

class PreViewController: UIViewController {

    @IBOutlet var preImageView: UIImageView!
    var imageData: NSData!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.preImageView.image = UIImage(data: imageData)
    }
}
