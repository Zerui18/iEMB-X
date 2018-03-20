//
//  ViewPostController.swift
//  iEMB X
//
//  Created by Chen Changheng on 15/9/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import UIKit
import EMBClient
import SafariServices
import Custom_UI

class ViewPostController: UIViewController {
    
    @IBOutlet weak var backgroundView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var postContainerView: UIVisualEffectView!
    @IBOutlet weak var postContentTextView: UITextView!
    @IBOutlet weak var attachmentsTable: UITableView!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var attachmentsLabel: UILabel!
    @IBOutlet weak var labelHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var lowerButton: UIButton!
    
    var post: Post!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.clipsToBounds = true
        setupUI()
        loadMessage()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let selected = attachmentsTable.indexPathForSelectedRow {
            transitionCoordinator?.animate(alongsideTransition: { context in
                self.attachmentsTable.deselectRow(at: selected, animated: context.isAnimated)
            })
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AppDelegate.shared.window?.windowLevel = UIWindowLevelAlert - .leastNonzeroMagnitude
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        AppDelegate.shared.window?.windowLevel = UIWindowLevelNormal
    }
    
    lazy var tap = UITapGestureRecognizer(target: self, action: #selector(contentTapped(_:)))
    
    lazy var downPan = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
    
    private func setupUI() {
        postContentTextView.textDragInteraction?.isEnabled = false
        scrollView.delegate = self
        scrollView.contentInset.top = leftButton.frame.maxY + 8 - view.convert(postContainerView.frame.origin, from: postContainerView).y
        attachmentsTable.tableFooterView = UIView()
        
        attachmentsTable.rowHeight = 50
        tableViewHeightConstraint.constant = 0
        labelHeightConstraint.constant = 0
        postContainerView.layer.cornerRadius = 10
        leftButton.layer.cornerRadius = 17.5
        rightButton.layer.cornerRadius = 17.5
        lowerButton.layer.cornerRadius = 17.5
        
        leftButton.addTarget(self, action: #selector(leftButtonClicked), for: .touchUpInside)
        
        rightButton.addTarget(self, action: #selector(rightButtonClicked), for: .touchUpInside)
        lowerButton.addTarget(self, action: #selector(rightButtonClicked), for: .touchUpInside)
        
        postContentTextView.addGestureRecognizer(tap)
        
        downPan.delegate = self
        view.addGestureRecognizer(downPan)
    }
    
    private func loadMessage() {
        if post.content != nil {
            updateUI(animated: false)
        }
        else {
            post.loadContent {[weak self] error in
                guard let `self` = self else {
                    return
                }
                DispatchQueue.main.async {
                    if error != nil {
                        self.postContentTextView.attributedText = NSAttributedString(string: error!.localizedDescription, attributes: [.font: UIFont.systemFont(ofSize: 28, weight: .bold)])
                    }
                    else {
                        self.updateUI(animated: true)
                    }
                }
            }
        }
    }
    
    func updateUI(animated flag: Bool) {
        self.attachmentsTable.reloadSections([0], with: flag ? .left:.none)
        
        func applyAnimatables() {
            self.tableViewHeightConstraint.constant = CGFloat(self.post.attachments!.count * 50) + 5
            self.labelHeightConstraint.constant = self.post.attachments!.count > 0 ? 30:0
            self.rightButton.alpha = post.canRespond ? 1:0
            
            if flag {
                self.postContentTextView.alpha = 0
            }
        }
        
        if flag {
            UIView.animate(withDuration: 0.2, animations: applyAnimatables) {_ in
                self.postContentTextView.attributedText = self.post.compoundMessage()
                
                UIView.animate(withDuration: 0.1) {
                    self.postContentTextView.alpha = 1
                }
            }
        }
        else {
            self.postContentTextView.attributedText = self.post.compoundMessage()
            applyAnimatables()
        }
    }
    
    
    @objc func leftButtonClicked() {
        setReplyUIHidden()
    }
    
    @objc func contentTapped(_ sender: UITapGestureRecognizer) {
        postContentTextView.resignFirstResponder()
        if post.content != nil {
            let index = postContentTextView.layoutManager.characterIndex(for: sender.location(in: postContentTextView), in: postContentTextView.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
            if index < postContentTextView.attributedText.length,
                let attachment = (postContentTextView.attributedText.attribute(.attachment, at: index, effectiveRange: nil) ?? postContentTextView.attributedText.attribute(.attachment, at: index-1, effectiveRange: nil)) as? NSTextAttachment {
                if let image = attachment.image(forBounds: attachment.bounds, textContainer: postContentTextView.textContainer, characterIndex: index) {
                    let tempImage = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(attachment.fileWrapper?.filename ?? "Image.png")
                    try! UIImagePNGRepresentation(image)!.write(to: tempImage)
                    let ctr = FilePreviewController()
                    ctr.file = tempImage
                    ctr.deletesFileOnDismiss = true
                    ctr.present(in: self)
                }
            }
        }
    }
    
    var replyContainerView: UIVisualEffectView!
    var optionsSegment: UISegmentedControl!
    var responseTextView: RSKPlaceholderTextView!
    
    private func setupReplyUI() {
        if replyContainerView != nil {return}
        
        // setup reply segments
        
        replyContainerView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
        
        replyContainerView.alpha = 0
        replyContainerView.translatesAutoresizingMaskIntoConstraints = false
        replyContainerView.clipsToBounds = true
        replyContainerView.layer.cornerRadius = 10
        view.addSubview(replyContainerView)
        
        replyContainerView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: scrollView.adjustedContentInset.top + 8).isActive = true
        replyContainerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 8).isActive = true
        replyContainerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -8).isActive = true
        replyContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 50).isActive = true
        
        // setup options segment
        
        optionsSegment = UISegmentedControl(items: ["A","B","C","D","E"])
        optionsSegment.translatesAutoresizingMaskIntoConstraints = false
        
        replyContainerView.contentView.addSubview(optionsSegment)
        
        optionsSegment.topAnchor.constraint(equalTo: replyContainerView.contentView.topAnchor, constant: 10).isActive = true
        optionsSegment.heightAnchor.constraint(equalToConstant: 30).isActive = true
        optionsSegment.leadingAnchor.constraint(equalTo: replyContainerView.contentView.leadingAnchor, constant: 10).isActive = true
        optionsSegment.trailingAnchor.constraint(equalTo: replyContainerView.contentView.trailingAnchor, constant: -10).isActive = true
        optionsSegment.addTarget(self, action: #selector(selectionChanged), for: .valueChanged)
        optionsSegment.selectedSegmentIndex = 0
        
        // setup reply text view
        
        responseTextView = RSKPlaceholderTextView()
        responseTextView.placeholder = "your message here..."
        responseTextView.backgroundColor = .clear
        responseTextView.translatesAutoresizingMaskIntoConstraints = false
        replyContainerView.contentView.addSubview(responseTextView)
        
        responseTextView.topAnchor.constraint(equalTo: optionsSegment.bottomAnchor, constant: 15).isActive = true
        responseTextView.leadingAnchor.constraint(equalTo: optionsSegment.leadingAnchor).isActive = true
        responseTextView.trailingAnchor.constraint(equalTo: optionsSegment.trailingAnchor).isActive = true
        responseTextView.bottomAnchor.constraint(equalTo: replyContainerView.contentView.bottomAnchor, constant: 60).isActive = true
        
        responseTextView.font = UIFont.systemFont(ofSize: 20)
        
        view.layoutIfNeeded()
        
        // load previous reply, if any
        if let opt = post.responseOption, let con = post.responseContent {
            optionsSegment.selectedSegmentIndex = ["A","B","C","D","E"].index(of: opt)!
            responseTextView.text = con
        }
    }
    
    private func setReplyUIHidden() {
        responseTextView.resignFirstResponder()
        scrollView.animateVisible()
        isReplying = false
        leftButton.animateHidden()
        if scrollView.contentOffset.y + scrollView.adjustedContentInset.top > 0 {
            rightButton.animateHidden()
            lowerButton.animateVisible()
        }
        replyContainerView.animateHidden()
        view.gestureRecognizers?.forEach {
            $0.isEnabled = true
        }
    }
    
    private func setReplyUIVisible() {
        setupReplyUI()
        scrollView.animateHidden()
        isReplying = true
        lowerButton.animateHidden()
        leftButton.animateVisible()
        rightButton.animateVisible()
        replyContainerView.animateVisible()
        view.gestureRecognizers?.forEach {
            $0.isEnabled = false
        }
    }
    
    var isReplying = false
    
    @objc func rightButtonClicked() {
        if isReplying {
            let alr = UIAlertController(title: "Processing", message: "please wait for the reply to be sent", preferredStyle: .alert)
            responseTextView.resignFirstResponder()
            alr.present(in: self)
            let hasOption = optionsSegment.selectedSegmentIndex != UISegmentedControlNoSegment
            let option = hasOption ? optionsSegment.titleForSegment(at: optionsSegment.selectedSegmentIndex)!:""
            post.postResponse(option: option, content: responseTextView.text) { error in
                DispatchQueue.main.async {
                    if error != nil {
                        alr.title = "Failed to send"
                        alr.message = error!.localizedDescription
                    }
                    else {
                        alr.title = "Reply Sent"
                        alr.message = ""
                        self.setReplyUIHidden()
                    }
                    alr.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                }
            }
        }
        else {
            setReplyUIVisible()
        }
    }
    
    @objc func selectionChanged() {
        selectionFeedback()
    }
    
    fileprivate var startingVal: CGFloat?
    fileprivate var startingPoint: CGPoint?
    fileprivate var isAtTop = false
    
}

extension ViewPostController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return post.attachments!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "fileCell") as! FileCell
        cell.update(with: post.attachments!.allObjects[indexPath.row] as! Attachment)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let file = post.attachments!.allObjects[indexPath.row] as! Attachment
        if file.type == .embedding {
            SFSafariViewController(url: file.url).present(in: self)
            return
        }
        if file.isDownloaded {
            let ctr = FilePreviewController()
            ctr.file = (post.attachments!.allObjects[indexPath.row] as! Attachment).cacheURL
            ctr.present(in: self)
        }
        else {
            let alert = UIAlertController(title: "Downloading", message: "initializing download...", preferredStyle: .alert)
            alert.present(in: self)
            file.download(progress: { progress in
                DispatchQueue.main.async {
                    alert.message = String(format: "%.1f", progress * 100)
                }
            }) { error in
                DispatchQueue.main.async {
                    if error != nil {
                        alert.title = "Failed"
                        alert.message = error!.localizedDescription
                        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    }
                    else {
                        alert.dismiss(animated: true) {
                            let ctr = FilePreviewController()
                            ctr.file = (self.post.attachments!.allObjects[indexPath.row] as! Attachment).cacheURL
                            ctr.present(in: self)
                        }
                    }
                }
            }
        }
    }
    
    
}

