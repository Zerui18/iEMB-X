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
    
    func complete(extraCondition condition: Bool = false){
        if hasStarted{
            if shouldFinish || condition{
                finish()
            }
            else{
                cancel()
            }
            hasStarted = false
            shouldFinish = false
        }
    }
    
}
