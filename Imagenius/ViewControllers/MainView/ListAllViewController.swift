//
//  ListAllViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/09/26.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import DZNEmptyDataSet

final class ListAllViewController: UIViewController {
    @IBOutlet weak var listTableView: UITableView! {
        didSet {
            listTableView.estimatedRowHeight = 200
            listTableView.rowHeight = UITableView.automaticDimension
            listTableView.emptyDataSetDelegate = self
            listTableView.emptyDataSetSource = self
            listTableView.delegate = self
            listTableView.dataSource = self
            // cellを選択不可に
            listTableView.allowsMultipleSelection = false
            listTableView.tableFooterView = UIView()
        }
    }
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(ListAllViewController.loadList), for: UIControl.Event.valueChanged)
        return refreshControl
    }()
    
    var listList = [String]()
    var listIDs = [String]()
    var selectedListID: String!
    var selectedListTitle: String!
    var selectedUser: String!
    var reloadingFlag: Bool = false
    
    let saveData: UserDefaults = UserDefaults.standard
    let twitterManager = TwitterManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // 引っ張ってロードするやつ
        listTableView.addSubview(refreshControl)
        
        saveData.addObserver(self, forKeyPath: Settings.Saveword.twitter, options: [NSKeyValueObservingOptions.new, NSKeyValueObservingOptions.old], context: nil)
        
        if saveData.object(forKey: Settings.Saveword.twitter) == nil {
            performSegue(withIdentifier: "showInfo", sender: nil)
        } else {
            
            self.loadList()
        }
    }

    // MARK: アカウントが切り替わった時点でページをリロードしている
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if !self.reloadingFlag {
            self.loadList()
            self.reloadingFlag = true
        } else {
            self.reloadingFlag = false
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toUserView" {
            let userView = segue.destination as? UserViewController ?? UserViewController()
            userView.user = self.selectedUser
            self.selectedUser = nil
        } else if segue.identifier == "watchList" {
            let listView = segue.destination as? WatchListViewController ?? WatchListViewController()
            listView.selectedListTitle = self.selectedListTitle
            listView.selectedListID = self.selectedListID
        }
    }
    
    // MARK: ステータスバーを細く
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    // MARK: - ボタン関連
    @IBAction func pushTweet() {
        performSegue(withIdentifier: "toTweetView", sender: nil)
    }
    @IBAction func pushUser() {
        
        selectedUser = twitterManager.currentSession!.userName
        performSegue(withIdentifier: "toUserView", sender: nil)
    }
    
    // MARK: - Utility
    @objc func loadList() {
        
        if let current = twitterManager.currentSession {
            let failureHandler: ((Error?) -> Void) = { error in
                Utility.simpleAlert("Error: リストのロードに失敗しました。インターネット環境を確認してください。", presentView: self)
                self.listList = []
                self.listIDs = []
            }
            let successHandler: (([List]) -> Void) = { modes in

                self.listList = []
                self.listIDs = []
                for mode in modes {
                    self.listList.append(mode.name)
                    self.listIDs.append(mode.idStr)
                }
                self.listTableView.reloadData()
            }
            twitterManager.getSubscribedLists(for: current.userName, success: successHandler, failure: failureHandler)
        }
        
    }

}

// MARK: - TableViewの設定
extension ListAllViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return listList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "listCell")!
        
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.text = listList[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedListID = listIDs[indexPath.row]
        selectedListTitle = listList[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "watchList", sender: nil)
    }
}

// MARK: - DZNEmptyDataSetの設定
extension ListAllViewController: DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {
    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "リストがありません。"
        let font = UIFont.systemFont(ofSize: 20)
        return NSAttributedString(string: text, attributes: [NSAttributedString.Key.font: font])
    }
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControl.State) -> NSAttributedString! {
        return NSAttributedString(string: "リロードする")
    }
    func emptyDataSetDidTapButton(_ scrollView: UIScrollView!) {
        loadList()
    }
}