extension ViewPostController: UIGestureRecognizerDelegate {
    
    var interactor: Interactor {
        return (transitioningDelegate as! BoardTableController).interactor
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return !postContentTextView.isFirstResponder
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // only update send buttons if post can respond & is displaying post content
        guard post.canRespond && !isReplying else {
            return
        }
        let istop = scrollView.contentOffset.y + scrollView.adjustedContentInset.top <= 0
        if !istop && rightButton.alpha == 1 {
            rightButton.animateHidden()
            lowerButton.animateVisible()
        }
        else if istop && rightButton.alpha == 0 {
            rightButton.animateVisible()
            lowerButton.animateHidden()
        }
    }
    
    @objc func pan(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .began:
            startingVal = sender.location(in: nil).y
            interactor.hasStarted = true
        case .changed:
            let currentY = sender.location(in: nil).y
            
            if interactor.hasStarted {
                
                // calc local properties
                let isup = sender.velocity(in: nil).y > 0
                let istop = scrollView.contentOffset.y + scrollView.adjustedContentInset.top <= 0
                if istop {
                    if !isAtTop {
                        isAtTop = true
                        // start transition when move to top & move up
                        if isup && !isBeingDismissed {
                            dismiss(animated: true)
                            startingVal = currentY
                            startingPoint = sender.translation(in: view)
                        }
                    }
                    guard isBeingDismissed else {return}
                    
                    // update progress while at top
                    let progress = min((currentY-startingVal!) / (UIScreen.main.bounds.height/1.5), 1)
                    interactor.update(progress)
                    
                    view.frame.origin = sender.translation(in: view).applying(CGAffineTransform(translationX: -startingPoint!.x, y: -startingPoint!.y))
                }
                else {
                    if isAtTop {
                        // cancel transition when leave top
                        isAtTop = false
                        interactor.shouldFinish = false
                        interactor.cancel()
                        
                        UIView.animate(withDuration: 0.2) {
                            self.view.frame.origin = .zero
                        }
                    }
                }
            }
        default:
            let finished = interactor.complete(extraCondition: sender.velocity(in: nil).y > 600 &&
                                                interactor.percentComplete >= 0.1)
            if !finished {
                // restore if dismissal cancelled
                UIView.animate(withDuration: 0.2) {
                    self.view.frame.origin = .zero
                }
            }
            isAtTop = false
            startingVal = nil
        }
    }

}

fileprivate let subfont = UIFont.systemFont(ofSize: 13)
