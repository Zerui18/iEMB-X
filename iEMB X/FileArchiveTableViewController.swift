//
//  FileArchiveTableView.swift
//  iEMB X
//
//  Created by Chen Changheng on 16/9/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import UIKit
import QuickLook

class FileArchiveTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Cached Files"
        tableView.tableFooterView = UIView()
        navigationItem.largeTitleDisplayMode = .automatic
        files = try! FileManager.default.contentsOfDirectory(at: Constants.cachedFilesURL, includingPropertiesForKeys: nil, options: [])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        transitionCoordinator?.animate(alongsideTransition: {_ in
            menuViewController.presentedBoardVC.hideUIComponents()
        })
    }
    
    var files: [URL]!

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files != nil ? files.count:0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fileArchiveCell", for: indexPath) as! FileArchiveCell
        cell.update(with: files[indexPath.row])
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        do {
            try FileManager.default.removeItem(at: files[indexPath.row])
            files.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        catch {
            UIAlertController(title: "Error Deleting File", message: error.localizedDescription).present(in: self)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let ctr = FilePreviewController()
        ctr.file = files[indexPath.row]
        navigationController?.pushViewController(ctr, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 74
    }
    
}
