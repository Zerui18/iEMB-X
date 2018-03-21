//
//  AppDelegate.swift
//  iEMB X
//
//  Created by Chen Changheng on 13/9/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import UIKit
import Custom_UI
import EMBClient
import UserNotifications

let baseViewController = BaseViewController()
var menuViewController: MenuViewController = {
    return Constants.mainStoryboard.instantiateViewController(withIdentifier: "menuVC") as! MenuViewController
}()
var cariocaMenu: CariocaMenu = {
    let c = CariocaMenu(dataSource: menuViewController)
    c.delegate = menuViewController
    return c
}()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow? = UIWindow(frame: UIScreen.main.bounds)
    static var shared: AppDelegate!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        AppDelegate.shared = self
        setupBaseUI()
        
        setupFileDirectory()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) {_,_ in}
        
        if !EMBUser.shared.hasSavedCredentials() {
            Constants.mainStoryboard.instantiateViewController(withIdentifier: "loginVC").present(in: window!.rootViewController!)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(presentLoginScreen), name: .embLoginCredentiaInvalidated, object: nil)
        return true
    }
    
    private func setupBaseUI() {
        let boardVC = menuViewController.boardVCs[0].viewControllers[0] as! BoardTableController
        menuViewController.presentedBoardVC = boardVC
        baseViewController.addChildViewController(menuViewController.boardVCs[0])
        baseViewController.view.addSubview(menuViewController.boardVCs[0].view)
        
        cariocaMenu.addInView(baseViewController.view)
        window?.rootViewController = baseViewController
        
        cariocaMenu.showIndicator(position: CariocaMenuIndicatorViewPosition.center, offset: 0)
        window!.makeKeyAndVisible()
    }
    
        
    private func setupFileDirectory() {
        // create cached files directory if no already present
        if !FileManager.default.fileExists(atPath: Constants.cachedFilesURL.path) {
            do {
                try FileManager.default.createDirectory(at: Constants.cachedFilesURL, withIntermediateDirectories: false, attributes: nil)
            }
            catch {
                UIAlertController(title: "Directory Initialization Error", message: error.localizedDescription) {
                    exit(0)
                }.present(in: baseViewController)
            }
        }
        
        // clears temporary directory (where URLSession Downloads & other stuff are cached)
        DispatchQueue.global().async {
            guard let urls = try? FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: NSTemporaryDirectory()), includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants) else {
                return
            }
            
            urls.forEach {
                try? FileManager.default.removeItem(at: $0)
            }
        }
    }
    
    @objc private func presentLoginScreen() {
        DispatchQueue.main.async {
            menuViewController.presentedBoardVC.navigationController?.popToRootViewController(animated: false)
            Constants.mainStoryboard.instantiateViewController(withIdentifier: "loginVC").present(in: self.window!.rootViewController!)
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        if EMBUser.shared.hasSavedCredentials() {
            UIApplication.shared.setMinimumBackgroundFetchInterval(backgroungFetchInterval)
            try? CoreDataHelper.shared.saveContext()
        }
        else {
            UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalNever)
        }
    }

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        guard EMBUser.shared.hasSavedCredentials() else {
            UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalNever)
            completionHandler(.noData)
            return
        }
    
        beginPostUpdate(completionHandler: completionHandler)
    }
    
    private func beginPostUpdate(completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        EMBClient.shared.updatePosts(forBoard: 1048) { (posts, error) in
            
            guard error != nil else {
                completionHandler(.failed)
                return
            }
            
            userDefaults.set(Date().timeIntervalSince1970, forKey: "lastRefreshed_1048")
            
            guard !posts!.isEmpty else {
                completionHandler(.noData)
                return
            }
            
            
            DispatchQueue.main.sync {
                (menuViewController.boardVCs[0].viewControllers[0] as! BoardTableController).tableView?.reloadData()
            }
            
            var c1 = 0, c2 = 0, c3 = 0
            for post in posts! {
                switch post.importance {
                case .urgent: c1 += 1
                case .important: c2 += 1
                case .information: c3 += 1
                }
            }
            
            self.scheduleNotification(withTitle: "You Have \(posts!.count) New Posts", body: "Categories:  🛑\(c1)   ⚠️\(c2)   ✅\(c3)")
        }
    }
    
    private func scheduleNotification(withTitle title: String, body: String) {
        let content: UNMutableNotificationContent = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = UNNotificationSound.default()
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "\(arc4random())_noti", content: content, trigger: nil))
    }

}
