//
//  MuteSettingViewController.swift
//  Imagenius
//
//  Created by 藤井陽介 on 2016/09/28.
//  Copyright © 2016年 touyou. All rights reserved.
//

import UIKit

final class MuteSettingViewController: UIViewController {

    @IBOutlet weak var settingTableView: UITableView! {
        didSet {
            settingTableView.delegate = self
            settingTableView.dataSource = self
        }
    }
    
    let labelText = ["単語ミュートオン", "単語ミュートオフ"]
    let saveData = UserDefaults.standard
    
    var muteText = [String]()
    var muteMode: Int!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if saveData.object(forKey: "muteWords") != nil {
            muteText = saveData.object(forKey: "muteWords") as! [String]
        } else {
            saveData.set(muteText, forKey: "muteWords")
        }
        
        if saveData.object(forKey: "muteMode") != nil {
            muteMode = saveData.object(forKey: "muteMode") as! Int
        } else {
            muteMode = 1
            saveData.set(muteMode, forKey: "muteMode")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension MuteSettingViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return labelText.count
        } else {
            return muteText.count + 1
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 {
            return "単語一覧"
        }
        return ""
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "muteCell", for: indexPath)
        
        if indexPath.section == 0 {
            cell.textLabel?.text = labelText[indexPath.row]
            if muteMode == indexPath.row {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
        } else {
            if indexPath.row == muteText.count {
                cell.textLabel?.text = "新しい単語を登録"
                cell.accessoryType = .disclosureIndicator
            } else {
                cell.textLabel?.text = muteText[indexPath.row]
                cell.accessoryType = .none
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            muteMode = indexPath.row
            saveData.set(muteMode, forKey: "muteMode")
            tableView.reloadData()
        } else {
            if indexPath.row == muteText.count {
                let alertView = UIAlertController(title: "新しい単語を登録", message: "ミュートした単語を入力してください。", preferredStyle: .alert)
                alertView.addTextField(configurationHandler: { text in
                    text.placeholder = "単語を入力する"
                })
                alertView.addAction(UIAlertAction(title: "登録", style: .default, handler: { action in
                    let fields = alertView.textFields
                    guard let text = fields?[0].text else {
                        return
                    }
                    self.muteText.append(text)
                    self.saveData.set(self.muteText, forKey: "muteWords")
                    self.settingTableView.reloadData()
                }))
                alertView.addAction(UIAlertAction(title: "キャンセル", style: .cancel, handler: nil))
                present(alertView, animated: true, completion: nil)
            } else {
                let alertView = UIAlertController(title: "削除", message: "削除しますか？", preferredStyle: .alert)
                alertView.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                alertView.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
                    self.muteText.remove(at: indexPath.row)
                    self.saveData.set(self.muteText, forKey: "muteWords")
                    self.settingTableView.reloadData()
                }))
                present(alertView, animated: true, completion: nil)
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
