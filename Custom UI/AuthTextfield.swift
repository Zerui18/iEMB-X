//
//  AuthTextfield.swift
//  Custom UI
//
//  Created by Chen Changheng on 27/9/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import UIKit

@IBDesignable
class AuthTextfield: UITextField {
    
    @IBInspectable var lineLengthRatio: CGFloat = 0.8
    @IBInspectable var lineYOffset: CGFloat = 3
    @IBInspectable var lineColor: UIColor = .white
    @IBInspectable var lineWidth: CGFloat = 1
    
    @IBInspectable var placeHolderColor: UIColor = .white
    
    let linePath = UIBezierPath()
    
    var isActive = false
    
    private func strokeLine(){
        linePath.lineWidth = isActive ? lineWidth*1.5:lineWidth
        (isActive ? lineColor:lineColor.withAlphaComponent(0.7)).setStroke()
        linePath.lineCapStyle = .round
        
        let yPoint = bounds.height-lineYOffset
        linePath.move(to: CGPoint(x: 0, y: yPoint))
        linePath.addLine(to: CGPoint(x: bounds.width*lineLengthRatio, y: yPoint))
        linePath.stroke()
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        strokeLine()
        attributedPlaceholder = NSAttributedString(string: placeholder ?? "", attributes: [.foregroundColor: (isActive ? lineColor:lineColor.withAlphaComponent(0.7))])
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        borderStyle = .none
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        borderStyle = .none
    }
    
    override func resignFirstResponder() -> Bool {
        isActive = false
        setNeedsDisplay()
        return super.resignFirstResponder()
    }
    
    override func becomeFirstResponder() -> Bool {
        isActive = true
        setNeedsDisplay()
        return super.becomeFirstResponder()
    }

}
