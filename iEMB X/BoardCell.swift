//
//  BoardCell.swift
//  iEMB X
//
//  Created by Chen Changheng on 21/9/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import UIKit

fileprivate let highlightedColor = UIColor.systemBlue.withAlphaComponent(0.8)
fileprivate let selectedColor = UIColor.systemBlue

fileprivate let heavyFont = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.heavy)
fileprivate let normalFont = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.medium)

class BoardCell: UITableViewCell {

    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    func applySelectedStyle(_ isPreselect: Bool = false) {
        if isPreselect {
            iconView.tintColor = highlightedColor
            titleLabel.textColor = highlightedColor
        }
        else {
            titleLabel.font = heavyFont
            iconView.tintColor = selectedColor
            titleLabel.textColor = selectedColor
        }
    }
    
    func applyNormalStyle() {
        if #available(iOS 13.0, *) {
            iconView.tintColor = .systemGray
            titleLabel.textColor = .systemGray
        } else {
            iconView.tintColor = .gray
            titleLabel.textColor = .gray
        }
        
        titleLabel.font = normalFont
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
    }
    
}
