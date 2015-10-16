//
//  AppDelegate.swift
//  chatchat2
//
//  Created by Tony Shi on 15/9/29.
//  Copyright © 2015年 Tony Shi. All rights reserved.
//

import UIKit
import CoreData
import Alamofire
import SwiftyJSON

let server_path = "http://45.78.39.38"
//let server_path = "http://localhost:9292"

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        //设置Notification 的类型
        let types:UIUserNotificationType = [UIUserNotificationType.Alert, UIUserNotificationType.Badge, UIUserNotificationType.Sound]
        
        //设置Notification的设置项，其中categories参数用来设置Notification的类别
        let mySettings: UIUserNotificationSettings = UIUserNotificationSettings(forTypes: types, categories: nil)
        
        //注册UserNotification
        UIApplication.sharedApplication().registerUserNotificationSettings(mySettings)
        
        print("DDDD")
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }
    
    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "net.nemo.chatchat2" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("chatchat2", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason

            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()

    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let token = deviceToken.description.stringByReplacingOccurrencesOfString("<", withString: "").stringByReplacingOccurrencesOfString(">", withString: "").stringByReplacingOccurrencesOfString(" ", withString: "")
        RCIMClient.sharedRCIMClient().setDeviceToken(token)
    }
    
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        application.registerForRemoteNotifications()
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print(error.description)
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        print("didReceiveRemoteNotification")
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        print("didReceiveRemoteNotification")
    }
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        print("didReceiveLocalNotification")
    }
    
    func connectServer(failedConnection: Void -> Void) {
        //获取保存的token
        fetchUserToken(){ (userToken: String) -> Void in
            //初始化app key
            RCIM.sharedRCIM().initWithAppKey("8luwapkvu1u7l")
            RCIM.sharedRCIM().connectWithToken(userToken,
                success: { (str:String!) -> Void in
                    
                    let currentUserInfo = RCUserInfo(userId: currentUser?.id, name: currentUser?.name, portrait: "\(server_path)/user/\(currentUser!.portraitURL!).png")
                    RCIMClient.sharedRCIMClient().currentUserInfo = currentUserInfo
                    dispatch_async(dispatch_get_main_queue()) { () -> Void in
                        print("complete")
                    }
                },
                error: { (code:RCConnectErrorCode) -> Void in
                    print("无法连接！\(code)")
                    failedConnection()
                }
            ){ () -> Void in
                print("无效token！")
            }
        }
    }
    
    func fetchUserToken(callback: (String) -> Void){
        
        do{
            let f = NSFetchRequest(entityName: "User")
            
            f.predicate = NSPredicate(format: "id = %@", (currentUser?.id)!)
            let existingUsers:Array<AnyObject> = try self.managedObjectContext.executeFetchRequest(f)
            let currentUserInCoreData:NSManagedObject = existingUsers.first as! NSManagedObject
            var token = currentUserInCoreData.valueForKey("token") as? String
            
            print("Current User ID : \(currentUser!.id)")
            
            if token != nil {
                callback(token!)
            }
            else{
                let parameters:Dictionary<String,String> = ["user_id" : currentUser!.id, "username": currentUser!.name, "portraitUri": currentUser!.portraitURL!]
                
                let url = "\(server_path)/api/v1/user/token"
                Alamofire.request(.POST, url, parameters: parameters, encoding: .JSON).responseJSON() {
                    (request, response, data) in
                    
                    let value = data.value! as! NSDictionary
                    token = value.valueForKey("token") as! String
                    
                    do{
                        currentUserInCoreData.setValue(token, forKey: "token")
                        
                        try self.managedObjectContext.save()
                    }catch{
                        print(error)
                    }
                    
                    callback(token!)
                }
            }
        }catch{
            print(error)
        }
    }
    
    func syncFriendships(dataUpdated: Void -> Void){
        let url = "\(server_path)/api/v1/friendship/\(currentUser!.id)"
        Alamofire.request(.GET, url).responseJSON() {
            (request, response, data) in
            if data.isFailure{
                print("Failed syncing friendship")
            }
            else{
                let values = data.value! as! NSArray
                
                for value in values {
                    let id = String(value.valueForKey("user_id") as! Int)
                    let name = value.valueForKey("username") as! String
                    let portrait = value.valueForKey("portrait") as! String
                    let status = value.valueForKey("status") as! String
                    
                    do {
                        let f = NSFetchRequest(entityName: "Friends")
                        f.predicate = NSPredicate(format: "id = %@", id)
                        let existingFriends:Array<AnyObject> = try self.managedObjectContext.executeFetchRequest(f)
                        
                        if existingFriends.count != 0{
                            let friend = existingFriends.first as! NSManagedObject
                            friend.setValue(status, forKey: "status")
                        }
                        else{
                            let row = NSEntityDescription.insertNewObjectForEntityForName("Friends", inManagedObjectContext: self.managedObjectContext)
                            
                            row.setValue(id, forKey: "id")
                            row.setValue(name, forKey: "name")
                            row.setValue(portrait, forKey: "portrait")
                            row.setValue(status, forKey: "status")
                        }
                        try self.managedObjectContext.save()
                        
                        dataUpdated()
                    }catch{
                        print(error)
                    }
                }
            }
        }
    }

}

