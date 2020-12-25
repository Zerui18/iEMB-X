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
    
    var shouldUpdateBoardOnAppear = false
    
    /// Interactive Dismisser for presented ViewPostVCs. (Legacy)
    let interactor = Interactor()
    
    // MARK: Private Properties
    /// Barbutton that toggles unread filter.
    @IBOutlet private weak var filterButton: UIBarButtonItem!
    
    private lazy var filesButton = UIBarButtonItem(barButtonSystemItem: .organize, target: self, action: #selector(openFilesCtr))
    
    /// BarButton that replaces the folders BarButton when filesButton is active.
    private lazy var readAllButton = UIBarButtonItem(title: "Read All", style: .plain, target: self, action: #selector(showReadAllPrompt))
    
    /// Posts left after applying filter (if applicable).
    fileprivate var filteredPosts: [Post] {
        isFilterActive ? unreadPosts:EMBClient.shared.allPosts[currentBoard]!
    }
    ///Posts left after applying filter and search (if applicable).
    fileprivate var filteredSearchedPosts: [Post] {
        isSearchActive ? searchedPosts:filteredPosts
    }
    
    /// Cache of search results.
    fileprivate var searchedPosts: [Post] = []
    
    /// Cache of filter results.
    fileprivate var unreadPosts: [Post] = []
    
    /// Flag indicating whether search is active.
    fileprivate var isSearchActive = false
    
    /// Flag indicating whether unread-filter is active.
    fileprivate var isFilterActive = false
    
    /// The search controller that provides the posts search functionality.
    fileprivate let searchController = UISearchController(searchResultsController: nil)
    
    fileprivate var lastRefreshed: TimeInterval {
        get {
            userDefaults.double(forKey: "lastRefreshed_\(self.currentBoard)")
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
        filterButton.tintColor = isFilterActive ? .systemBlue:.systemGray
        
        guard let coordinator = transitionCoordinator else {
            return
        }
        
        coordinator.animate(alongsideTransition: {_ in
            self.showUIComponents()
        }, completion: {context in
            if context.isCancelled {
                UIView.animate(withDuration: 0.3) {
                    self.hideUIComponents()
                }
            }
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
        tableView.contentInset.top += 6
        tableView.showsVerticalScrollIndicator = false
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        searchController.searchBar.scopeButtonTitles = ["Title", "Author", "Marked"]
        
        navigationItem.searchController = searchController
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.hidesSearchBarWhenScrolling = false
        
        navigationItem.rightBarButtonItem = filesButton
        
        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(updateBoard), for: .valueChanged)
        updateLastReadDisplay()
        
        tableView.separatorStyle = .none
        
        filterButton.target = self
        filterButton.action = #selector(toggleUnreadFilter)
        NotificationCenter.default.addObserver(self, selector: #selector(postDidUpdate(_:)), name: .postIsReadUpdated, object: nil)
    }
    
    // MARK: Selector Methods
    @objc private func openFilesCtr() {
        navigationController?.pushViewController(
            storyboard!.instantiateViewController(withIdentifier: "filesVC"),
            animated: true)
    }
    
    @objc private func updateBoard() {
        // initial safety check for auth cookie
        guard EMBUser.shared.isAuthenticated() else {
            NotificationCenter.default.post(name: .embLoginCredentiaInvalidated, object: nil)
            return
        }
        
        refreshControl!.beginRefreshing()
        navigationItem.rightBarButtonItem!.isEnabled = false
        EMBClient.shared.updatePosts(forBoard: currentBoard) { (posts, error) in
            
            defer {
                DispatchQueue.main.async {
                    self.refreshControl!.endRefreshing()
                    self.navigationItem.rightBarButtonItem!.isEnabled = true
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
        isFilterActive.toggle()
        
        UIView.animate(withDuration: 0.2) {
            if #available(iOS 13.0, *) {
                self.filterButton.tintColor = self.isFilterActive ? .systemBlue:.systemGray
            } else {
                self.filterButton.tintColor = self.isFilterActive ? .blue:.lightGray
            }
            
            self.navigationItem.rightBarButtonItem = self.isFilterActive ? self.readAllButton:self.filesButton
        }
        
        if isFilterActive {
            unreadPosts = EMBClient.shared.allPosts[currentBoard]!.filter{!$0.isRead}
        }
        else {
            unreadPosts.removeAll()
        }
        
        tableView.reloadSections([0], with: .right)
    }
    
    @objc private func showReadAllPrompt() {
        // find all unread posts
        let targetPosts = EMBClient.shared.allPosts[currentBoard]!.filter({ !$0.isRead })
        if targetPosts.isEmpty {
            return
        }
        
        // prepare confirmation alert
        let confirmAlert = UIAlertController(title: "Read All", message: "This will mark \(targetPosts.count) posts as read. Please ensure that you have read through the important posts.", preferredStyle: .alert)
        confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        confirmAlert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { _ in
            
            // alert showing progress
            let progressAlert = UIAlertController(title: "Marking Posts", message: "...", preferredStyle: .alert)
            progressAlert.present(in: self)
            
            // begin read all
            targetPosts.readAll(progress: { (nMarked) in
                progressAlert.message = String(format: "%03d / %03d", nMarked, targetPosts.count)
            }) {
                progressAlert.title = "Completed"
                progressAlert.message = "remember to read impt. posts :)"
                // since postRead notifications aren't sent
                // manually reload unread posts and call reloadData to update display
                self.unreadPosts = EMBClient.shared.allPosts[self.currentBoard]!.filter{!$0.isRead}
                self.tableView.reloadData()
                
                // add dismiss option
                progressAlert.addAction(UIAlertAction(title: "Done", style: .cancel))
            }
            
        }))
        confirmAlert.present(in: self)
    }
    
    fileprivate func reloadCell(forPost post: Post) {
        DispatchQueue.main.async { [self] in
            if isSearchActive {
                if let postIndex = searchedPosts.firstIndex(of: post) {
                    tableView.reloadRows(at: [IndexPath(row: postIndex, section: 0)], with: .automatic)
                }
            }
            else if let postIndex = filteredPosts.firstIndex(of: post) {
                let indexPaths = [IndexPath(row: postIndex, section: 0)]
                
                if isFilterActive {
                    // if post became read, remove it from unreadPosts
                    if post.isRead {
                        unreadPosts.remove(at: postIndex)
                        tableView.deleteRows(at: indexPaths, with: .automatic)
                    }
                }
                else {
                    tableView.reloadRows(at: indexPaths, with: .automatic)
                }
            }
        }
    }
    
    // MARK: Internal Methods
    func reset() {
        searchedPosts.removeAll()
        unreadPosts.removeAll()
        isSearchActive = false
        isFilterActive = false
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
            
            let count: Int
            
            if self.isFilterActive{
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
        return filteredSearchedPosts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "postCell") as! PostCell
        cell.updateWith(post: filteredSearchedPosts[indexPath.row])
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        (tableView.visibleCell(at: indexPath) as? PostCell)?.showDeselection()
        if #available(iOS 13, *) {
            let vc = storyboard!.instantiateViewController(withIdentifier: "viewPostVC") as! ViewPostController
            vc.post = filteredSearchedPosts[indexPath.row]
            vc.present(in: self)
        }
        else {
            let vc = storyboard!.instantiateViewController(withIdentifier: "viewPostVCLegacy") as! ViewPostControllerLegacy
            vc.post = filteredSearchedPosts[indexPath.row]
            vc.transitioningDelegate = self
            vc.present(in: self)
        }
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let post = filteredSearchedPosts[indexPath.row]
        let isMarked = post.isMarked
        let toggleMarkAction = UITableViewRowAction(style: .normal, title: isMarked ? "Unmark":"Mark", handler: { (_, _) in
            tableView.setEditing(false, animated: false)
            post.isMarked = !isMarked
            if let cell = tableView.visibleCell(at: indexPath) as? PostCell {
                cell.updateWith(post: post)
            }
        })
        toggleMarkAction.backgroundColor = .systemYellow
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
                self.searchedPosts = filteredPosts.filter { (post) in
                    return post.titleLower.contains(text)
                }
            case 1:
                let name = text.uppercased()
                self.searchedPosts = filteredPosts.filter { (post) in
                    return post.author!.contains(name)
                }
            default:
                self.searchedPosts = filteredPosts.filter { (post) in
                    return post.isMarked && post.titleLower.contains(text)
                }
            }
        }
        else {
            // show all marked posts (even with no search text)
            if searchController.searchBar.selectedScopeButtonIndex == 2 {
                self.searchedPosts = filteredPosts.filter {
                    $0.isMarked
                }
            }
            // else no filtering at all
            else {
                self.searchedPosts = filteredPosts
            }
        }
        self.tableView.reloadData()
    }
    
    func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        self.isSearchActive = true
        selectionFeedback()
        updateSearchResults(for: searchController)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.isSearchActive = false
        self.tableView.reloadData()
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        self.isSearchActive = true
        return true
    }
    
}

// MARK: Transitions (Legacy)
extension BoardTableController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PresentAnimator()
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let postVC = dismissed as? ViewPostControllerLegacy else {
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
