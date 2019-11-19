//
//  FileCell.swift
//  iEMB X
//
//  Created by Chen Changheng on 15/9/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import UIKit
import EMBClient

class FileCell: UITableViewCell {
    
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    func update(with attachment: Attachment) {
        titleLabel.text = attachment.name
        if attachment.type == .file {
            iconView.image = Constants.fileIcon(for: attachment.name!)
        }
        else {
            iconView.image = #imageLiteral(resourceName: "link")
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = nil
        let view = UIView()
        if #available(iOS 13.0, *) {
            view.backgroundColor = .secondarySystemFill
        } else {
            view.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        }
        selectedBackgroundView = view
        selectedBackgroundView?.clipsToBounds = true
        selectedBackgroundView?.layer.cornerRadius = 7
    }
    
}
