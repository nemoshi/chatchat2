//
//  ChatViewController.swift
//  chatchat2
//
//  Created by Tony Shi on 15/9/29.
//  Copyright © 2015年 Tony Shi. All rights reserved.
//

import UIKit
import CoreData

class ChatViewController: RCConversationViewController {

    var context:NSManagedObjectContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        self.navigationItem.title = "与\(self.userName)聊天"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        do{
            let f = NSFetchRequest(entityName: "Sessions")
            
            f.predicate = NSPredicate(format: "id = %@", self.targetId)
            let existingSessions:Array<AnyObject> = try self.context.executeFetchRequest(f)
            
            let session = existingSessions.first as! NSManagedObject
            
            session.setValue(0, forKey: "unread_cnt")
            try context.save()
        }catch{
            print(error)
        }
    }

    override func didSendMessage(stauts: Int, content messageCotent: RCMessageContent!) {
        do{
            let f = NSFetchRequest(entityName: "Sessions")
            
            f.predicate = NSPredicate(format: "id = %@", self.targetId)
            let existingSessions:Array<AnyObject> = try self.context.executeFetchRequest(f)
            
            let session = existingSessions.first as! NSManagedObject
            
            if messageCotent is RCTextMessage{
                session.setValue(messageCotent.valueForKey("content") as! String, forKey: "last_msg")
            }
            else if messageCotent is RCVoiceMessage{
                session.setValue("[语音]", forKey: "last_msg")
            }
            else if messageCotent is RCImageMessage{
                session.setValue("[图片]", forKey: "last_msg")
            }
            else if messageCotent is RCLocationMessage{
                session.setValue("[位置]", forKey: "last_msg")
            }
            else{
                session.setValue("[消息]", forKey: "last_msg")
            }
            try self.context.save()
        }catch{
            print(error)
        }
    }
}
