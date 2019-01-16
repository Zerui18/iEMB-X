//
//  Functions.swift
//  iEMB X
//
//  Created by Chen Changheng on 13/9/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import UIKit

func notificationFeedback(ofType type: UINotificationFeedbackGenerator.FeedbackType) {
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

