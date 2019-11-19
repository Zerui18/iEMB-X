//
//  SettingsViewController.swift
//  iEMB X
//
//  Created by Chen Changheng on 11/10/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import UIKit
import CoreData
import EMBClient


var backgroungFetchInterval: TimeInterval {
    get {
        max(userDefaults.double(forKey: "bg_fetch"), 30*60)
    }
    set {
        userDefaults.set(newValue, forKey: "bg_fetch")
    }
}

// MARK: SettingsViewController
class SettingsViewController: UIViewController {
    
    // MARK: Properties
    override var prefersStatusBarHidden: Bool {
        false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        .portrait
    }
    
    var durationOptions: [TimeInterval] = [30*60, 60*60, 120*60, UIApplication.backgroundFetchIntervalNever]
    
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet var optionButtons: [UIButton]!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var linkedLabel: UITextView!

    // MARK: Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        menuViewController.tableView(menuViewController.tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
        cariocaMenu.showIndicator(position: .center, offset: 0)
    }
    
    private func setupUI() {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        
        var descriptionAttrs = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15, weight: .regular),
                                .paragraphStyle: style]
        
        if #available(iOS 13.0, *) {
            descriptionAttrs[.foregroundColor] = UIColor.secondaryLabel
        }
        else {
            descriptionAttrs[.foregroundColor] = UIColor.darkGray
        }
        
        let str = NSMutableAttributedString(string: """
        · the actual interval is usually slightly longer than this
        · you will also need to enable this in Settings
        """, attributes: descriptionAttrs)
        str.addAttribute(.link, value: NSURL(string: UIApplication.openSettingsURLString)!, range: NSRange(location: str.length-8, length: 8))
        linkedLabel.attributedText = str
        linkedLabel.delegate = self
        linkedLabel.textDragInteraction?.isEnabled = false
        
        clearButton.clipsToBounds = true
        clearButton.layer.borderColor = clearButton.currentTitleColor.cgColor
        clearButton.layer.borderWidth = 1
        clearButton.layer.cornerRadius = 7
        clearButton.addTarget(self, action: #selector(clearClicked), for: .touchUpInside)
        
        logoutButton.clipsToBounds = true
        logoutButton.layer.borderColor = logoutButton.currentTitleColor.cgColor
        logoutButton.layer.borderWidth = 1
        logoutButton.layer.cornerRadius = 7
        logoutButton.addTarget(self, action: #selector(logoutClicked), for: .touchUpInside)
        
        optionButtons.sort(by: {$0.tag < $1.tag})
        optionButtons.forEach {
            $0.clipsToBounds = true
            $0.layer.borderColor = UIColor.systemBlue.cgColor
            $0.layer.cornerRadius = 15
        }
        
        let index = durationOptions.firstIndex(of: backgroungFetchInterval)!
        showSelected(button: optionButtons[index])
    }
    
    func showSelected(button: UIButton) {
        let ani = CABasicAnimation(keyPath: #keyPath(CALayer.borderWidth))
        ani.fromValue = 0
        ani.toValue = 2
        ani.fillMode = CAMediaTimingFillMode.forwards
        ani.isRemovedOnCompletion = false
        button.layer.add(ani, forKey: nil)
        button.setTitleColor(.systemBlue, for: .normal)
    }
    
    func showDeslected(button: UIButton) {
        let ani = CABasicAnimation(keyPath: #keyPath(CALayer.borderWidth))
        ani.fromValue = 2
        ani.toValue = 0
        ani.fillMode = CAMediaTimingFillMode.forwards
        ani.isRemovedOnCompletion = false
        button.layer.add(ani, forKey: nil)
        button.setTitleColor(.systemGray, for: .normal)
    }
    
    // MARK: Selector Methods
    @IBAction func buttonSelected(_ sender: UIButton) {
        selectionFeedback()
        let prevSelected = optionButtons[durationOptions.firstIndex(of: backgroungFetchInterval)!]
        showDeslected(button: prevSelected)
        showSelected(button: sender)
        backgroungFetchInterval = durationOptions[sender.tag]
    }
    
    @IBAction func dismissVC() {
        menuViewController.tableView(menuViewController.tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
        cariocaMenu.showIndicator(position: .center, offset: 0)
        dismiss(animated: true)
    }
    
    @objc func clearClicked() {
        let alr = UIAlertController(title: "Clear Cache?", message: "this only clears the contents of the posts", preferredStyle: .actionSheet)
        alr.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alr.addAction(UIAlertAction(title: "Clear", style: .default) {_ in
            do {
                _ = try CoreDataHelper.shared.mainContext.execute(NSBatchDeleteRequest(fetchRequest: Attachment.fetchRequest()))
                EMBClient.shared.allPosts.forEach {
                    $0.value.forEach {
                        $0.content = nil
                        $0.contentData = nil
                    }
                }
                try CoreDataHelper.shared.saveContext()
            }
            catch {
                print(error)
            }
        })
        alr.present(in: self)
    }
    
    @objc func logoutClicked() {
        let alr = UIAlertController(title: "Logout?", message: "all your cached posts and files will be cleared", preferredStyle: .actionSheet)
        alr.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alr.addAction(UIAlertAction(title: "Logout", style: .destructive, handler: { _ in
            do {
                EMBUser.shared.logout()
                try EMBClient.shared.resetCache()
                for boardID in menuViewController.boardIds {
                    userDefaults.removeObject(forKey: "lastRefreshed_\(boardID)")
                }
                menuViewController.boardVCs.forEach {
                    let ctr = ($0.viewControllers[0] as! BoardTableController)
                    ctr.reset()
                }
                menuViewController.tableView(menuViewController.tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
                self.dismiss(animated: true) {
                    LoginViewController().present(in: baseViewController)
                }
            }
            catch {
                UIAlertController(title: "Error Reseting Cache", message: error.localizedDescription).present(in: self)
            }
        }))
        alr.present(in: self)
    }
}

extension SettingsViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        true
    }

}
