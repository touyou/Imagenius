//
//  UIAlertController.swift
//  MusicAppClone
//
//  Created by 藤井陽介 on 2017/09/16.
//  Copyright © 2017年 藤井陽介. All rights reserved.
//

import UIKit

extension UIAlertController {
    
    func addAction(title: String, style: UIAlertAction.Style = .default, handler: ((UIAlertAction) -> Void)? = nil) -> Self {
        
        let action = UIAlertAction(title: title, style: style, handler: handler)
        addAction(action)
        return self
    }
    
    func addActionWithTextFields(title: String, style: UIAlertAction.Style = .default, handler: ((UIAlertAction, [UITextField]) -> Void)? = nil) -> Self {
        
        let action = UIAlertAction(title: title, style: style) { [weak self] action in
            
            handler?(action, self?.textFields ?? [])
        }
        addAction(action)
        return self
    }
    
    func show() {
        
        // iPad用
        self.popoverPresentationController?.sourceView = UIApplication.shared.topPresentedViewController?.view
        self.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: 20, height: 20)
        
        UIApplication.shared.topPresentedViewController?.present(self, animated: true, completion: nil)
    }
}
