//
//  ViewController.swift
//  iEMB X
//
//  Created by Chen Changheng on 13/9/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import UIKit
import EMBClient

fileprivate var allPosts: [Int: [Post]]{
    return EMBClient.shared.allPosts
}

class BoardTableController: UITableViewController{
    
    var currentBoard: Int = 1048
    var filteredPosts: [Post] = []
    
    var isFiltering = false
    let interactor = Interactor()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = Constants.idToBoardName[currentBoard]
        setupUI()
    }
    
    var selectedIndexPath: IndexPath?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let coordinator = transitionCoordinator{
            let index = selectedIndexPath
            coordinator.animate(alongsideTransition: {_ in
                self.showUIComponents()
                if index != nil{
                    (self.tableView.cellForRow(at: index!) as! PostCell).showDeselection()
                }
            }, completion: {context in
                if context.isCancelled{
                    UIView.animate(withDuration: 0.3){
                        self.hideUIComponents()
                        if index != nil{
                            (self.tableView.cellForRow(at: index!) as! PostCell).showSelection()
                        }
                    }
                }
                else{
                    self.selectedIndexPath = nil
                }
            })
        }
    }

    let searchController = UISearchController(searchResultsController: nil)
    
    private func setupUI(){
        tableView.rowHeight = 100
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.searchBar.scopeButtonTitles = ["Title","Author","Marked"]
        
        if #available(iOS 11, *){
            navigationItem.searchController = searchController
            navigationController?.navigationBar.prefersLargeTitles = true
            navigationItem.largeTitleDisplayMode = .always
            navigationItem.hidesSearchBarWhenScrolling = false
        }
        else{
            tableView.tableHeaderView = searchController.searchBar
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .organize, target: self, action: #selector(openFiles))
        
        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(reloadBoard), for: .valueChanged)
        updateLastReadDisplay()
        
        tableView.separatorStyle = .none
        NotificationCenter.default.addObserver(self, selector: #selector(postDidUpdate(_:)), name: .postContentDidLoad, object: nil)
    }
    
    @objc func openFiles(){
        navigationController?.pushViewController(storyboard!.instantiateViewController(withIdentifier: "filesVC"), animated: true)
    }
    
    @objc func reloadBoard(){
        refreshControl?.beginRefreshing()
        navigationItem.rightBarButtonItem?.isEnabled = false
        EMBClient.shared.updatePosts(forBoard: currentBoard) { (posts, error) in
                if posts != nil{
                    userDefaults.set(Date().timeIntervalSince1970, forKey: "lastRefreshed_\(self.currentBoard)")
                    if posts!.count > 0{
                        self.selectedIndexPath = nil
                        DispatchQueue.main.async{
                            let ints = [Int](0...posts!.count-1)
                            self.tableView.insertRows(at: ints.map{
                                IndexPath(row: $0, section: 0)
                            }, with: .automatic)
                        }
                    }
                    DispatchQueue.main.async {
                        self.updateLastReadDisplay()
                    }
                }
                else{
                    notificationFeedback(ofType: .error)
                    if (error! as NSError).domain != "com.Zerui.EMBClient.AuthError"{
                        DispatchQueue.main.async {
                            simpleAlert(title: "Error", message: "failed to load posts for board \(self.currentBoard)").present(in: self)
                        }
                    }
                }
                DispatchQueue.main.async {
                    self.refreshControl?.endRefreshing()
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                }
        }
    }
    
    @objc private func postDidUpdate(_ notification: Notification){
        if let post = notification.object as? Post, post.board == Int64(currentBoard){
            reloadCell(forPost: post)
        }
    }
    
    func reloadCell(forPost post: Post){
        if isFiltering{
            if let postIndex = filteredPosts.index(of: post){
                tableView.reloadRows(at: [IndexPath(row: postIndex, section: 0)], with: .automatic)
            }
        }
        else if let postIndex = EMBClient.shared.allPosts[currentBoard]?.index(of: post){
            tableView.reloadRows(at: [IndexPath(row: postIndex, section: 0)], with: .automatic)
        }
    }
    
    func lastRefreshed()-> TimeInterval{
        return userDefaults.double(forKey: "lastRefreshed_\(self.currentBoard)")
    }

}

