//
//  ViewController.swift
//  chatchat2
//
//  Created by Tony Shi on 15/9/29.
//  Copyright © 2015年 Tony Shi. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire
import CoreData
import QuartzCore

class ViewController: UIViewController, UITableViewDataSource, RCIMReceiveMessageDelegate, RCIMUserInfoDataSource{
    var context:NSManagedObjectContext!
    @IBOutlet weak var tableView: UITableView!
    
    var sessions:Array<AnyObject> = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate
        context = appDelegate!.managedObjectContext
        self.tableView.dataSource = self
        
        navigationItem.leftBarButtonItem = editButtonItem()
        
        appDelegate?.connectServer(){
            print("未连接")
        }
        appDelegate?.syncFriendships(){}
        
        RCIM.sharedRCIM().receiveMessageDelegate = self
        RCIM.sharedRCIM().userInfoDataSource = self
        
        reloadChatSessions()
        
        self.view.setNeedsDisplay()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        reloadChatSessions()
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        self.tableView.setEditing(editing, animated: true)
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return self.editing
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        let session = self.sessions.removeAtIndex(sourceIndexPath.row)
        self.sessions.insert(session, atIndex: destinationIndexPath.row)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sessions.count
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == UITableViewCellEditingStyle.Delete {
            do{
                self.context.deleteObject(self.sessions[indexPath.row] as! NSManagedObject)
                try self.context.save()
            }catch{
                print(error)
            }
            self.sessions.removeAtIndex(indexPath.row)
            self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("sessionCell", forIndexPath: indexPath) as UITableViewCell
        
        let session = self.sessions[indexPath.row] as! NSManagedObject
        
        let name = self.tableView.viewWithTag(3001) as! UILabel
        let lastMsg = self.tableView.viewWithTag(3002) as! UILabel
        let portrait = self.tableView.viewWithTag(3003) as! UIImageView
        let unreadLabel = self.tableView.viewWithTag(3004) as! UILabel
        
        name.text = session.valueForKey("name") as? String
        lastMsg.text = session.valueForKey("last_msg") as? String
        portrait.image = UIImage(named: (session.valueForKey("portrait") as! String))
        
        let unreadCnt = session.valueForKey("unread_cnt") as! Int
        unreadLabel.text = String(unreadCnt)
        unreadLabel.hidden = unreadCnt == 0
        unreadLabel.textColor = UIColor.whiteColor()
        unreadLabel.backgroundColor = UIColor.redColor()
        unreadLabel.textAlignment = NSTextAlignment.Center
        unreadLabel.layer.cornerRadius = 10
        unreadLabel.layer.borderWidth = 2
        unreadLabel.layer.borderColor = UIColor.redColor().CGColor
        unreadLabel.layer.masksToBounds = true
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 80
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "GoToChatFromSessionList" {
            let cv = segue.destinationViewController as! ChatViewController
            let session = self.sessions[(self.tableView.indexPathForSelectedRow?.row)!] as!NSManagedObject
            
            cv.targetId = session.valueForKey("id") as? String
            cv.userName = session.valueForKey("name") as? String
            if let type = session.valueForKey("type") as? String{
                switch type{
                    case "P" :
                        cv.conversationType = RCConversationType.ConversationType_PRIVATE
                    case "G" :
                        cv.conversationType = RCConversationType.ConversationType_GROUP
                    default:
                        cv.conversationType = RCConversationType.ConversationType_PRIVATE
                }
            }
            
            cv.hidesBottomBarWhenPushed = true
            
            do{
                session.setValue(0, forKey: "unread_cnt")
                try context.save()
            }catch{
                print(error)
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                self.reloadChatSessions()
            }
        }
    }
    
    func reloadChatSessions(){
        do {
            let f = NSFetchRequest(entityName: "Sessions")
            self.sessions = try context.executeFetchRequest(f)
        }catch{
            self.sessions = []
        }
        
        self.tableView.reloadData()
        
        self.setBarItemBadge()
    }
    
