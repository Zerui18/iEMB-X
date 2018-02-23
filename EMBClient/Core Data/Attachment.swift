//
//  LinkedFile.swift
//  iEMB X
//
//  Created by Chen Changheng on 16/9/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import CoreData

@objc(Attachment)
public class Attachment: NSManagedObject {
    
    public enum AttachmentType: Int16 {
        case file = 0, embedding = 1
    }
    
    convenience public init(url: URL, name: String, type: AttachmentType) {
        self.init(entity: NSEntityDescription.entity(forEntityName: "Attachment", in: CoreDataHelper.shared.mainContext)!, insertInto: CoreDataHelper.shared.mainContext)
        self.urlString = url.absoluteString
        self.name = name
        self.type = type
    }
    
    public var type: AttachmentType {
        get {
            return AttachmentType(rawValue: typeRaw)!
        }
        set {
            typeRaw = newValue.rawValue
        }
    }
    
    public var url: URL {
        return URL(string: self.urlString!)!
    }
    
    public var cacheURL: URL {
        return cachedFilesURL.appendingPathComponent("\(post!.board)-\(post!.id)-"+self.name!)
    }
    
    public var isDownloaded: Bool {
        return FileManager.default.fileExists(atPath: cacheURL.path)
    }
    
    private var downloader: Downloader?
    
    public func download(progress: @escaping (Double)->Void, completion: @escaping (Error?)-> Void) {
        if isDownloaded {
            completion(nil)
        }
        else {
            EMBClient.shared.reLogin { (_, err) in
                if err != nil {
                    completion(err)
                }
                else {
                    self.downloader = Downloader.download(file: self, progress: progress, completion: completion)
                }
            }
        }
    }
    
    public static func ==(_ lhs: Attachment, _ rhs: Attachment)-> Bool {
        return lhs.url == rhs.url
    }
}
