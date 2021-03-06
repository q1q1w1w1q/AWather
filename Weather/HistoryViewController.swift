//
//  HistoryViewController.swift
//  Weather
//
//  Created by Allen Wang on 2017/6/28.
//  Copyright © 2017年 Allen Wang. All rights reserved.
//

import UIKit
import CoreLocation

class HistoryViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    var histories: Set<LocationModel> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        // Do any additional setup after loading the view.
        
        let ud = UserDefaults.standard
        let decoded  = ud.object(forKey: Constant.USER_CREATION) as! Data
        let decodedModel = NSKeyedUnarchiver.unarchiveObject(with: decoded) as! Set<LocationModel>
        histories = decodedModel
        
    }
    
}

extension HistoryViewController: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return histories.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            as UITableViewCell
        let index = histories.index(histories.startIndex, offsetBy: indexPath.section)
        cell.textLabel?.text = histories[index].city
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let index = histories.index(histories.startIndex, offsetBy: indexPath.section)
        let c =  histories[index].coordinate
        let d: [String: CLLocationCoordinate2D] = ["coordinate": c]
        NotificationCenter.default.post(name: Notification.Name("pressedHistory"), object: nil,  userInfo: d)
        self.dismiss(animated: true, completion: nil)
    }

}
