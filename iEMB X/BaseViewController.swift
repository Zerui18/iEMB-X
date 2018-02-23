//
//  BaseViewController.swift
//  iEMB X
//
//  Created by Chen Changheng on 6/10/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import UIKit

class BaseViewController: UIViewController {
    
    let imageView = UIImageView(image: #imageLiteral(resourceName: "hci_light"))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let (w, h) = (view.bounds.width, view.bounds.height)
        
        imageView.frame = CGRect(x: 0, y: 0, width: min(w, h), height: max(w, h))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: imageView.bounds.width/imageView.bounds.height).isActive = true
        imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        view.layoutIfNeeded()
    }
}
