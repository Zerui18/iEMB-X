//
//  PostCell.swift
//  iEMB X
//
//  Created by Chen Changheng on 13/9/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import UIKit
import EMBClient

fileprivate let systemFontNormal = UIFont.systemFont(ofSize: 20, weight: .regular)
fileprivate let systemFontHeavy = UIFont.systemFont(ofSize: 20, weight: .semibold)

class PostCell: UITableViewCell {
    
    @IBOutlet weak var visualEffectContainer: UIVisualEffectView!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var starIconWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var importanceBanner: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    

    func updateWith(post: Post) {
        showDeselection()
        authorLabel.text = post.author
        dateLabel.text = post.date
        switch post.importance {
        case .important: importanceBanner.backgroundColor = .important
        case .urgent: importanceBanner.backgroundColor = .urgent
        case .information: importanceBanner.backgroundColor = .information
        }
        starIconWidthConstraint.constant = post.isMarked ? 23:0
        titleLabel.attributedText = NSAttributedString(string: post.title!, attributes: [NSAttributedString.Key.font:(post.isRead ? systemFontNormal:systemFontHeavy)])
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        visualEffectContainer.layer.cornerRadius = 7
        
        // fallback for older iOS since .material blur style is unavailable
        guard #available(iOS 13, *) else {
            visualEffectContainer.effect = UIBlurEffect(style: .extraLight)
            return
        }
    }
    
    func showSelection() {
        self.visualEffectContainer.contentView.backgroundColor = self.importanceBanner.backgroundColor!.withAlphaComponent(0.5)
    }
    
    func showDeselection() {
        self.visualEffectContainer.contentView.backgroundColor = nil
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        UIView.animate(withDuration: 0.3) {
            self.showSelection()
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        UIView.animate(withDuration: 0.3) {
            self.showDeselection()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        UIView.animate(withDuration: 0.3) {
            self.showDeselection()
        }
    }

}
