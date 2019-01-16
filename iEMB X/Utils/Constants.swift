//
//  Global.swift
//  iEMB X
//
//  Created by Chen Changheng on 13/9/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import UIKit
import CoreData

struct Constants {
    
    static let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
    
    
    static var initializedFileIcons: [String:UIImage] = [
        "jpg"   :   #imageLiteral(resourceName: "jpg"),
        "jpeg"  :   #imageLiteral(resourceName: "jpg"),
        "png"   :   #imageLiteral(resourceName: "png"),
        "pdf"   :   #imageLiteral(resourceName: "pdf"),
        "doc"   :   #imageLiteral(resourceName: "doc"),
        "docx"  :   #imageLiteral(resourceName: "doc"),
        "ppt"   :   #imageLiteral(resourceName: "ppt"),
        "pptx"  :   #imageLiteral(resourceName: "ppt"),
        "xls"   :   #imageLiteral(resourceName: "xls"),
        "xlsx"  :   #imageLiteral(resourceName: "xls")
    ]
    
    static func fileIcon(for fileName: String)-> UIImage {
        let ext = (fileName.components(separatedBy: ".").last ?? "").lowercased()
        return initializedFileIcons[ext] ?? #imageLiteral(resourceName: "file")
    }
    
    static let presentTransitionDuration: TimeInterval = 0.45
    static let dismissTransitionDuraction: TimeInterval = 0.65
    
    static let idToBoardName = [1048 : "Student",
                                1049 : "PSB",
                                1039 : "Service",
                                1050 : "Lost & Found"]
    
    static let cachedFilesURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Files")
    
}

let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
let selectionFeedbackGenerator = UISelectionFeedbackGenerator()

let userDefaults = UserDefaults.standard
