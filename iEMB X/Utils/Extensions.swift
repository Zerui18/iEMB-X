//
//  Extensions.swift
//  iEMB X
//
//  Created by Chen Changheng on 13/9/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import UIKit
import Foundation


extension UIViewController {
    func present(in parent: UIViewController, animated: Bool = true, completion: (()->Void)? = nil) {
        parent.present(self, animated: animated, completion: completion)
    }
}

extension UIColor {
    static let information = #colorLiteral(red: 0.3882352941, green: 0.8549019608, blue: 0.2196078431, alpha: 1)
    static let important = #colorLiteral(red: 1, green: 0.5843137255, blue: 0, alpha: 1)
    static let urgent = #colorLiteral(red: 1, green: 0.231372549, blue: 0.1882352941, alpha: 1)
}

extension UITableView {
    
    func visibleCell(at indexPath: IndexPath)-> UITableViewCell? {
        return visibleCells.first {
            self.indexPath(for: $0) == indexPath
        }
    }
    
}

extension UIView {
    
    func animateHidden(duration: TimeInterval = 0.3) {
        if alpha != 0 {
            alpha = 1
            isHidden = false
            UIView.animate(withDuration: duration, animations: {
                self.alpha = 0
            }) {_ in
                self.isHidden = true
            }
        }
    }
    
    func animateVisible(duration: TimeInterval = 0.3) {
        if alpha != 1 {
            alpha = 0
            isHidden = false
            UIView.animate(withDuration: duration, animations: {
                self.alpha = 1
            })
        }
    }
}

extension UIAlertController {
    
    /**
     Initlialize an UIAlertController instance with title, message and an action of title "OK" and type "cancel". Additionally specify a block to be executed on dismissal.
     */
    convenience init(title: String, message: String, onDismiss handler: (() -> Void)? = nil) {
        self.init(title: title, message: message, preferredStyle: .alert)
        
        addAction(UIAlertAction(title: "OK", style: .cancel){_ in handler?()})
    }
    
}

infix operator =>

func =>(_ obj: Any, _ typeClass: AnyClass) -> Bool {
    return type(of: obj) == typeClass
}
