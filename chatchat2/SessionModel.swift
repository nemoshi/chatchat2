//
//  SessionModel.swift
//  chatchat2
//
//  Created by Tony Shi on 15/9/29.
//  Copyright © 2015年 Tony Shi. All rights reserved.
//

import UIKit

class SessionModel: NSObject {

    var id: String
    var name: String
    var portraitURL: String
    var type: String
    var lastMsg: String?
    
    init(id: String, name: String, portraitURL: String, type: String, lastMsg: String = ""){
        self.id = id
        self.name = name
        self.portraitURL = portraitURL
        self.type = type
        self.lastMsg = lastMsg
    }
}
