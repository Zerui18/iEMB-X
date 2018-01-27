//
//  Attachment+CoreDataProperties.swift
//  EMBClient
//
//  Created by Chen Zerui on 26/1/18.
//  Copyright © 2018 Chen Zerui. All rights reserved.
//
//

import Foundation
import CoreData


extension Attachment {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Attachment> {
        return NSFetchRequest<Attachment>(entityName: "Attachment")
    }

    @NSManaged public var name: String?
    @NSManaged public var typeRaw: Int16
    @NSManaged public var urlString: String?
    @NSManaged public var post: Post?

}
