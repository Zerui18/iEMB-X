//
//  Post+CoreDataProperties.swift
//  EMBClient
//
//  Created by Chen Zerui on 26/1/18.
//  Copyright © 2018 Chen Zerui. All rights reserved.
//
//

import Foundation
import CoreData


extension Post {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Post> {
        return NSFetchRequest<Post>(entityName: "Post")
    }

    @NSManaged public var author: String?
    @NSManaged public var board: Int64
    @NSManaged public var canReply: Bool
    @NSManaged public var contentData: NSData?
    @NSManaged public var date: String?
    @NSManaged public var id: Int64
    @NSManaged public var importanceString: String?
    @NSManaged public var isMarked: Bool
    @NSManaged public var isRead: Bool
    @NSManaged public var responseContent: String?
    @NSManaged public var responseOption: String?
    @NSManaged public var title: String?
    @NSManaged public var attachments: NSSet?

}

// MARK: Generated accessors for attachments
extension Post {

    @objc(addAttachmentsObject:)
    @NSManaged public func addToAttachments(_ value: Attachment)

    @objc(removeAttachmentsObject:)
    @NSManaged public func removeFromAttachments(_ value: Attachment)

    @objc(addAttachments:)
    @NSManaged public func addToAttachments(_ values: NSSet)

    @objc(removeAttachments:)
    @NSManaged public func removeFromAttachments(_ values: NSSet)

}