    func getUserInfoWithUserId(userId: String!, completion: ((RCUserInfo!) -> Void)!) {
        if let user = getUserInfo(userId){
            let portrait = "\(server_path)/user/\(user.portraitURL!).png"
            return completion(RCUserInfo(userId: user.id, name: user.name, portrait: portrait))
        }
    }
    
    func getUserInfo(userId: String!) -> UserModel?{
        do{
            var f = NSFetchRequest(entityName: "Friends")
            
            f.predicate = NSPredicate(format: "id = %@", userId)
            var existingFriends:Array<AnyObject> = try self.context.executeFetchRequest(f)
            
            if existingFriends.count == 0{
                f = NSFetchRequest(entityName: "User")
                
                f.predicate = NSPredicate(format: "id = %@", userId)
                existingFriends = try self.context.executeFetchRequest(f)
                if existingFriends.count == 0 {
                    return nil
                }
            }
            let friendInCoreData:NSManagedObject = existingFriends.first as! NSManagedObject
            
            let name = friendInCoreData.valueForKey("name") as! String
            let portrait = friendInCoreData.valueForKey("portrait") as! String
            return UserModel(id: userId, name: name, portraitURL: portrait)
        }catch{
            print(error)
        }
        
        return nil
    }
    
    func onRCIMReceiveMessage(message: RCMessage!, left: Int32) {
        do{
            let f = NSFetchRequest(entityName: "Sessions")
            
            f.predicate = NSPredicate(format: "id = %@", message.senderUserId)
            let existingSessions:Array<AnyObject> = try self.context.executeFetchRequest(f)
            if existingSessions.count == 0 {
                if let user = getUserInfo(message.senderUserId){
                    let row = NSEntityDescription.insertNewObjectForEntityForName("Sessions", inManagedObjectContext: context)
                        
                    row.setValue(message.senderUserId, forKey: "id")
                    row.setValue(user.name, forKey: "name")
                    row.setValue(user.portraitURL, forKey: "portrait")
                    
                    row.setValue(1, forKey: "unread_cnt")
                    row.setValue("P", forKey: "type")
                    
                    if message.content is RCTextMessage{
                        row.setValue(message.content.valueForKey("content") as! String, forKey: "last_msg")
                    }
                    else if message.content is RCVoiceMessage{
                        row.setValue("[语音]", forKey: "last_msg")
                    }
                    else if message.content is RCImageMessage{
                        row.setValue("[图片]", forKey: "last_msg")
                    }
                    else if message.content is RCLocationMessage{
                        row.setValue("[位置]", forKey: "last_msg")
                    }
                    else{
                        row.setValue("[消息]", forKey: "last_msg")
                    }
                }
            }
            else{
                let session = existingSessions[0] as! NSManagedObject
                let unreadCnt = session.valueForKey("unread_cnt") as! Int
                session.setValue(unreadCnt+1, forKey: "unread_cnt")
                if message.content is RCTextMessage{
                    session.setValue(message.content.valueForKey("content") as! String, forKey: "last_msg")
                }
                else if message.content is RCVoiceMessage{
                    session.setValue("[语音]", forKey: "last_msg")
                }
                else if message.content is RCImageMessage{
                    session.setValue("[图片]", forKey: "last_msg")
                }
                else if message.content is RCLocationMessage{
                    session.setValue("[位置]", forKey: "last_msg")
                }
                else{
                    session.setValue("[消息]", forKey: "last_msg")
                }
            }
            
            self.tabBarItem.badgeValue = "1"
            try context.save()
        }catch{
            print(error)
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            self.reloadChatSessions()
        }
    }
    
    func setBarItemBadge(){
        var unreadSessionCnt = 0
        for session in self.sessions {
            let unreadCnt = session.valueForKey("unread_cnt") as! Int
            if unreadCnt > 0 {
                unreadSessionCnt = unreadSessionCnt + 1
            }
        }
        self.navigationController?.tabBarItem.badgeValue = unreadSessionCnt==0 ? nil : String(unreadSessionCnt)
        UIApplication.sharedApplication().applicationIconBadgeNumber = unreadSessionCnt
    }
}

