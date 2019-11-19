//
//  FilePreviewController.swift
//  iEMB X
//
//  Created by Chen Changheng on 23/9/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import UIKit
import QuickLook

class FilePreviewController: QLPreviewController, QLPreviewControllerDataSource {
    
    override var prefersStatusBarHidden: Bool {
        true
    }
        
    var file: URL!
    var deletesFileOnDismiss = false

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        dataSource = self
    }

    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        file as NSURL
    }
    
    deinit {
        if deletesFileOnDismiss {
            try? FileManager.default.removeItem(at: file)
        }
    }

}
