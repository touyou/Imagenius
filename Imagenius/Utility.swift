//
//  Utility.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/02/18.
//  Copyright © 2016年 touyou. All rights reserved.
//

import Foundation
import UIKit

class Utility {
    // 単純なアラートをつくる関数
    class func simpleAlert(titleString: String, presentView: UIViewController) {
        let alertController = UIAlertController(title: titleString, message: nil, preferredStyle: .Alert)
        let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alertController.addAction(defaultAction)
        presentView.presentViewController(alertController, animated: true, completion: nil)
    }
}