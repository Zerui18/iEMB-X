//
//  ViewController.swift
//  iEMB X
//
//  Created by Chen Changheng on 13/9/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import UIKit
import EMBClient

fileprivate let swipeActionPullViewType: AnyClass = NSClassFromString("UISwipeActionPullView")!

class BoardTableController: UITableViewController {
    
    /// Integer board id.
    var currentBoard: Int = 1048
    
    /// Interactive Dismisser for presented ViewPostVCs.
    let interactor = Interactor()
    
    var shouldUpdateBoardOnAppear = false
    
    // MARK: Private Properties
    /// Barbutton that toggles unread filter.
    @IBOutlet private weak var filterButton: UIBarButtonItem!
    
    /**
     All posts to display/search for in the current board. Reflects "isFilteringUnread" state.
     */
    fileprivate var allPostsToDisplay: [Post] {
        return isFilteringUnread ? unreadPosts:EMBClient.shared.allPosts[currentBoard]!
    }
    /**
     All posts to display in the current board. Reflects "isFilteringUnread" & "isFilteringThroughSearch" states.
     */
    fileprivate var displayedPosts: [Post] {
        return isFilteringThroughSearch ? filteredPosts:allPostsToDisplay
    }
    
    /// Cache of search results.
    fileprivate var filteredPosts: [Post] = []
    
    /// Cache of filter results.
    fileprivate var unreadPosts: [Post] = []
    
    /// Flag indicating whether search is active.
    fileprivate var isFilteringThroughSearch = false
    
    /// Flag indicating whether unread-filter is active.
    fileprivate var isFilteringUnread = false
    
    
//    /// Cache of selected indexPath.
//    fileprivate var selectedIndexPath: IndexPath?
    
    fileprivate let searchController = UISearchController(searchResultsController: nil)
    
    fileprivate var lastRefreshed: TimeInterval {
        get {
            return userDefaults.double(forKey: "lastRefreshed_\(self.currentBoard)")
        }
        set {
            userDefaults.setValue(newValue, forKey: "lastRefreshed_\(self.currentBoard)")
        }
    }
    
    // MARK: Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        title = Constants.idToBoardName[currentBoard]
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        filterButton.tintColor = isFilteringUnread ? #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1):#colorLiteral(red: 0.6553392163, green: 0.6553392163, blue: 0.6553392163, alpha: 1)
        
        guard let coordinator = transitionCoordinator else {
            return
        }
        
//        let index = selectedIndexPath
        coordinator.animate(alongsideTransition: {_ in
            self.showUIComponents()
//            if index != nil {
//                (self.tableView.cellForRow(at: index!) as? PostCell)?.showDeselection()
//            }
        }, completion: {context in
            if context.isCancelled {
                UIView.animate(withDuration: 0.3) {
                    self.hideUIComponents()
//                    if index != nil {
//                        (self.tableView.cellForRow(at: index!) as? PostCell)?.showSelection()
//                    }
                }
            }
//            else {
//                self.selectedIndexPath = nil
//            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if shouldUpdateBoardOnAppear {
            // this only happens on credentials invalidation and relogin
            tableView.reloadData() // reload to prevent out of sync
            updateBoard()
            shouldUpdateBoardOnAppear = false
        }
    }
    
    private func setupUI() {
        tableView.rowHeight = 100
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.searchBar.scopeButtonTitles = ["Title","Author","Marked"]
        
        navigationItem.searchController = searchController
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.hidesSearchBarWhenScrolling = false
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .organize, target: self, action: #selector(openFilesCtr))
        
        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(updateBoard), for: .valueChanged)
        updateLastReadDisplay()
        
        tableView.separatorStyle = .none
        
        filterButton.target = self
        filterButton.action = #selector(toggleUnreadFilter)
        NotificationCenter.default.addObserver(self, selector: #selector(postDidUpdate(_:)), name: .postContentDidLoad, object: nil)
    }
    
    // MARK: Selector Methods
    @objc private func openFilesCtr() {
        navigationController?.pushViewController(
            storyboard!.instantiateViewController(withIdentifier: "filesVC"),
            animated: true)
    }
    
