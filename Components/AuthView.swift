//
//  AuthView.swift
//  Components
//
//  Created by Chen Zerui on 4/5/18.
//  Copyright © 2018 Chen Zerui. All rights reserved.
//

import UIKit

/// Text input view containing a left icon, a textfield, and an animating underscore.
public class AuthView: UIView, UITextFieldDelegate{
    
    // MARK: Public Properties
    public var icon: UIImage? {
        get {
            return iconView.image
        }
        set {
            iconView.image = newValue
        }
    }
    
    public var placeholder: String? {
        didSet {
            textField.attributedPlaceholder = NSAttributedString(string: placeholder!, attributes: [.font: UIFont.systemFont(ofSize: 18), .foregroundColor: UIColor.white])
        }
    }
    
    public var text: String? {
        return textField.text
    }
    
    public var nextView: AuthView? {
        didSet {
            if nextView != nil {
                textField.returnKeyType = .next
            }
            else {
                textField.returnKeyType = .done
            }
        }
    }
    
    public var isSecureTextEntry: Bool {
        get {
            return textField.isSecureTextEntry
        }
        set {
            textField.isSecureTextEntry = newValue
        }
    }
    
    // MARK: Private Properties
    private let iconView = UIImageView(frame: .zero)
    private let textField = UITextField(frame: .zero)
    private let lineLayer = CAShapeLayer()
    
    
    // MARK: Public Init
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        iconView.translatesAutoresizingMaskIntoConstraints = false
        textField.translatesAutoresizingMaskIntoConstraints = false
        
        textField.textColor = .white
        textField.tintColor = .white
        textField.returnKeyType = .done
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.font = .systemFont(ofSize: 20)
        
        addSubview(iconView)
        addSubview(textField)
        
        iconView.topAnchor.constraint(equalTo: topAnchor, constant: 4).isActive = true
        iconView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6).isActive = true
        iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2).isActive = true
        iconView.widthAnchor.constraint(equalTo: iconView.heightAnchor, multiplier: 1).isActive = true
        
        textField.topAnchor.constraint(equalTo: topAnchor, constant: 4).isActive = true
        textField.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4).isActive = true
        textField.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 4).isActive = true
        textField.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        lineLayer.strokeColor = UIColor.white.cgColor
        lineLayer.lineWidth = 1
        layer.addSublayer(lineLayer)
        
        textField.addTarget(self, action: #selector(editStateChanged), for: .editingDidBegin)
        textField.addTarget(self, action: #selector(editStateChanged), for: .editingDidEnd)
        textField.delegate = self
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Public Methods
    public override func layoutSubviews() {
        super.layoutSubviews()
        let line = UIBezierPath()
        line.move(to: CGPoint(x: 0, y: bounds.height - 1))
        line.addLine(to: CGPoint(x: bounds.width, y: bounds.height - 1))
        lineLayer.path = line.cgPath
    }
    
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if nextView != nil {
            nextView!.textField.becomeFirstResponder()
        }
        else {
            textField.resignFirstResponder()
        }
        return true
    }
    
    // MARK: Objc Methods
    @objc private func editStateChanged() {
        lineLayer.lineWidth = textField.isEditing ? 2:1
    }
    
}
