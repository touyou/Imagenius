//
//  RightShowSegue.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/06/18.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit

class RightShowSegue: UIStoryboardSegue {
    override func perform() {
        let source = self.sourceViewController as UIViewController!
        let destination = self.destinationViewController as UIViewController!
        
        // まずsubviewに表示する
        source.navigationController?.view.insertSubview(destination.view, aboveSubview: source.view)
        
        let windowCenter = source.view.center
        let windowWidth = source.view.bounds.width
        let barHeight = source.navigationController?.navigationBar.bounds.height

        destination.view.center = CGPoint(x: windowCenter.x - windowWidth, y: windowCenter.y + barHeight! + 10.0)
        
        // animationする
        // showの逆バージョンなので微妙にsourceの位置をずらしながら
        UIView.animateWithDuration(0.15, animations: {
                source.view.center = CGPoint(x: windowCenter.x -  windowWidth / 15.0, y: windowCenter.y)
                destination.view.center = CGPoint(x: windowCenter.x - windowWidth / 15.0 - windowWidth / 2, y: windowCenter.y + barHeight! + 10.0)
            }, completion: { completed in
                UIView.animateWithDuration(0.2, animations: {
                        destination.view.center = CGPoint(x: windowCenter.x, y: windowCenter.y + barHeight! + 10.0)
                    }, completion: {completed in
                        source.navigationController?.pushViewController(destination, animated: false)
                })
        })
    }
}