    @objc private func updateBoard() {
        guard EMBUser.shared.isAuthenticated() else {
            NotificationCenter.default.post(name: .embLoginCredentiaInvalidated, object: nil)
            return
        }
        
        refreshControl?.beginRefreshing()
        navigationItem.rightBarButtonItem?.isEnabled = false
        EMBClient.shared.updatePosts(forBoard: currentBoard) { (posts, error) in
            
            defer{
                DispatchQueue.main.async {
                    self.refreshControl?.endRefreshing()
                    self.navigationItem.rightBarButtonItem?.isEnabled = true
                }
            }
            
            guard let newPosts = posts else {
                notificationFeedback(ofType: .error)
                if (error! as NSError).domain != "com.Zerui.EMBClient.AuthError" {
                    DispatchQueue.main.async {
                        UIAlertController(title: "Error", message: "failed to load posts for board \(self.currentBoard)").present(in: self)
                    }
                }
                return
            }
            
            self.boardUpdated(for: newPosts)
        }
    }
    
    
    @objc private func postDidUpdate(_ notification: Notification) {
        if let post = notification.object as? Post, post.board == Int64(currentBoard) {
            reloadCell(forPost: post)
        }
    }
    
    @objc private func toggleUnreadFilter() {
        isFilteringUnread = !isFilteringUnread
        
        UIView.animate(withDuration: 0.2) {
            self.filterButton.tintColor = self.isFilteringUnread ? #colorLiteral(red: 0, green: 0.5898008943, blue: 1, alpha: 1):#colorLiteral(red: 0.6553392163, green: 0.6553392163, blue: 0.6553392163, alpha: 1)
        }
        
        if isFilteringUnread {
            unreadPosts = EMBClient.shared.allPosts[currentBoard]!.filter{!$0.isRead}
        }
        else {
            unreadPosts.removeAll()
        }
        
        tableView.reloadSections([0], with: .right)
    }
    
    fileprivate func reloadCell(forPost post: Post) {
        if isFilteringThroughSearch {
            if let postIndex = filteredPosts.firstIndex(of: post) {
                tableView.reloadRows(at: [IndexPath(row: postIndex, section: 0)], with: .automatic)
            }
        }
        else if let postIndex = allPostsToDisplay.firstIndex(of: post) {
            let indexPaths = [IndexPath(row: postIndex, section: 0)]
            
            if isFilteringUnread{
                unreadPosts.remove(at: postIndex)
                tableView.deleteRows(at: indexPaths, with: .automatic)
            }
            else{
                tableView.reloadRows(at: indexPaths, with: .automatic)
            }
        }
    }
    
    // MARK: Internal Methods
    func reset() {
        filteredPosts.removeAll()
        unreadPosts.removeAll()
        isFilteringThroughSearch = false
        isFilteringUnread = false
        searchController.isActive = false
        tableView.reloadData()
    }
    
    func hideUIComponents() {
        searchController.searchBar.resignFirstResponder()
        cariocaMenu.sidePanLeft.isEnabled = false
        cariocaMenu.setIndicatorAlpha(0)
    }
    
    func showUIComponents() {
        cariocaMenu.sidePanLeft.isEnabled = true
        cariocaMenu.setIndicatorAlpha(1)
    }
    
    func boardUpdated(for newPosts: [Post]) {
        self.lastRefreshed = Date().timeIntervalSince1970
        if !newPosts.isEmpty {
//            self.selectedIndexPath = nil
            
            let count: Int
            
            if self.isFilteringUnread{
                let unreadPosts = newPosts.filter{!$0.isRead}
                self.unreadPosts.insert(contentsOf: unreadPosts, at: 0)
                
                count = unreadPosts.count
            }
            else{
                count = newPosts.count
            }
            let ints = [Int](0...count-1)
            
            DispatchQueue.main.async {
                
                self.tableView.insertRows(at: ints.map {
                    IndexPath(row: $0, section: 0)
                }, with: .automatic)
                
            }
        }
        DispatchQueue.main.async {
            self.updateLastReadDisplay()
        }
    }
}

