//
//  MainViewController.swift
//  iEMB X
//
//  Created by Chen Changheng on 21/9/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import UIKit
import Custom_UI

class MenuViewController: UITableViewController {
    
    var cellIdentifier = "cellRight"
    
    let boardIds = [1048, 1039, 1049, 1050, 1053]
    var boardVCs: [UINavigationController] = [1048, 1039, 1049, 1050, 1053].map {
        let ctr = Constants.mainStoryboard.instantiateViewController(withIdentifier: "boardVC") as! BoardTableController
        ctr.currentBoard = $0
        return UINavigationController(rootViewController: ctr)
    }
    
    var boardIcons = [#imageLiteral(resourceName: "student"),#imageLiteral(resourceName: "service"),#imageLiteral(resourceName: "psb"),#imageLiteral(resourceName: "lost_found"),#imageLiteral(resourceName: "serve"),#imageLiteral(resourceName: "settings")]
    
    var presentedBoardVC: BoardTableController!

    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 6
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! BoardCell
        cell.tag = indexPath.row
        if indexPath.row == 5 {
            cell.titleLabel.text = "Settings"
            cell.iconView.image = #imageLiteral(resourceName: "settings")
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
        return self.view
    }
    
    func getShapeColor() -> UIColor {
        return UIColor(red:0.07, green:0.83, blue:0.86, alpha:1)
    }
    
    func heightByMenuItem()->CGFloat {
        return self.tableView(self.tableView, heightForRowAt: IndexPath(item: 0, section: 0))
    }
    
    func numberOfMenuItems()->Int {
        return self.tableView(self.tableView, numberOfRowsInSection: 0)
    }
    
    func iconForRowAtIndexPath(_ indexPath:IndexPath)->UIImage {
        return boardIcons[indexPath.row]
    }
    
    func setCellIdentifierForEdge(_ identifier: String) {
        cellIdentifier = identifier
        tableView.reloadData()
    }

}

extension MenuViewController: UIAdaptivePresentationControllerDelegate, CariocaMenuDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    func cariocaMenuDidSelect(_ menu: CariocaMenu, indexPath: IndexPath) {
        if indexPath.row == 5 {
            let index = menuViewController.boardVCs.index(of: menuViewController.presentedBoardVC.navigationController!)!
            menu.updateIndicatorsImage(boardIcons[index])
            let settingsVC = storyboard!.instantiateViewController(withIdentifier: "settingsVC") as! SettingsViewController
            settingsVC.present(in: baseViewController)
            return
        }
        let vc = boardVCs[indexPath.row]
        
        presentedBoardVC.navigationController!.view.removeFromSuperview()
        presentedBoardVC.navigationController!.removeFromParentViewController()
        
        presentedBoardVC = vc.viewControllers[0] as! BoardTableController
        
        baseViewController.addChildViewController(presentedBoardVC.navigationController!)
        
        let navView = presentedBoardVC.navigationController!.view!
        let baseView = baseViewController.view!
        navView.frame = baseView.bounds
        baseView.addSubview(navView)

        cariocaMenu.moveToTop()
    }
    
}

