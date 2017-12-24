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
        imageView.frame = view.bounds
        view.addSubview(imageView)
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
}