extension BoardTableController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedPosts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCell") as! PostCell
        cell.updateWith(post: displayedPosts[indexPath.row])
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        selectedIndexPath = indexPath
        (tableView.visibleCell(at: indexPath) as? PostCell)?.showDeselection()
        let vc = storyboard!.instantiateViewController(withIdentifier: "viewVC") as! ViewPostController
        vc.modalPresentationStyle = .overFullScreen
        vc.post = displayedPosts[indexPath.row]
        vc.transitioningDelegate = self
        vc.present(in: self)
//        UIView.animate(withDuration: Constants.presentTransitionDuration) {
//            self.hideUIComponents()
//        }
    }
    
    override func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        if let pullView = menuViewController.presentedBoardVC.tableView.subviews.filter({
            $0 => swipeActionPullViewType
        }).last {
            pullView.clipsToBounds = true
            pullView.layer.cornerRadius = 5
            pullView.backgroundColor = UIColor.white.withAlphaComponent(0.8)
            
            let actionButton = pullView.subviews[0] as! UIButton
            actionButton.subviews[0].alpha = 0
            actionButton.setTitleColor(.darkGray, for: .normal)
            actionButton.setTitleColor(.gray, for: .highlighted)
        }
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let post = displayedPosts[indexPath.row]
        let isMarked = post.isMarked
        let toggleMarkAction = UITableViewRowAction(style: .default, title: isMarked ? "Unmark":"Mark", handler: { (_, _) in
            tableView.setEditing(false, animated: false)
            post.isMarked = !isMarked
            if let cell = tableView.visibleCell(at: indexPath) as? PostCell {
                cell.updateWith(post: post)
            }
        })
        return [toggleMarkAction]
    }
    
    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        updateLastReadDisplay()
    }
    
    fileprivate func updateLastReadDisplay() {
        let timeInterval = lastRefreshed
        if timeInterval > 0 {
            refreshControl!.attributedTitle = NSAttributedString(string: Date(timeIntervalSince1970: timeInterval).timeAgoSinceNow(), attributes: [.font: subfont, .foregroundColor: UIColor.gray])
        }
        else {
            refreshControl!.attributedTitle = NSAttributedString(string: "Pull to Update", attributes: [.font: subfont, .foregroundColor: UIColor.gray])
        }
    }
    
}

extension BoardTableController: UISearchResultsUpdating, UISearchBarDelegate {
    
    func updateSearchResults(for searchController: UISearchController) {
        if let text = searchController.searchBar.text?.lowercased(), !text.isEmpty {
            switch searchController.searchBar.selectedScopeButtonIndex {
            case 0:
                self.filteredPosts = allPostsToDisplay.filter { (post) in
                    return post.titleLower.contains(text)
                }
            case 1:
                let name = text.uppercased()
                self.filteredPosts = allPostsToDisplay.filter { (post) in
                    return post.author!.contains(name)
                }
            default:
                self.filteredPosts = allPostsToDisplay.filter { (post) in
                    return post.isMarked && post.titleLower.contains(text)
                }
            }
        }
        else {
            if searchController.searchBar.selectedScopeButtonIndex == 2 {
                self.filteredPosts = allPostsToDisplay.filter {
                    $0.isMarked
                }
            }
            else {
                self.filteredPosts = allPostsToDisplay
            }
        }
        self.tableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        self.isFilteringThroughSearch = true
        selectionFeedback()
        updateSearchResults(for: searchController)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.isFilteringThroughSearch = false
        self.tableView.reloadData()
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        self.isFilteringThroughSearch = true
        return true
    }
    
}

extension BoardTableController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PresentAnimator()
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let postVC = dismissed as? ViewPostController else {
            return nil
        }
        
        if postVC.isReplying {
            postVC.responseTextView.resignFirstResponder()
        }
        
        switch postVC.downPan.state {
        case .began, .changed:
            return DismissAnimator(animation: .close)
        case .cancelled, .ended, .failed:
            return DismissAnimator(animation: .shrink)
        default:
            return nil
        }
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor:nil
    }
}

fileprivate let subfont = UIFont.systemFont(ofSize: 13)
