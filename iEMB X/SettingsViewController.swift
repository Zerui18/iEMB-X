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
        return max(userDefaults.double(forKey: "bg_fetch"), 30*60)
    }
    set {
        userDefaults.set(newValue, forKey: "bg_fetch")
    }
}

class SettingsViewController: UIViewController {
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    @IBOutlet var buttons: [UIButton]!
    @IBOutlet weak var clearButton: UIButton!
    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var linkedLabel: UITextView!
    
    var durs: [TimeInterval] = [30*60, 60*60, 120*60, UIApplicationBackgroundFetchIntervalNever]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        
        let str = NSMutableAttributedString(string: """
        · the actual interval is usually slightly longer than this
        · you will also need to enable this in Settings
        """, attributes: [.font:UIFont.systemFont(ofSize: 15, weight: .regular), .paragraphStyle: style])
        str.addAttribute(.link, value: NSURL(string: UIApplicationOpenSettingsURLString)!, range: NSRange(location: str.length-8, length: 8))
        linkedLabel.attributedText = str
        linkedLabel.delegate = self
        if #available(iOS 11, *) {
            linkedLabel.textDragInteraction?.isEnabled = false
        }
        
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
        
        buttons.sort(by: {$0.tag < $1.tag})
        buttons.forEach {
            $0.clipsToBounds = true
            $0.layer.borderColor = #colorLiteral(red: 0.1058823529, green: 0.6784313725, blue: 0.9725490196, alpha: 1).cgColor
            $0.layer.cornerRadius = 15
        }
        
        let index = durs.index(of: backgroungFetchInterval)!
        showSelected(button: buttons[index])
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
                    ctr.searchController.isActive = false
                    ctr.isFilteringThroughSearch = false
                    ctr.tableView.reloadData()
                }
                menuViewController.tableView(menuViewController.tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
                self.dismiss(animated: true) {
                    self.storyboard!.instantiateViewController(withIdentifier: "loginVC").present(in: baseViewController)
                }
            }
            catch {
                simpleAlert(title: "Error Reseting Cache", message: error.localizedDescription).present(in: self)
            }
        }))
        alr.present(in: self)
    }
    
    func showSelected(button: UIButton) {
        let ani = CABasicAnimation(keyPath: #keyPath(CALayer.borderWidth))
        ani.fromValue = 0
        ani.toValue = 2
        ani.fillMode = kCAFillModeForwards
        ani.isRemovedOnCompletion = false
        button.layer.add(ani, forKey: nil)
        button.setTitleColor(#colorLiteral(red: 0.1058823529, green: 0.6784313725, blue: 0.9725490196, alpha: 1), for: .normal)
    }
    
    func showDeslected(button: UIButton) {
        let ani = CABasicAnimation(keyPath: #keyPath(CALayer.borderWidth))
        ani.fromValue = 2
        ani.toValue = 0
        ani.fillMode = kCAFillModeForwards
        ani.isRemovedOnCompletion = false
        button.layer.add(ani, forKey: nil)
        button.setTitleColor(.lightGray, for: .normal)
    }
    
    @IBAction func buttonSelected(_ sender: UIButton) {
        selectionFeedback()
        let prevSelected = buttons[durs.index(of: backgroungFetchInterval)!]
        showDeslected(button: prevSelected)
        showSelected(button: sender)
        backgroungFetchInterval = durs[sender.tag]
    }
    
    @IBAction func dismissVC() {
        menuViewController.tableView(menuViewController.tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
        cariocaMenu.showIndicator(position: .center, offset: 0)
        dismiss(animated: true)
    }
}

extension SettingsViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        print("called: ", URL)
        return true
    }

}
