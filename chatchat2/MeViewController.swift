//
//  MeViewController.swift
//  chatchat2
//
//  Created by Tony Shi on 15/10/5.
//  Copyright © 2015年 Tony Shi. All rights reserved.
//

import UIKit

class MeViewController: UIViewController {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descTextView: UITextView!
    @IBOutlet weak var genderImageView: UIImageView!
    @IBOutlet weak var portraitImageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.descTextView.text = currentUser?.desc
        
        self.genderImageView.image = UIImage(named: "gender-\((currentUser?.gender!.lowercaseString)!)-25")
        self.nameLabel.text = currentUser?.name
        self.portraitImageView.image = UIImage(named: currentUser!.portraitURL!)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
