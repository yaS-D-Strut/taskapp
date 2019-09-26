//
//  ViewController.swift
//  taskapp
//
//  Created by Yasuaki Osada on 2019/09/15.
//  Copyright © 2019 Yasuaki Osada. All rights reserved.
//

import UIKit
import RealmSwift
import UserNotifications

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    
    //
    var items : NSArray = []                    //検索用配列
    private var searchResult : NSArray = []     //検索結果配列
    //
    
    @IBOutlet weak var categorySearch: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    // Realmインスタンスを取得する
    let realm = try! Realm()
    
    // DB内のタスクが格納されるリスト
    // 日付近い順\順でソート：降順
    // 以降内容をアップデートするとリスト内は自動的に更新される。
    var taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: false)
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        
        // デリゲート先を自分に設定する
        categorySearch.delegate = self
        
        // 何も入力されていなくてもReturnキーを押せるようにする
        categorySearch.enablesReturnKeyAutomatically = false
        //
        
    }

    // MARK: UITableViewDataSourceプロトコルのメソッド
    // データの数（＝セルの数）を返すメソッド
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return taskArray.count
    }
    
    // MARK: - 渡された文字列を含む要素を検索し、テーブルビューを再表示する
    func searchItems(searchText: String){
        // 要素を検索する
        if searchText != "" {
            searchResult = items.filter { item in
                return (item as! String).contains(searchText)
                } as NSArray
            //渡された文字列が空の場合は全てを表示する
            searchResult = items
        }
    }
    
    
    // 各セルの内容を返すメソッド
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 再利用可能な cell を得る
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        //Cellに値を設定する.   --- ここから ---
        let task = taskArray[indexPath.row]
        cell.textLabel?.text = task.title
        cell.textLabel?.text = task.category
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        
        let dateString:String = formatter.string(from: task.date)
        cell.detailTextLabel?.text = dateString
        // --- ここまで追加 ---
        
        return cell
    }
    
    //
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // キャンセルされた場合、検索は行わない
        categorySearch.text = ""
        self.view.endEditing(true)
        searchResult = items
    }
    //検索ボタン押下時の呼び出しメソッド
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // キーボードを閉じる
        self.view.endEditing(true)
        print("検索ボタンが押されました")
        
        taskArray = try!Realm().objects(Task.self).filter("category BEGINSWITH %@",searchBar.text!)
        print("taskArray")
        
        tableView.reloadData()
        
        if categorySearch.text == "" {
            taskArray = try! Realm().objects(Task.self).sorted(byKeyPath: "date", ascending: false)
            tableView.reloadData()
            
        }
    }
    
    
    // MARK: UITableViewDelegateプロトコルのメソッド
    // 各セルを選択した時に実行されるメソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "cellSegue",sender: nil)
    }
    
    // セルが削除が可能な事を伝えるメソッド
    func tableView(_ tableView:UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    // Delete ボタンが押された時に呼ばれるメソッド
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        // --- ここから ---
        if editingStyle == .delete{
            // 削除するタスクを取得する
            let task = self.taskArray[indexPath.row]
            
            // ローカル通知をキャンセルする
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [String(task.id)])
            
            // データベースから削除する
            try! realm.write {
                self.realm.delete(task)
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            
            // 未通知のローカル通知一覧をログ出力
            center.getPendingNotificationRequests { (requests: [UNNotificationRequest]) in
                for request in requests {
                    print("/---------------")
                    print(request)
                    print("---------------/")
                }
            }
        }
    }// --- ここまで追加 ---
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        let inputViewController:InputViewController = segue.destination as! InputViewController
        
        if segue.identifier == "cellSegue" {
            let indexPath = self.tableView.indexPathForSelectedRow
            inputViewController.task = taskArray[indexPath!.row]
        } else {
            let task = Task()
            task.date = Date()
            
            let allTasks = realm.objects(Task.self)
            if allTasks.count != 0{
                task.id = allTasks.max(ofProperty: "id")! + 1
            }
            
            inputViewController.task = task
        }
    }
    
    // 入力画面から戻ってきた時に TableView を更新させる
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
}


