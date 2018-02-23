//
//  FileArchiveCell.swift
//  iEMB X
//
//  Created by Chen Changheng on 16/9/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import UIKit

class FileArchiveCell: UITableViewCell {

    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    func update(with file: URL) {
        iconView.image = Constants.fileIcon(for: file.lastPathComponent)
        titleLabel.text = file.lastPathComponent
    }

}
