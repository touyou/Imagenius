//
//  ListAllViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/09/26.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit
import DZNEmptyDataSet
import Accounts
import SwifteriOS

final class ListAllViewController: UIViewController {
    @IBOutlet weak var listTableView: UITableView! {
        didSet {
            listTableView.estimatedRowHeight = 200
            listTableView.rowHeight = UITableViewAutomaticDimension
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
        refreshControl.addTarget(self, action: #selector(ListAllViewController.loadList), for: UIControlEvents.valueChanged)
        return refreshControl
    }()
    
    var listList = [String]()
    var listIDs = [String]()
    var selectedListID: String!
    var selectedListTitle: String!
    var selectedUser: String!
    var swifter: Swifter!
    var account: ACAccount?
    var accounts = [ACAccount]()
    var reloadingFlag: Bool = false
    
    let accountStore = ACAccountStore()
    let saveData: UserDefaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // 引っ張ってロードするやつ
        listTableView.addSubview(refreshControl)
        
        saveData.addObserver(self, forKeyPath: Settings.Saveword.twitter, options: [NSKeyValueObservingOptions.new, NSKeyValueObservingOptions.old], context: nil)
        
        if saveData.object(forKey: Settings.Saveword.twitter) == nil {
            performSegue(withIdentifier: "showInfo", sender: nil)
        } else {
            let accountType = accountStore.accountType(withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter)
            accountStore.requestAccessToAccounts(with: accountType, options: nil) { granted, _ in
                if granted {
                    self.accounts = self.accountStore.accounts(with: accountType) as? [ACAccount] ?? []
                    if self.accounts.count != 0 {
                        self.account = self.accounts[self.saveData.object(forKey: Settings.Saveword.twitter) as? Int ?? 0]
                        self.swifter = Swifter(account: self.account!)
                        self.loadList()
                    }
                }
            }
        }
    }

    // MARK: アカウントが切り替わった時点でページをリロードしている
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        let accountType = accountStore.accountType(withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter)
        accountStore.requestAccessToAccounts(with: accountType, options: nil) { granted, _ in
            if granted {
                self.accounts = self.accountStore.accounts(with: accountType) as? [ACAccount] ?? []
                if self.accounts.count != 0 {
                    self.account = self.accounts[self.saveData.object(forKey: Settings.Saveword.twitter) as? Int ?? 0]
                    self.swifter = Swifter(account: self.account!)
                    if !self.reloadingFlag {
                        self.loadList()
                        self.reloadingFlag = true
                    } else {
                        self.reloadingFlag = false
                    }
                }
            }
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
        selectedUser = self.account?.username!
        performSegue(withIdentifier: "toUserView", sender: nil)
    }
    
    // MARK: - Utility
    func loadList() {
        if swifter != nil {
            let failureHandler: ((Error) -> Void) = { error in
                Utility.simpleAlert("Error: リストのロードに失敗しました。インターネット環境を確認してください。", presentView: self)
                self.listList = []
                self.listIDs = []
            }
            let successHandler: ((JSON) -> Void) = { statuses in
                guard let modes = statuses.array else { return }
                self.listList = []
                self.listIDs = []
                for mode in modes {
                    self.listList.append(mode["name"].string!)
                    self.listIDs.append(mode["id_str"].string!)
                }
                self.listTableView.reloadData()
            }
            self.swifter.getSubscribedLists(for: .screenName(self.account?.username ?? ""), reverse: true, success: successHandler, failure: failureHandler)
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
        return NSAttributedString(string: text, attributes: [NSFontAttributeName: font])
    }
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
        return NSAttributedString(string: "リロードする")
    }
    func emptyDataSetDidTapButton(_ scrollView: UIScrollView!) {
        loadList()
    }
}
