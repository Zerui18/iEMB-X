//
//  Functions.swift
//  iEMB X
//
//  Created by Chen Changheng on 13/9/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import UIKit

func simpleAlert(title: String, message: String, block: ((UIAlertAction)->Void)? = nil)-> UIAlertController {
    let al = UIAlertController(title: title, message: message, preferredStyle: .alert)
    al.addAction(UIAlertAction(title: "OK", style: .cancel, handler: block))
    return al
}

func notificationFeedback(ofType type: UINotificationFeedbackType = .success) {
    DispatchQueue.main.async {
        notificationFeedbackGenerator.notificationOccurred(type)
        notificationFeedbackGenerator.prepare()
    }
}

func selectionFeedback() {
    DispatchQueue.main.async {
        selectionFeedbackGenerator.selectionChanged()
        selectionFeedbackGenerator.prepare()
    }
}

