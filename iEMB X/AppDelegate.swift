//
//  AppDelegate.swift
//  iEMB X
//
//  Created by Chen Changheng on 13/9/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import UIKit
import UserNotifications
import CariocaMenu

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
        Post.initializePosts()
        setupBaseUI()
        window?.makeKeyAndVisible()
        setupFileDirectory()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (_, _) in
        }
        
        if EMBReader.storedUser() == nil{
            Constants.mainStoryboard.instantiateViewController(withIdentifier: "loginVC").present(in: window!.rootViewController!)
        }
        return true
    }
    
    private func setupBaseUI(){
        let boardVC = menuViewController.boardVCs[0].viewControllers[0] as! BoardTableController
        menuViewController.presentedBoardVC = boardVC
        baseViewController.addChildViewController(menuViewController.boardVCs[0])
        baseViewController.view.addSubview(menuViewController.boardVCs[0].view)
        
        cariocaMenu.addInView(baseViewController.view)
        window?.rootViewController = baseViewController
        
        cariocaMenu.showIndicator(position: CariocaMenuIndicatorViewPosition.center, offset: 0)
    }
    
    private func setupFileDirectory(){
        if !FileManager.default.fileExists(atPath: Constants.cachedFilesURL.path){
            do{
                try FileManager.default.createDirectory(at: Constants.cachedFilesURL, withIntermediateDirectories: false, attributes: nil)
            }
            catch{
                simpleAlert(title: "Directory Initialization Failed", message: error.localizedDescription){_ in
                    exit(0)
                }.present(in: baseViewController)
            }
        }
        DispatchQueue.global(qos: .background).async {
            if let urls = try? FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: NSTemporaryDirectory()), includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants){
                urls.forEach{
                    try? FileManager.default.removeItem(at: $0)
                }
            }
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        if EMBReader.isLoggedIn{
            UIApplication.shared.setMinimumBackgroundFetchInterval(backgroungFetchInterval)
            saveContext()
        }
        else{
            UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalNever)
        }
    }

    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if EMBReader.storedUser() != nil{
            Post.initializePosts()
            EMBReader.updatePostsFor(board: 1048, completion: { (posts) in
                if posts != nil{
                    if posts!.isEmpty{
                        completionHandler(.noData)
                        return
                    }
                    userDefaults.set(Date().timeIntervalSince1970, forKey: "lastRefreshed_1048")
                    DispatchQueue.main.async {
                        (menuViewController.boardVCs[0].viewControllers[0] as! BoardTableController).tableView?.reloadData()
                    }
                    var c1 = 0, c2 = 0, c3 = 0
                    for post in posts!{
                        switch post.importance{
                        case .urgent: c1 += 1
                        case .important: c2 += 1
                        case .information: c3 += 1
                        }
                    }
                    scheduleNotification(withTitle: "You Have \(posts!.count) New Posts", body: "Categories:  🛑\(c1)   ⚠️\(c2)   ✅\(c3)")
                    completionHandler(.newData)
                }
                else{
                    completionHandler(.failed)
                }
            })
        }
        else{
            UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalNever)
            completionHandler(.noData)
        }
    }

}
