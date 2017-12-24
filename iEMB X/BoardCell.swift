//
//  BoardCell.swift
//  iEMB X
//
//  Created by Chen Changheng on 21/9/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import UIKit

fileprivate let highlightedColor = UIColor(red:0.46, green:0.82, blue:0.89, alpha:1)
fileprivate let selectedColor = UIColor(red:0.07, green:0.73, blue:0.86, alpha:1)

fileprivate let heavyFont = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.heavy)
fileprivate let normalFont = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.medium)

class BoardCell: UITableViewCell {

    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    func applySelectedStyle(_ isPreselect: Bool = false){
        if isPreselect{
            iconView.tintColor = highlightedColor
            titleLabel.textColor = highlightedColor
        }
        else{
            titleLabel.font = heavyFont
            iconView.tintColor = selectedColor
            titleLabel.textColor = selectedColor
        }
    }
    
    func applyNormalStyle(){
        iconView.tintColor = #colorLiteral(red: 0.6300531826, green: 0.6300531826, blue: 0.6300531826, alpha: 1)
        titleLabel.textColor = #colorLiteral(red: 0.6300531826, green: 0.6300531826, blue: 0.6300531826, alpha: 1)
        titleLabel.font = normalFont
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
    }
    
}
