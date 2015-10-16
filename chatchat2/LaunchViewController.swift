//
//  LoginViewController.swift
//  chatchat2
//
//  Created by Tony Shi on 15/10/4.
//  Copyright © 2015年 Tony Shi. All rights reserved.
//

import UIKit
import CoreData

var currentUser: UserModel?

class LaunchViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(false)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(animated: Bool) {
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        self.navigationController?.navigationBarHidden = true
        NSThread.sleepForTimeInterval(1)
        if isCurrentUserLRegistered(){
            self.performSegueWithIdentifier("GoToMainFromLaunch", sender: self)
        }
        else{
            self.performSegueWithIdentifier("GoToRegister", sender: self)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func isCurrentUserLRegistered() -> Bool{
        let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        
        do{
            let f = NSFetchRequest(entityName: "User")
            let existingUsers:Array<AnyObject> = try context.executeFetchRequest(f)
            
            if existingUsers.count != 0{
                let record = existingUsers[0] as! NSManagedObject
                
                let id = record.valueForKey("id") as! String
                let name = record.valueForKey("name") as! String
                let gender = record.valueForKey("gender") as! String
                let portrait = record.valueForKey("portrait") as! String
                
                currentUser = UserModel(id: id, name: name, portraitURL: portrait)
                currentUser?.gender = gender
                
                return true
            }
        }catch{
            print(error)
        }
        return false
    }

}
