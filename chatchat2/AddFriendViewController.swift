//
//  AddFriendViewController.swift
//  chatchat2
//
//  Created by Tony Shi on 15/9/29.
//  Copyright © 2015年 Tony Shi. All rights reserved.
//

import UIKit
import SwiftyJSON
import CoreData
import Alamofire
import MBProgressHUD

class AddFriendViewController: UITableViewController{
    
    var context: NSManagedObjectContext!
    
    var nearbyUsers:[UserModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        // Do any additional setup after loading the view.
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self, action: "searchNearbyUsers", forControlEvents: UIControlEvents.ValueChanged)
        
        searchNearbyUsers()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("nearbyUserCell", forIndexPath: indexPath) as UITableViewCell
        
        let user = self.nearbyUsers[indexPath.row] as UserModel
        
        let name = self.tableView.viewWithTag(2001) as! UILabel
        let portrait = self.tableView.viewWithTag(2002) as! UIImageView
        
        name.text = user.name
        portrait.image = UIImage(named: user.portraitURL!)
        
        return cell
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.nearbyUsers.count
    }
    
    func searchNearbyUsers() {
//        let loadingNotification = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
//        loadingNotification.mode = MBProgressHUDMode.Indeterminate
//        loadingNotification.labelText = "Loading"
//      
        self.refreshControl?.beginRefreshing()
        self.nearbyUsers = []
        
        let url = "\(server_path)/api/v1/user/nearby/\(currentUser!.id)"
        Alamofire.request(.GET, url).responseJSON() {
            (request, response, data) in
            
            let values = data.value! as! NSArray
            
            for value in values {
                let id = String(value.valueForKey("user_id") as! Int)
                let name = value.valueForKey("username") as! String
                let gender = value.valueForKey("gender") as! String
                let portrait = value.valueForKey("portrait") as! String
                //let phoneNumber = value.valueForKey("phone_number") as! String
                let desc = value.valueForKey("desc") as! String
                
                do {
                    let f = NSFetchRequest(entityName: "Friends")
                    f.predicate = NSPredicate(format: "id = %@", id)
                    let existingFriends:Array<AnyObject> = try self.context.executeFetchRequest(f)
                    
                    if existingFriends.count == 0{
                        self.nearbyUsers.append(UserModel(id: id, name: name, portraitURL: portrait, phoneNumber: "", gender: gender, desc: desc))
                    }
                }catch{
                    print(error)
                }
            }
            self.refreshControl?.endRefreshing()
            self.tableView.reloadData()
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "GoToUserDetailFromNearbyUsers" {
            let udvc = segue.destinationViewController as! UserDetailViewController
            udvc.user_id = self.nearbyUsers[(self.tableView.indexPathForSelectedRow?.row)!].id
            udvc.status = "stranger"
            
            udvc.hidesBottomBarWhenPushed = true
        }
    }

}
