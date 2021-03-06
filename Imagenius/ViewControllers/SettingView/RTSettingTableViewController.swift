//
//  RTSettingTableViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/09/11.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit

class RTSettingTableViewController: UITableViewController {

    let labelText = ["文章そのまま", "\"RT\"をつける", "\"RT:\"をつける", "\"RT>\"をつける", "\"\"で囲む", "URLのみ引用する"]
    
    var rtMode = 5
    let saveData = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.allowsMultipleSelection = false
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        if saveData.object(forKey: "rtMode") != nil {
            rtMode = saveData.object(forKey: "rtMode") as! Int
        } else {
            saveData.set(rtMode, forKey: "rtMode")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return labelText.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "引用リツイートの形式"
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "rtCell", for: indexPath)

        // Configure the cell...
        cell.textLabel?.text = labelText[indexPath.row]
        if indexPath.row == rtMode {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
    }
 
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        rtMode = indexPath.row
        saveData.set(rtMode, forKey: "rtMode")
        tableView.reloadData()
    }
    
}
