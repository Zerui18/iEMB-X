//
//  Attachment+CoreDataProperties.swift
//  iEMB X
//
//  Created by Chen Changheng on 17/10/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//
//

import Foundation
import CoreData


extension Attachment {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Attachment> {
        return NSFetchRequest<Attachment>(entityName: "Attachment")
    }

    @NSManaged public var name: String?
    @NSManaged public var urlString: String?
    @NSManaged public var typeRaw: Int16
    @NSManaged public var post: Post?

}
