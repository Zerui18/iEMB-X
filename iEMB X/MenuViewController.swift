//
//  MainViewController.swift
//  iEMB X
//
//  Created by Chen Changheng on 21/9/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import UIKit
import EMBClient
import Components

class MenuViewController: UITableViewController {
    
    var cellIdentifier = "cellRight"
    
    var boardIds: [Int] {
        EMBClient.boardIds
    }
    lazy var boardVCs: [UINavigationController] = boardIds.map {
        let ctr = Constants.mainStoryboard.instantiateViewController(withIdentifier: "boardVC") as! BoardTableController
        ctr.currentBoard = $0
        let navVc = UINavigationController(rootViewController: ctr)
        // fix for iOS 13
        // reconfigure navBars to use translucent backgrounds
        // instead of the new default transparent
        if #available(iOS 13.0, *) {
            let app = UINavigationBarAppearance()
            navVc.navigationBar.standardAppearance = app
            navVc.navigationBar.scrollEdgeAppearance = app
        }
        return navVc
    }
    
    var boardIcons = [UIImage(named: "ic_student")!, UIImage(named: "ic_hbl")!, UIImage(named: "settings")!]
    
    var presentedBoardVC: BoardTableController!

    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        boardIds.count + 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! BoardCell
        cell.tag = indexPath.row
        // manually setup settings row
        // which is at the end
        if indexPath.row == boardIds.count {
            cell.titleLabel.text = "Settings"
            cell.iconView.image = UIImage(named: "settings")!
            cell.applyNormalStyle()
            return cell
        }
        let boardId = boardIds[indexPath.row]
        cell.titleLabel.text = Constants.idToBoardName[boardId]!
        cell.iconView.image = boardIcons[indexPath.row]
        if indexPath == cariocaMenu.selectedIndexPath {
            cell.applySelectedStyle()
        }
        else {
            cell.applyNormalStyle()
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        cariocaMenu.didSelectRowAtIndexPath(indexPath, fromContentController: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

}

extension MenuViewController: CariocaMenuDataSource {
    
    func preselectRowAtIndexPath(_ indexPath: IndexPath) {
        selectionFeedback()
        (tableView.cellForRow(at: indexPath) as? BoardCell)?.applySelectedStyle(true)
    }
    
    func setSelectedIndexPath(_ indexPath: IndexPath) {
        (tableView.cellForRow(at: indexPath) as? BoardCell)?.applySelectedStyle()
    }
    
    func selectRowAtIndexPath(_ indexPath: IndexPath) {
        tableView(tableView, didSelectRowAt: indexPath)
    }
    
    func unselectRowAtIndexPath(_ indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as? BoardCell
        if indexPath == cariocaMenu.selectedIndexPath {
            cell?.applySelectedStyle()
        }
        else {
            cell?.applyNormalStyle()
        }
    }
    
    func getMenuView()->UIView {
        self.view
    }
    
    func heightByMenuItem()->CGFloat {
        self.tableView(self.tableView, heightForRowAt: IndexPath(item: 0, section: 0))
    }
    
    func numberOfMenuItems()->Int {
        self.tableView(self.tableView, numberOfRowsInSection: 0)
    }
    
    func iconForRowAtIndexPath(_ indexPath:IndexPath)->UIImage {
        boardIcons[indexPath.row]
    }
    
    func setCellIdentifierForEdge(_ identifier: String) {
        cellIdentifier = identifier
        tableView.reloadData()
    }

}

extension MenuViewController: UIAdaptivePresentationControllerDelegate, CariocaMenuDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        .none
    }
        
    func cariocaMenuDidSelect(_ menu: CariocaMenu, indexPath: IndexPath) {
        // handle present settings if the last row is selected
        if indexPath.row == boardIds.count {
            let index = menuViewController.boardVCs.firstIndex(of: menuViewController.presentedBoardVC.navigationController!)!
            menu.updateIndicatorsImage(boardIcons[index])
            let settingsVC = storyboard!.instantiateViewController(withIdentifier: "settingsVC") as! SettingsViewController
            settingsVC.modalPresentationStyle = .formSheet
            settingsVC.present(in: baseViewController)
            return
        }
        
        // else formula present board vc
        let vc = boardVCs[indexPath.row]
        
        presentedBoardVC.navigationController!.view.removeFromSuperview()
        presentedBoardVC.navigationController!.removeFromParent()
        
        presentedBoardVC = (vc.viewControllers[0] as! BoardTableController)
        
        baseViewController.addChild(presentedBoardVC.navigationController!)
        
        let navView = presentedBoardVC.navigationController!.view!
        let baseView = baseViewController.view!
        navView.frame = baseView.bounds
        baseView.addSubview(navView)

        cariocaMenu.moveToTop()
    }
    
}

