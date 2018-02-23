//
//  Interactor.swift
//  iEMB X
//
//  Created by Chen Changheng on 3/10/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import UIKit

fileprivate let completionFraction: CGFloat = 0.45

class Interactor: UIPercentDrivenInteractiveTransition {
    
    var hasStarted = false
    var shouldFinish = false
    
    override func update(_ percentComplete: CGFloat) {
        super.update(percentComplete)
        shouldFinish = percentComplete > completionFraction
    }
    
    func complete(extraCondition condition: Bool = false) -> Bool {
        guard hasStarted else {
            return false
        }
        
        defer {
            // clean states before return
            hasStarted = false
            shouldFinish = false
        }
        
        if shouldFinish || condition {
            finish()
            return true
        }
        else {
            cancel()
            return false
        }
    }
    
}
