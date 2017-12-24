//
//  LinkedFile.swift
//  iEMB X
//
//  Created by Chen Changheng on 16/9/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import CoreData

@objc(Attachment)
class Attachment: NSManagedObject{
    
    enum AttachmentType: Int16{
        case file = 0, embed = 1
    }
    
    convenience init(url: URL, name: String, type: AttachmentType, post: Post){
        self.init(entity: NSEntityDescription.entity(forEntityName: "Attachment", in: context)!, insertInto: context)
        self.urlString = url.absoluteString
        self.name = name
        self.type = type
        self.post = post
    }
    
    var type: AttachmentType{
        get{
            return AttachmentType(rawValue: typeRaw)!
        }
        set{
            typeRaw = newValue.rawValue
        }
    }
    
    var url: URL{
        return self.urlString!.toURL!
    }
    
    var cacheURL: URL{
        return Constants.cachedFilesURL.appendingPathComponent("\(post!.board)-\(post!.id)-"+self.name!)
    }
    
    var isDownloaded: Bool{
        return FileManager.default.fileExists(atPath: cacheURL.path)
    }
    
    var downloader: Downloader?
    
    func download(progress: @escaping (Double)->Void, completion: @escaping (Error?)-> Void){
        if isDownloaded{
            completion(nil)
        }
        else{
            EMBReader.reLogin(then: { (_, err) in
                if err != nil{
                    completion(err)
                }
                else{
                    self.downloader = Downloader.download(file: self, progress: progress, completion: completion)
                }
            })
        }
    }
    
    static func ==(_ lhs: Attachment, _ rhs: Attachment)-> Bool{
        return lhs.url == rhs.url
    }
}
