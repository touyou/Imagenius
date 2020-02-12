//
//  WebViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/03/13.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import WebKit

final class WebViewController: UIViewController {
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var forwardButton: UIBarButtonItem!

    var reloadButton: UIBarButtonItem!
    var stopButton: UIBarButtonItem!
    var webView: WKWebView!
    var url: URL = URL(string: "https://twitter.com")!

    let saveData: UserDefaults = UserDefaults.standard

    override func viewDidLoad() {
        super.viewDidLoad()

        self.webView.addObserver(self, forKeyPath: "title", options: NSKeyValueObservingOptions.new, context: nil)
        self.webView.addObserver(self, forKeyPath: "loading", options: NSKeyValueObservingOptions.new, context: nil)
        self.webView.addObserver(self, forKeyPath: "canGoBack", options: NSKeyValueObservingOptions.new, context: nil)
        self.webView.addObserver(self, forKeyPath: "canGoForward", options: NSKeyValueObservingOptions.new, context: nil)

        if saveData.object(forKey: Settings.Saveword.url) != nil {
            url = URL(string: saveData.object(forKey: Settings.Saveword.url) as? String ?? "")!
        }

        let request = URLRequest(url: url)
        self.webView.load(request)
        reloadButton = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(WebViewController.didTapReloadButton(_:)))
        stopButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(WebViewController.didTapStopButton(_:)))
        self.navigationItem.rightBarButtonItem = reloadButton
    }
    // MARK: WKWebViewの設定
    override func loadView() {
        super.loadView()
        self.webView = WKWebView()
        self.webView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addConstraints([NSLayoutConstraint(item: self.webView!, attribute: NSLayoutConstraint.Attribute.width, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.width, multiplier: 1.0, constant: 0),
                                  NSLayoutConstraint(item: self.webView!, attribute: NSLayoutConstraint.Attribute.height, relatedBy: NSLayoutConstraint.Relation.equal, toItem: self.view, attribute: NSLayoutConstraint.Attribute.height, multiplier: 1.0, constant: 0)])
        self.webView.navigationDelegate = self
        self.webView.uiDelegate = self
        self.webView.allowsBackForwardNavigationGestures = true
        self.view.insertSubview(self.webView, at: 0)
    }
    deinit {
        self.webView.removeObserver(self, forKeyPath: "title")
        self.webView.removeObserver(self, forKeyPath: "loading")
        self.webView.removeObserver(self, forKeyPath: "canGoBack")
        self.webView.removeObserver(self, forKeyPath: "canGoForward")
    }
    // MARK: 状態に応じて
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "title" {
            self.title = self.webView.title
        } else if keyPath == "loading" {
            UIApplication.shared.isNetworkActivityIndicatorVisible = self.webView.isLoading
            if self.webView.isLoading {
                self.navigationItem.rightBarButtonItem = stopButton
            } else {
                self.navigationItem.rightBarButtonItem = reloadButton
            }
        } else if keyPath == "canGoBack" {
            self.backButton.isEnabled = self.webView.canGoBack
        } else if keyPath == "canGoForward" {
            self.forwardButton.isEnabled = self.webView.canGoForward
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }

    // MARK: - ボタン関連
    @IBAction func didTapBackButton() {
        self.webView.goBack()
    }
    @IBAction func didTapForwardButton() {
        self.webView.goForward()
    }
    @IBAction func safariButton() {
        let url = self.webView.url
        Utility.shareSome(url!, text: self.webView.title, presentView: self)
    }
    @objc internal func didTapReloadButton(_ sender: AnyObject) {
        self.webView.reload()
    }
    @objc internal func didTapStopButton(_ sender: AnyObject) {
        self.webView.stopLoading()
    }
}

// MARK: - WKWebView関連
extension WebViewController:  WKNavigationDelegate, WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if navigationAction.targetFrame == nil {
            webView.load(navigationAction.request)
        }
        return nil
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let currentUrl = navigationAction.request.url
        let urlString = currentUrl?.absoluteString
        if NSRegularExpression.rx("\\/\\/itunes\\.apple\\.com\\/").isMatch(urlString) {
            UIApplication.shared.openURL(currentUrl!)
            decisionHandler(WKNavigationActionPolicy.cancel)
            return
        } else if !NSRegularExpression.rx("^https?:\\/\\/.", ignoreCase: true).isMatch(urlString) {
            UIApplication.shared.openURL(currentUrl!)
            decisionHandler(WKNavigationActionPolicy.cancel)
            return
        }
        decisionHandler(WKNavigationActionPolicy.allow)
    }
}
