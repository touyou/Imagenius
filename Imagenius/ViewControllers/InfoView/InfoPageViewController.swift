//
//  InfoPageViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/03/28.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit

final class InfoPageViewController: UIPageViewController {

    var pageData: NSMutableArray!
    var currentIndex: Int!

    override func viewDidLoad() {
        super.viewDidLoad()
        pageData = NSMutableArray()
        currentIndex = 0
        pageData.add(UIImagePNGRepresentation(UIImage(named: "info_1")!)!)
        pageData.add(UIImagePNGRepresentation(UIImage(named: "info_2")!)!)
        pageData.add(UIImagePNGRepresentation(UIImage(named: "info_3")!)!)

        self.delegate = self

        let startViewController: InfoViewController = self.viewControllerAtIndex(0, storyboard: self.storyboard!)!
        let viewControllers = [startViewController]
        self.setViewControllers(viewControllers, direction: .forward, animated: false, completion: {_ in })

        self.dataSource = self
        self.view.gestureRecognizers = self.gestureRecognizers

        self.view.backgroundColor = Settings.Colors.mainColor
    }

    // MARK: - Utility
    func indexOfViewController(_ viewController: InfoViewController) -> Int {
        if let dataObject: AnyObject = viewController.image as AnyObject? {
            return self.pageData.index(of: dataObject)
        } else {
            return NSNotFound
        }
    }
    func viewControllerAtIndex(_ index: Int, storyboard: UIStoryboard) -> InfoViewController? {
        if self.pageData.count == 0 || index >= self.pageData.count {
            return nil
        }
        let infoViewController = storyboard.instantiateViewController(withIdentifier: "InfoViewController") as? InfoViewController ?? InfoViewController()
        infoViewController.image = self.pageData[index] as? Data ?? Data()
        return infoViewController
    }
}

// MARK: - pageViewController関連
extension InfoPageViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        var index = self.indexOfViewController(viewController as? InfoViewController ?? InfoViewController())
        if index == 0 || index == NSNotFound {
            return nil
        }
        index -= 1
        return self.viewControllerAtIndex(index, storyboard: viewController.storyboard!)
    }
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        var index = self.indexOfViewController(viewController as? InfoViewController ?? InfoViewController())
        if index == self.pageData.count - 1 || index == NSNotFound {
            return nil
        }
        index += 1
        return self.viewControllerAtIndex(index, storyboard: viewController.storyboard!)
    }
    // MARK: 向きはPortrait限定なので常に表示されるページは一個
    func pageViewController(_ pageViewController: UIPageViewController, spineLocationFor orientation: UIInterfaceOrientation) -> UIPageViewControllerSpineLocation {
        let currentViewController = self.viewControllers![0]
        let viewControllers = [currentViewController]
        self.setViewControllers(viewControllers, direction: .forward, animated: true, completion: {_ in })
        self.isDoubleSided = false
        return .min
    }
    // MARK: 現在地
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let viewController = pageViewController.viewControllers?.first as? InfoViewController {
            currentIndex = indexOfViewController(viewController)
        }
    }
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return currentIndex
    }
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return 3
    }
}
