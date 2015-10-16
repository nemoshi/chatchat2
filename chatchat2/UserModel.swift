//
//  UserModel.swift
//  chatchat2
//
//  Created by Tony Shi on 15/9/29.
//  Copyright © 2015年 Tony Shi. All rights reserved.
//

import UIKit

class UserModel: NSObject {

    var id: String
    var name: String
    var portraitURL: String?
    var phoneNumber: String?
    var gender: String?
    var desc: String?
    
    init(id: String, name: String, portraitURL: String,
        phoneNumber: String = "",
        gender: String = "U",
        desc: String = "这家伙很懒，什么都没有留下..."){
        self.id = id
        self.name = name
        self.portraitURL = portraitURL
        self.phoneNumber = phoneNumber
        self.gender = gender
        self.desc = desc
    }
}