extension BoardTableController{
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isFiltering ? filteredPosts.count:allPosts[currentBoard]!.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCell") as! PostCell
        cell.updateWith(post: (isFiltering ? filteredPosts:allPosts[currentBoard]!)[indexPath.row])
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndexPath = indexPath
        (tableView.visibleCell(at: indexPath) as? PostCell)?.showSelection()
        let vc = storyboard!.instantiateViewController(withIdentifier: "viewVC") as! ViewPostController
        vc.post = (isFiltering ? filteredPosts:allPosts[currentBoard]!)[indexPath.row]
        vc.transitioningDelegate = self
        vc.present(in: self)
        UIView.animate(withDuration: Constants.presentTransitionDuration) {
            self.hideUIComponents()
        }
    }
    
    override func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        if let pullView = menuViewController.presentedBoardVC.tableView.subviews.filter({
            String(describing: type(of: $0)) == "UISwipeActionPullView"
        }).last{
            
            pullView.clipsToBounds = true
            pullView.layer.cornerRadius = 5
            pullView.backgroundColor = UIColor.white.withAlphaComponent(0.8)
            
            let actionButton = pullView.subviews[0] as! UIButton
            actionButton.subviews[0].alpha = 0
            actionButton.setTitleColor(.darkGray, for: .normal)
            actionButton.setTitleColor(.gray, for: .highlighted)
            
        }
    }
    
    func hideUIComponents(){
        searchController.searchBar.resignFirstResponder()
        cariocaMenu.sidePanLeft.isEnabled = false
        cariocaMenu.setIndicatorAlpha(0)
    }
    
    func showUIComponents(){
        cariocaMenu.sidePanLeft.isEnabled = true
        cariocaMenu.setIndicatorAlpha(1)
    }
    
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return !searchController.isActive
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let post = allPosts[currentBoard]![indexPath.row]
        let isMarked = post.isMarked
        let toggleMarkAction = UITableViewRowAction(style: .default, title: isMarked ? "Unmark":"Mark", handler: { (_, _) in
            tableView.setEditing(false, animated: false)
            post.isMarked = !isMarked
            if let cell = tableView.visibleCell(at: indexPath) as? PostCell{
                cell.updateWith(post: post)
            }
        })
        return [toggleMarkAction]
    }
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        updateLastReadDisplay()
    }
    
    func updateLastReadDisplay(){
        let timeInterval = lastRefreshed()
        if timeInterval > 0{
            refreshControl!.attributedTitle = NSAttributedString(string: "Last Updated: "+Date(timeIntervalSince1970: timeInterval).timeAgoSinceNow(), attributes: [.font: subfont, .foregroundColor: UIColor.gray])
        }
        else{
            refreshControl!.attributedTitle = NSAttributedString(string: "Last Updated: Never", attributes: [.font: subfont, .foregroundColor: UIColor.gray])
        }
    }
    
}

extension BoardTableController: UISearchResultsUpdating, UISearchBarDelegate{
    
    func updateSearchResults(for searchController: UISearchController) {
        if let text = searchController.searchBar.text?.lowercased(), !text.isEmpty {
            switch searchController.searchBar.selectedScopeButtonIndex{
            case 0:
                self.filteredPosts = allPosts[self.currentBoard]!.filter({ (post) in
                    return post.titleLower.contains(text)
                })
            case 1:
                let name = text.uppercased()
                self.filteredPosts = allPosts[self.currentBoard]!.filter({ (post) in
                    return post.author!.contains(name)
                })
            default:
                self.filteredPosts = allPosts[self.currentBoard]!.filter({ (post) in
                    return post.isMarked && post.titleLower.contains(text)
                })
            }
        }
        else {
            if searchController.searchBar.selectedScopeButtonIndex == 2{
                self.filteredPosts = allPosts[self.currentBoard]!.filter{
                    $0.isMarked
                }
            }
            else{
                self.filteredPosts = allPosts[self.currentBoard]!
            }
        }
        self.tableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        self.isFiltering = true
        selectionFeedback()
        updateSearchResults(for: searchController)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.isFiltering = false
        self.tableView.reloadData()
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        self.isFiltering = true
        return true
    }
        
}

extension BoardTableController: UIViewControllerTransitioningDelegate{
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PresentAnimator()
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if let postVC = dismissed as? ViewPostController, postVC.isReplying{
            postVC.responseTextView.resignFirstResponder()
        }
        return DismissAnimator()
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor:nil
    }
}

fileprivate let subfont = UIFont.systemFont(ofSize: 13)
