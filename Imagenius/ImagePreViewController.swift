//
//  ImagePreViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/03/07.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit

class ImagePreViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    var pageData: NSMutableArray!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        
        let startViewController: PreViewController = self.viewControllerAtIndex(0, storyboard: self.storyboard!)!
        let viewControllers = [startViewController]
        self.setViewControllers(viewControllers, direction: .Forward, animated: false, completion: {done in })
        
        self.dataSource = self
        self.view.gestureRecognizers = self.gestureRecognizers
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    // pageViewController関連----------------------------------------------------
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        var index = self.indexOfViewController(viewController as! PreViewController)
        if index == 0 || index == NSNotFound {
            return nil
        }
        index -= 1
        return self.viewControllerAtIndex(index, storyboard: viewController.storyboard!)
    }
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        var index = self.indexOfViewController(viewController as! PreViewController)
        if index == self.pageData.count - 1 || index == NSNotFound {
            return nil
        }
        index += 1
        return self.viewControllerAtIndex(index, storyboard: viewController.storyboard!)
    }
    // 向きはPortrait限定なので常に表示されるページは一個
    func pageViewController(pageViewController: UIPageViewController, spineLocationForInterfaceOrientation orientation: UIInterfaceOrientation) -> UIPageViewControllerSpineLocation {
        let currentViewController = self.viewControllers![0]
        let viewControllers = [currentViewController]
        self.setViewControllers(viewControllers, direction: .Forward, animated: true, completion: {done in })
        self.doubleSided = false
        return .Min
    }
    
    // Utility------------------------------------------------------------------
    func indexOfViewController(viewController: PreViewController) -> Int {
        if let dataObject: AnyObject = viewController.imageData {
            return self.pageData.indexOfObject(dataObject)
        } else {
            return NSNotFound
        }
    }
    func viewControllerAtIndex(index: Int, storyboard: UIStoryboard) -> PreViewController? {
        if self.pageData.count == 0 || index >= self.pageData.count {
            return nil
        }
        let preViewController = storyboard.instantiateViewControllerWithIdentifier("PreViewController") as! PreViewController
        preViewController.imageData = self.pageData[index] as! NSData
        return preViewController
    }
}
