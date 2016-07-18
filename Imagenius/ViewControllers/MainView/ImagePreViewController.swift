//
//  ImagePreViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/03/07.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit

final class ImagePreViewController: UIPageViewController {

    @IBOutlet weak var pageControl: UIPageControl!
    var pageData: NSMutableArray!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self

        let startViewController: PreViewController = self.viewControllerAtIndex(0, storyboard: self.storyboard!)!
        let viewControllers = [startViewController]
        self.setViewControllers(viewControllers, direction: .Forward, animated: false, completion: {done in })

        self.dataSource = self
        self.view.gestureRecognizers = self.gestureRecognizers

        pageControl.numberOfPages = pageData.count
        self.view.backgroundColor = UIColor.whiteColor()
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }

    // MARK: 画像をシェアする
    @IBAction func shareImage() {
        let image = UIImage(data: self.pageData[pageControl.currentPage] as? NSData ?? NSData())
        let activityItems: [AnyObject]!
        activityItems = [image!]
        let activityVC = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        let excludedActivityTypes = [UIActivityTypePostToWeibo, UIActivityTypePostToTencentWeibo]
        activityVC.excludedActivityTypes = excludedActivityTypes
        // iPad用
        activityVC.popoverPresentationController?.sourceView = self.view
        activityVC.popoverPresentationController?.sourceRect = CGRect(x: 0.0, y: 0.0, width: 20.0, height: 20.0)
        self.presentViewController(activityVC, animated: true, completion: nil)
    }

    // MARK: - Utility
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
        let preViewController = storyboard.instantiateViewControllerWithIdentifier("PreViewController") as? PreViewController ?? PreViewController()
        preViewController.imageData = self.pageData[index] as? NSData ?? NSData()
        return preViewController
    }
}

// MARK: - pageViewController関連
extension ImagePreViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        var index = self.indexOfViewController(viewController as? PreViewController ?? PreViewController())
        if index == 0 || index == NSNotFound {
            return nil
        }
        index -= 1
        return self.viewControllerAtIndex(index, storyboard: viewController.storyboard!)
    }
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        var index = self.indexOfViewController(viewController as? PreViewController ?? PreViewController())
        if index == self.pageData.count - 1 || index == NSNotFound {
            return nil
        }
        index += 1
        return self.viewControllerAtIndex(index, storyboard: viewController.storyboard!)
    }
    // MARK: 向きはPortrait限定なので常に表示されるページは一個
    func pageViewController(pageViewController: UIPageViewController, spineLocationForInterfaceOrientation orientation: UIInterfaceOrientation) -> UIPageViewControllerSpineLocation {
        let currentViewController = self.viewControllers![0]
        let viewControllers = [currentViewController]
        self.setViewControllers(viewControllers, direction: .Forward, animated: true, completion: {done in })
        self.doubleSided = false
        return .Min
    }
    // MARK: 現在地
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let viewController = pageViewController.viewControllers?.first as? PreViewController {
            self.pageControl.currentPage = indexOfViewController(viewController)
        }
    }
}
