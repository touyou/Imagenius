//
//  WebViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/03/13.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController, WKNavigationDelegate {
    @IBOutlet var backButton: UIBarButtonItem!
    @IBOutlet var forwardButton: UIBarButtonItem!
    @IBOutlet var reloadButton: UIBarButtonItem!
    @IBOutlet var stopButton: UIBarButtonItem!
    
    var webView: WKWebView!
    var url: NSURL = NSURL(string: "https://twitter.com")!
    
    let saveData:NSUserDefaults = NSUserDefaults.standardUserDefaults()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.webView.addObserver(self, forKeyPath: "title", options: NSKeyValueObservingOptions.New, context: nil)
        self.webView.addObserver(self, forKeyPath: "loading", options: NSKeyValueObservingOptions.New, context: nil)
        self.webView.addObserver(self, forKeyPath: "canGoBack", options: NSKeyValueObservingOptions.New, context: nil)
        self.webView.addObserver(self, forKeyPath: "canGoForward", options: NSKeyValueObservingOptions.New, context: nil)
        
        if saveData.objectForKey(Settings.Saveword.url) != nil {
            url = NSURL(string: saveData.objectForKey(Settings.Saveword.url) as! String)!
        }
        
        let request = NSURLRequest(URL: url)
        self.webView.loadRequest(request)
    }
    override func loadView() {
        super.loadView()
        self.webView = WKWebView()
        self.webView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addConstraints([NSLayoutConstraint(item: self.webView, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Width, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self.webView, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Height, multiplier: 1.0, constant: 0)])
        self.webView.navigationDelegate = self
        self.webView.allowsBackForwardNavigationGestures = true
        self.view.insertSubview(self.webView, atIndex: 0)
    }
    deinit {
        self.webView.removeObserver(self, forKeyPath: "title")
        self.webView.removeObserver(self, forKeyPath: "loading")
        self.webView.removeObserver(self, forKeyPath: "canGoBack")
        self.webView.removeObserver(self, forKeyPath: "canGoForward")
    }
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "title" {
            self.title = self.webView.title
        } else if keyPath == "loading" {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = self.webView.loading
            self.reloadButton.enabled = !self.webView.loading
            self.stopButton.enabled = self.webView.loading
        } else if keyPath == "canGoBack" {
            self.backButton.enabled = self.webView.canGoBack
        } else if keyPath == "canGoForward" {
            self.forwardButton.enabled = self.webView.canGoForward
        }
    }
    
    @IBAction func didTapBackButton() {
        self.webView.goBack()
    }
    @IBAction func didTapForwardButton() {
        self.webView.goForward()
    }
    @IBAction func didTapReloadbutton() {
        self.webView.reload()
    }
    @IBAction func didTapStopButton() {
        self.webView.stopLoading()
    }
    @IBAction func closeViewButton() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    @IBAction func safariButton() {
        let url = self.webView.URL
        UIApplication.sharedApplication().openURL(url!)
    }
}
