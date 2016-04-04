//
//  WebViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/03/13.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    @IBOutlet var backButton: UIBarButtonItem!
    @IBOutlet var forwardButton: UIBarButtonItem!
    
    var reloadButton: UIBarButtonItem!
    var stopButton: UIBarButtonItem!
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
        reloadButton = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: #selector(WebViewController.didTapReloadButton(_:)))
        stopButton = UIBarButtonItem(barButtonSystemItem: .Stop, target: self, action: #selector(WebViewController.didTapStopButton(_:)))
        self.navigationItem.rightBarButtonItem = reloadButton
    }
    // WKWebViewの設定
    override func loadView() {
        super.loadView()
        self.webView = WKWebView()
        self.webView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addConstraints([NSLayoutConstraint(item: self.webView, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Width, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: self.webView, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Height, multiplier: 1.0, constant: 0)])
        self.webView.navigationDelegate = self
        self.webView.UIDelegate = self
        self.webView.allowsBackForwardNavigationGestures = true
        self.view.insertSubview(self.webView, atIndex: 0)
    }
    deinit {
        self.webView.removeObserver(self, forKeyPath: "title")
        self.webView.removeObserver(self, forKeyPath: "loading")
        self.webView.removeObserver(self, forKeyPath: "canGoBack")
        self.webView.removeObserver(self, forKeyPath: "canGoForward")
    }
    // 状態に応じて
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "title" {
            self.title = self.webView.title
        } else if keyPath == "loading" {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = self.webView.loading
            if self.webView.loading {
                self.navigationItem.rightBarButtonItem = stopButton
            } else {
                self.navigationItem.rightBarButtonItem = reloadButton
            }
        } else if keyPath == "canGoBack" {
            self.backButton.enabled = self.webView.canGoBack
        } else if keyPath == "canGoForward" {
            self.forwardButton.enabled = self.webView.canGoForward
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    // ボタン関連-----------------------------------------------------------------
    @IBAction func didTapBackButton() {
        self.webView.goBack()
    }
    @IBAction func didTapForwardButton() {
        self.webView.goForward()
    }
    @IBAction func safariButton() {
        let url = self.webView.URL
        Utility.shareSome(url!, text: self.webView.title, presentView: self)
    }
    internal func didTapReloadButton(sender: AnyObject) {
        self.webView.reload()
    }
    internal func didTapStopButton(sender: AnyObject) {
        self.webView.stopLoading()
    }
    
    // WKWebView関連-------------------------------------------------------------
    func webView(webView: WKWebView, createWebViewWithConfiguration configuration: WKWebViewConfiguration, forNavigationAction navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.loadRequest(navigationAction.request)
        }
        return nil
    }
    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        let currentUrl = navigationAction.request.URL
        let urlString = currentUrl?.absoluteString
        if NSRegularExpression.rx("\\/\\/itunes\\.apple\\.com\\/").isMatch(urlString) {
            UIApplication.sharedApplication().openURL(currentUrl!)
            decisionHandler(WKNavigationActionPolicy.Cancel)
            return
        } else if !NSRegularExpression.rx("^https?:\\/\\/.", ignoreCase: true).isMatch(urlString) {
            UIApplication.sharedApplication().openURL(currentUrl!)
            decisionHandler(WKNavigationActionPolicy.Cancel)
            return
        }
        decisionHandler(WKNavigationActionPolicy.Allow)
    }
}
