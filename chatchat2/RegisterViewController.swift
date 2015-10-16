//
//  RegisterViewController.swift
//  chatchat2
//
//  Created by Tony Shi on 15/10/5.
//  Copyright © 2015年 Tony Shi. All rights reserved.
//

import UIKit
import CoreData
import Alamofire
import MBProgressHUD

class RegisterViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet weak var portraitCollectionView: UICollectionView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var genderSegmentControl: UISegmentedControl!
    @IBOutlet weak var okBtn: UIButton!
    @IBOutlet weak var descTextView: UITextView!
    
    var keyboardShown: Bool = false
    
    @IBAction func registerBtnTapped(sender: AnyObject) {
        let loadingNotification = MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        loadingNotification.mode = MBProgressHUDMode.Indeterminate
        loadingNotification.labelText = "注册中"
        
        let name = self.nameTextField.text
        let gender = ["M", "F", "U"][self.genderSegmentControl.selectedSegmentIndex]
        let portrait = "portrait-\((self.portraitCollectionView.indexPathsForSelectedItems()?.first?.row)!+1)"
        let desc = self.descTextView.text
        
        let parameters:Dictionary<String,String> = ["username": name!, "gender": gender, "portrait_url": portrait, "desc": desc]
        
        let url = "\(server_path)/api/v1/user/register"
        Alamofire.request(.POST, url, parameters: parameters, encoding: .JSON).responseJSON() {
            (request, response, data) in
            if data.isFailure{
                MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
                
                let alertController = UIAlertController(title: "提示", message: "注册失败!", preferredStyle: UIAlertControllerStyle.Alert)
                let okAction = UIAlertAction(title: "确定", style: UIAlertActionStyle.Default, handler: nil)
                alertController.addAction(okAction)
                
                self.presentViewController(alertController, animated: true, completion: nil)
            }
            else{
                let value = data.value! as! NSDictionary
                let id = value.valueForKey("id") as! Int
                
                currentUser = UserModel(id: String(id), name: name!, portraitURL: portrait)
                currentUser!.gender = gender
                
                let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
                
                do{
                    let row = NSEntityDescription.insertNewObjectForEntityForName("User", inManagedObjectContext: context)
                    
                    row.setValue(currentUser?.id, forKey: "id")
                    row.setValue(currentUser?.name, forKey: "name")
                    row.setValue(currentUser?.portraitURL, forKey: "portrait")
                    row.setValue(currentUser?.gender, forKey: "gender")
                    row.setValue(currentUser?.desc, forKey: "desc")
                    
                    try context.save()
                }catch{
                    print(error)
                }
                
                MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
                
                self.performSegueWithIdentifier("GoToMain", sender: self)
            }
        }
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 12
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = self.portraitCollectionView.dequeueReusableCellWithReuseIdentifier("portraitCell", forIndexPath: indexPath) as UICollectionViewCell
        let portait = cell.viewWithTag(3001) as! UIImageView
        portait.image = UIImage(named: "portrait-\(indexPath.row + 1)")
        
        let selectedView = UIView()
        selectedView.backgroundColor = UIColor.greenColor()
        cell.selectedBackgroundView = selectedView
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.nameTextField.delegate = self
        self.descTextView.delegate = self
        
        self.portraitCollectionView.dataSource = self
        self.portraitCollectionView.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func keyboardToggled(keyboardShown: Bool) {
        self.keyboardShown = keyboardShown
        
        let animationDuration:NSTimeInterval = 0.8
        var frame = self.view.frame;
        if keyboardShown == true {
            frame.origin.y = frame.origin.y - 216;
            frame.size.height = frame.size.height + 216;
        }
        else{
            frame.origin.y = frame.origin.y + 216;
            frame.size.height = frame.size.height - 216;
        }
        self.view.frame = frame;
        
        UIView.beginAnimations("ResizeView", context: nil)
        UIView.setAnimationDuration(animationDuration)
        self.view.frame = frame
        UIView.commitAnimations()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        keyboardToggled(false)
        
        self.nameTextField.resignFirstResponder()

        return true
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        
        if self.keyboardShown == true{
            keyboardToggled(false)
        }
        keyboardToggled(true)
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        
        
        if self.keyboardShown == true{
            keyboardToggled(false)
        }
        keyboardToggled(true)
    }
    
    func textViewShouldEndEditing(textView: UITextView) -> Bool {
        keyboardToggled(false)
        
        self.descTextView.resignFirstResponder()
        
        return true
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.nameTextField.resignFirstResponder()
        self.descTextView.resignFirstResponder()
        
        if self.keyboardShown == true{
            keyboardToggled(false)
        }
    }
}
