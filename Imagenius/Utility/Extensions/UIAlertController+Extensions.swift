//
//  UIAlertController+Extensions.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2017/09/19.
//  Copyright © 2017年 touyou. All rights reserved.
//

import UIKit

extension UIAlertController {
    
    func addAction(title: String?, style: UIAlertActionStyle, handler: ((UIAlertAction)->())? = nil) {
        
        let action = UIAlertAction(title: title, style: style, handler: handler)
        self.addAction(action)
    }
}
