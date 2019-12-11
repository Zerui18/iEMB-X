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
    
    var files: [URL]!
    lazy var clearButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(clearPressed))

    // MARK: Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Cached Files"
        tableView.tableFooterView = UIView()
        navigationItem.largeTitleDisplayMode = .automatic
        navigationItem.rightBarButtonItem = clearButton
        updateUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        transitionCoordinator?.animate(alongsideTransition: {_ in
            menuViewController.presentedBoardVC.hideUIComponents()
        })
    }
    
    func updateUI() {
        files = try! FileManager.default.contentsOfDirectory(at: Constants.cachedFilesURL, includingPropertiesForKeys: nil, options: [])
        tableView.reloadData()
    }

    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        files != nil ? files.count:0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fileArchiveCell", for: indexPath) as! FileArchiveCell
        cell.update(with: files[indexPath.row])
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .delete
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
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
        74
    }
    
    // MARK: Selector Methods
    @objc private func clearPressed() {
        let alr = UIAlertController(title: "Clear Files?", message: "this will delete all cached files", preferredStyle: UIDevice.current.userInterfaceIdiom != .pad ? .actionSheet:.alert)
        alr.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alr.addAction(UIAlertAction(title: "Clear", style: .destructive) {_ in
            for file in self.files {
                try? FileManager.default.removeItem(at: file)
                self.updateUI()
            }
        })
        alr.present(in: self)
    }
    
}
