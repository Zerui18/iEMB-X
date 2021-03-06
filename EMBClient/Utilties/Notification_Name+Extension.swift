//
//  Notification_Name+Extension.swift
//  EMBClient
//
//  Created by Chen Zerui on 26/1/18.
//  Copyright © 2018 Chen Zerui. All rights reserved.
//

import Foundation

public extension Notification.Name {
    
    static let postIsReadUpdated = Notification.Name("PostIsReadUpdatedNotification")
    
    static let embLoginCredentiaInvalidated = Notification.Name("EMBLoginCredentialsInvalidatedNotification")
    
}
