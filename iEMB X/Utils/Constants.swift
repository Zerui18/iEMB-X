//
//  Global.swift
//  iEMB X
//
//  Created by Chen Changheng on 13/9/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import UIKit
import CoreData

struct Constants{
    
    static let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
    
    static let cachedFilesURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Files")
    
    static let loginURL = "https://iemb.hci.edu.sg/home/login".toURL!
    static let boardBaseURL = "https://iemb.hci.edu.sg/Board/Detail".toURL!
    
    static func boardURLFor(id: Int)-> URL{
        return boardBaseURL.appendingPathComponent(String(id))
    }
    
    static let idToBoardName = [1048:"Student",1049:"PSB",1039:"Service",1050:"Lost & Found",1053:"Let's Serve"]
    
    static let unreadTableStart = "id=\"tab_table\" name=\"bottomTable\" class=\"tablesorter\">"
    static let readTableStart = "id=\"tab_table1\" name=\"bottomTable\" class=\"tablesorter\">"
    static let tableEnd = "</table>"
    
    static let dateRegex = try! NSRegularExpression(pattern: "([0-9]+-[A-Z][a-z]{2}-[0-9]+)", options: [])
    static let authorRegex = try! NSRegularExpression(pattern: "tooltip-data=\"(.+?)\"", options: [])
    static let importanceRegex = try! NSRegularExpression(pattern: "([ABC])<\\/span>", options: [])
    static let contentRegex = try! NSRegularExpression(pattern: "<a\\s+href=\"\\/Board\\/content\\/([0-9]*)\\?board=([0-9]+)\".+?>(.+?)<\\/a>", options: [])
    static let fileRegex = try! NSRegularExpression(pattern: "addConfirmedChild\\('attaches','([^']+)','([0-9]+)',false,([0-9]+),([0-9])\\)", options: [])
    static let iframeRegex = try! NSRegularExpression(pattern: "<iframe[^>]+src=\"([^\"]+)", options: [])
    
    static let iframeRemovalRegex = try! NSRegularExpression(pattern: "<iframe.+?<\\/iframe>", options: .dotMatchesLineSeparators)
    
    static let htmlEscaped = ["&amp;"     :   "&",
                              "&gt;"      :   ">",
                              "&lt;"      :   "<",
                              "&quot;"    :   "\"",
                              "&#39;"     :   "'"]
    
    
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
    
    static func fileIcon(for fileName: String)-> UIImage{
        let ext = (fileName.components(separatedBy: ".").last ?? "").lowercased()
        return initializedFileIcons[ext] ?? #imageLiteral(resourceName: "file")
    }
    
    static let transitionDuraction: TimeInterval = 0.44
    
}


fileprivate var storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("PostRecords.sqlite")

fileprivate var storeDescription: NSPersistentStoreDescription = {
    let description = NSPersistentStoreDescription(url: storeURL)
    return description
}()

fileprivate var storeContainer: NSPersistentContainer = {
    let container = NSPersistentContainer(name: "PostRecords")
    container.persistentStoreDescriptions = [storeDescription]
    container.loadPersistentStores { (storeDescription, error) in
        if let error = error {
            fatalError("Unresolved error \(error)")
        }
    }
    return container
}()

var context: NSManagedObjectContext = storeContainer.viewContext

let userDefaults = UserDefaults.standard

let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
let selectionFeedbackGenerator = UISelectionFeedbackGenerator()


