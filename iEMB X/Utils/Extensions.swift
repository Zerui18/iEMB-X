//
//  Extensions.swift
//  iEMB X
//
//  Created by Chen Changheng on 13/9/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import UIKit
import Foundation

extension String{
    var toURL: URL?{
        return URL(string: self)
    }
    var toInt: Int?{
        return Int(self)
    }
    
    var removingHTMLEncoding: String{
        var result = self
        for (enc, ori) in Constants.htmlEscaped{
            result = result.replacingOccurrences(of: enc, with: ori)
        }
        return result
    }
}

infix operator ~
func ~(_ lhs: String, _ rhs: NSRegularExpression)-> NSTextCheckingResult?{
    return rhs.firstMatch(in: lhs, options: [], range: NSRange.init(location: 0, length: lhs.count))
}

extension UIViewController{
    func present(in parent: UIViewController, animated: Bool = true, completion: (()->Void)? = nil){
        parent.present(self, animated: animated, completion: completion)
    }
}

extension UIColor{
    static let information = #colorLiteral(red: 0.3882352941, green: 0.8549019608, blue: 0.2196078431, alpha: 1)
    static let important = #colorLiteral(red: 1, green: 0.5843137255, blue: 0, alpha: 1)
    static let urgent = #colorLiteral(red: 1, green: 0.231372549, blue: 0.1882352941, alpha: 1)
}

extension UITableView{
    
    func visibleCell(at indexPath: IndexPath)-> UITableViewCell?{
        return visibleCells.first{
            self.indexPath(for: $0) == indexPath
        }
    }
    
}

extension UIView{
    
    func animateHidden(duration: TimeInterval = 0.3){
        if alpha != 0{
            alpha = 1
            isHidden = false
            UIView.animate(withDuration: duration, animations: {
                self.alpha = 0
            }){_ in
                self.isHidden = true
            }
        }
    }
    
    func animateVisible(duration: TimeInterval = 0.3){
        if alpha != 1{
            alpha = 0
            isHidden = false
            UIView.animate(withDuration: duration, animations: {
                self.alpha = 1
            })
        }
    }
}

extension NSAttributedString{
    func enumerateAttribute(named attrName: NSAttributedStringKey, block: (Any?, NSRange, UnsafeMutablePointer<ObjCBool>)-> Void){
        enumerateAttribute(attrName, in: NSMakeRange(0, length), options: [], using: block)
    }
}
