//
//  FriendsListViewController.swift
//  chatchat2
//
//  Created by Tony Shi on 15/9/29.
//  Copyright © 2015年 Tony Shi. All rights reserved.
//

import UIKit
import SwiftyJSON
import CoreData
import QuartzCore
import Alamofire
import MBProgressHUD

class FriendsListViewController: UIViewController, UITableViewDataSource,  UISearchDisplayDelegate{
    var context:NSManagedObjectContext!
    var dataArr:Array<AnyObject> = []
    var filteredDataArr:Array<AnyObject> = []
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        
        self.tableView.dataSource = self
        dispatch_async(dispatch_get_main_queue()) {
            self.queryFriendsFromCoreData()
        }
        
        print("viewDidLoad")
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        dispatch_async(dispatch_get_main_queue()) {
            self.queryFriendsFromCoreData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let friend:NSManagedObject
        
        if self.tableView == searchDisplayController?.searchResultsTableView{
            friend = filteredDataArr[indexPath.row] as! NSManagedObject
        }
        else{
            friend = dataArr[indexPath.row] as! NSManagedObject
        }
        
        let cell = self.tableView.dequeueReusableCellWithIdentifier("friendCell")! as UITableViewCell
        
        let nameLabel = cell.viewWithTag(1001) as! UILabel
        let portraitImageView = cell.viewWithTag(1002) as! UIImageView
        let statusLabel = cell.viewWithTag(1003) as! UILabel
        statusLabel.layer.borderColor = UIColor.grayColor().CGColor
        statusLabel.layer.borderWidth = 1.0
        statusLabel.textAlignment = NSTextAlignment.Center
        statusLabel.textColor = UIColor.blackColor()
        statusLabel.layer.cornerRadius = 5
        statusLabel.layer.borderWidth = 1
        statusLabel.layer.borderColor = UIColor.grayColor().CGColor
        statusLabel.layer.masksToBounds = true
        
        nameLabel.text = friend.valueForKey("name") as? String
        portraitImageView.image = UIImage(named: (friend.valueForKey("portrait") as! String))
        let status = friend.valueForKey("status") as? String
        
        switch status! {
        case "mutual-friend":
            statusLabel.backgroundColor = UIColor.greenColor()
            statusLabel.text = "好友"
        case "request-sent":
            statusLabel.backgroundColor = UIColor.brownColor()
            statusLabel.text = "已发送好友请求"
        case "request-received":
            statusLabel.backgroundColor = UIColor.orangeColor()
            statusLabel.text = "收到好友请求"
        default:
            statusLabel.backgroundColor = UIColor.grayColor()
            statusLabel.text = ""
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.tableView == searchDisplayController?.searchResultsTableView{
            return filteredDataArr.count
        }
        else{
            return dataArr.count
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 70
    }
    
    func searchDisplayController(controller: UISearchDisplayController, shouldReloadTableForSearchString searchString: String!) -> Bool {
        self.filteredDataArr = self.dataArr.filter(){
            let name = ($0 as! NSManagedObject).valueForKey("name") as! String
            let a = name.rangeOfString(searchString) != nil
            return a
        }
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "GoToUserDetailFromFriendsList" {
            let udvc = segue.destinationViewController as! UserDetailViewController
            
            let user = dataArr[(self.tableView.indexPathForSelectedRow?.row)!]
            
            udvc.user_id = user.valueForKey("id") as? String
            udvc.status = user.valueForKey("status") as? String
            
            udvc.hidesBottomBarWhenPushed = true
        }
    }
    
    func queryFriendsFromCoreData(){
        let loadingNotification = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        loadingNotification.mode = MBProgressHUDMode.Indeterminate
        loadingNotification.labelText = "加载中..."
        
        let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate
        
        appDelegate?.syncFriendships(){
            do {
                let f = NSFetchRequest(entityName: "Friends")
                self.dataArr = try self.context.executeFetchRequest(f).sort(){
                    
                    let statusPriority = ["mutual-friend":0, "request-received": 1, "request-sent": 2]
                    
                    let name0 = ($0 as! NSManagedObject).valueForKey("name") as! String
                    let name1 = ($1 as! NSManagedObject).valueForKey("name") as! String
                    let status0 = statusPriority[($0 as! NSManagedObject).valueForKey("status") as! String]
                    let status1 = statusPriority[($1 as! NSManagedObject).valueForKey("status") as! String]
                    
                    return status0 < status1 && name0 < name0
                }
            }catch{
                self.dataArr = []
            }
            self.tableView.reloadData()
            MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
        }
    }
}
