//
//  UserDetailViewController.swift
//  chatchat2
//
//  Created by Tony Shi on 15/9/29.
//  Copyright © 2015年 Tony Shi. All rights reserved.
//

import UIKit
import CoreData
import Alamofire
import MBProgressHUD

class UserDetailViewController: UIViewController {
    @IBOutlet weak var sendRequestBtn: UIButton!
    @IBOutlet weak var blockBtn: UIButton!
    @IBOutlet weak var SendMsgBtn: UIButton!
    @IBOutlet weak var deleteBtn: UIButton!
    @IBOutlet weak var descTextView: UITextView!
    @IBOutlet weak var genderImageView: UIImageView!
    @IBOutlet weak var acceptBtn: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var portraitImageView: UIImageView!
    @IBOutlet weak var statusLabel: UILabel!
    
    var context: NSManagedObjectContext!
    
    var user_id: String?
    var user: UserModel?
    var status: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBarController?.hidesBottomBarWhenPushed = true
        
        context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext

        self.navigationItem.title = ""
        self.nameLabel.hidden = true
        self.genderImageView.hidden = true
        self.descTextView.hidden = true
        self.portraitImageView.hidden = true
        
        if self.user_id != nil {
            loadUserDetail(self.user_id!)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func loadUserDetail(user_id: String){
        
        let loadingNotification = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        loadingNotification.mode = MBProgressHUDMode.Indeterminate
        loadingNotification.labelText = "加载中..."
        
        let url = "\(server_path)/api/v1/user/\(self.user_id!)"
        Alamofire.request(.GET, url, encoding: .JSON).responseJSON() {
            (request, response, data) in
            
            if data.isSuccess{
                let value = data.value! as! NSDictionary
                let id = String(value.valueForKey("user_id") as! Int)
                let name = value.valueForKey("username") as! String
                let gender = value.valueForKey("gender") as! String
                let portrait = value.valueForKey("portrait") as! String
                let desc = value.valueForKey("desc") as! String
                
                self.user = UserModel(id: id, name: name, portraitURL: portrait, phoneNumber: "", gender: gender, desc: desc)
                self.navigationItem.title = self.user!.name
                
                self.nameLabel.hidden = false
                self.genderImageView.hidden = false
                self.descTextView.hidden = false
                self.portraitImageView.hidden = false
                
                self.nameLabel.text = self.user!.name
                self.genderImageView.image = UIImage(named: "gender-\(self.user!.gender!.lowercaseString)-25")
                self.descTextView.text = self.user!.desc
                self.portraitImageView.image = UIImage(named: self.user!.portraitURL!)
                
                self.toggleButtons()
            }
            else{
                let alertController = UIAlertController(title: "提示", message: "加载失败", preferredStyle: UIAlertControllerStyle.Alert)
                let okAction = UIAlertAction(title: "确定", style: UIAlertActionStyle.Default, handler: nil)
                alertController.addAction(okAction)
                
                self.presentViewController(alertController, animated: true, completion: nil)
            }
            
            MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
        }
    }
    
    @IBAction func acceptBtnTapped(sender: AnyObject) {
        let loadingNotification = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        loadingNotification.mode = MBProgressHUDMode.Indeterminate
        loadingNotification.labelText = "加载中..."

        let url = "\(server_path)/api/v1/friendship/\(self.user_id!)/\(currentUser!.id)"
        Alamofire.request(.PUT, url).responseJSON() {
            (request, response, data) in
            if data.isFailure{
                print("Failed syncing friendship")
            }
            else{
                self.status = "mutual-friend"
                do {
                    let f = NSFetchRequest(entityName: "Friends")
                    f.predicate = NSPredicate(format: "id = %@", self.user_id!)
                    let existingFriends:Array<AnyObject> = try self.context.executeFetchRequest(f)
                    
                    if existingFriends.count != 0{
                        let friend = existingFriends.first as! NSManagedObject
                        friend.setValue(self.status, forKey: "status")
                    }
                    else{
                        let row = NSEntityDescription.insertNewObjectForEntityForName("Friends", inManagedObjectContext: self.context)
                        
                        row.setValue(self.user!.id, forKey: "id")
                        row.setValue(self.user!.name, forKey: "name")
                        row.setValue(self.user!.portraitURL, forKey: "portrait")
                        row.setValue(self.status, forKey: "status")
                    }
                    try self.context.save()
                }catch{
                    print(error)
                }
                
                self.toggleButtons()
                MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
            }
        }
    }
    
    @IBAction func deleteBtnTapped(sender: AnyObject) {
        let alertController = UIAlertController(title: "提示", message: "确定要删除好友\(self.user!.name)吗？", preferredStyle: UIAlertControllerStyle.Alert)
        let cancelAction = UIAlertAction(title: "取消", style: UIAlertActionStyle.Cancel, handler: nil)
        let okAction = UIAlertAction(title: "确定", style: UIAlertActionStyle.Default){
            (action: UIAlertAction!) -> Void in
            do{
                let f = NSFetchRequest(entityName: "Friends")
                f.predicate = NSPredicate(format: "id = %@", self.user_id!)
                let existingSessions:Array<AnyObject> = try self.context.executeFetchRequest(f)
                
                if existingSessions.count == 0{
                    return
                }
                /****
                
                URL: https://chachat.com/api/v1/friendship/delete/<userid>/<friendid>
                
                ****/
                
                self.context.deleteObject(existingSessions.first as! NSManagedObject)
                self.status = "stranger"
                self.toggleButtons()
            }catch{
                print(error)
            }
        }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
    @IBAction func sendRequestBtnTapped(sender: AnyObject) {
        let url = "\(server_path)/api/v1/friendship/\(currentUser!.id)/\(self.user_id!)"
        Alamofire.request(.POST, url).responseJSON() {
            (request, response, data) in
            if data.isFailure{
                print("Failed syncing friendship")
            }
            else{
                do{
                    let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
                    let row = NSEntityDescription.insertNewObjectForEntityForName("Friends", inManagedObjectContext: context)
                    
                    row.setValue(self.user!.id, forKey: "id")
                    row.setValue(self.user!.name, forKey: "name")
                    row.setValue(self.user!.portraitURL, forKey: "portrait")
                    row.setValue("request-sent", forKey: "status")
                    
                    try context.save()
                    
                    let alertController = UIAlertController(title: "提示", message: "您已经发送请求添加\(self.user!.name)为好友。", preferredStyle: UIAlertControllerStyle.Alert)
                    let okAction = UIAlertAction(title: "确定", style: UIAlertActionStyle.Default){
                        (action: UIAlertAction!) -> Void in
                        self.status = "request-sent"
                        self.toggleButtons()
                    }
                    alertController.addAction(okAction)
                    
                    self.presentViewController(alertController, animated: true, completion: nil)
                }catch{
                    print(error)
                }
            }
        }
    }
    
    func toggleButtons(){
        if self.status == "mutual-friend" {
            self.sendRequestBtn.hidden = true
            self.blockBtn.hidden = true
            self.SendMsgBtn.hidden = false
            self.deleteBtn.hidden = false
            
            self.acceptBtn.hidden = true
            self.statusLabel.hidden = true
        }
        else if self.status == "stranger"{
            self.sendRequestBtn.hidden = false
            self.blockBtn.hidden = false
            self.SendMsgBtn.hidden = true
            self.deleteBtn.hidden = true
            
            self.acceptBtn.hidden = true
            self.statusLabel.hidden = true
        }
        else if self.status == "request-sent"{
            self.sendRequestBtn.hidden = true
            self.blockBtn.hidden = true
            self.SendMsgBtn.hidden = true
            self.deleteBtn.hidden = true
            
            self.statusLabel.hidden = false
        }
        else if self.status == "request-received"{
            self.sendRequestBtn.hidden = true
            self.blockBtn.hidden = true
            self.SendMsgBtn.hidden = true
            self.deleteBtn.hidden = true
            
            self.acceptBtn.hidden = false
            self.statusLabel.hidden = true
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "GoToChatFromUserDetail" {
            
            addChatSession(SessionModel(id: self.user!.id, name: self.user!.name, portraitURL: user!.portraitURL!, type: "P"))
            
            let cv = segue.destinationViewController as! ChatViewController
            cv.targetId = self.user!.id
            cv.userName = self.user!.name
            cv.conversationType = RCConversationType.ConversationType_PRIVATE
            
            cv.hidesBottomBarWhenPushed = true
        }
    }
    
    func addChatSession(session: SessionModel){
        
        let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        
        do{
            let f = NSFetchRequest(entityName: "Sessions")
            f.predicate = NSPredicate(format: "id = %@", session.id)
            let existingSessions:Array<AnyObject> = try context.executeFetchRequest(f)
            
            if existingSessions.count != 0{
                return
            }
            
            let row = NSEntityDescription.insertNewObjectForEntityForName("Sessions", inManagedObjectContext: context)
            
            row.setValue(session.id, forKey: "id")
            row.setValue(session.name, forKey: "name")
            row.setValue(session.portraitURL, forKey: "portrait")
            row.setValue(session.type, forKey: "type")
            
            try context.save()
        }catch{
            print(error)
        }

    }

}
