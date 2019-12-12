//
//  Extensions.swift
//  iEMB X
//
//  Created by Chen Changheng on 13/9/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import UIKit
import EMBClient


extension UIViewController {
    func present(in parent: UIViewController, animated: Bool = true, completion: (()->Void)? = nil) {
        parent.present(self, animated: animated, completion: completion)
    }
}

extension UIColor {
    static let information = UIColor.systemGreen
    static let important = UIColor.systemOrange
    static let urgent = UIColor.systemRed
}

extension UITableView {
    
    func visibleCell(at indexPath: IndexPath)-> UITableViewCell? {
        visibleCells.first {
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

//extension Array where Element == Post {
//    
//    /// Returns tableView indexPaths representing the posts of the given array in the receiver.
//    func indexPaths(ofPosts arr: [Post])-> [IndexPath] {
//        arr.compactMap { post in
//            self.firstIndex(of: post).flatMap { index in
//                IndexPath(row: index, section: 0)
//            }
//        }
//    }
//}
