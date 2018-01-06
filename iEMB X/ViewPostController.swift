//
//  ViewPostController.swift
//  iEMB X
//
//  Created by Chen Changheng on 15/9/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import UIKit
import SafariServices
import Custom_UI

class ViewPostController: UIViewController{
    
    override var prefersStatusBarHidden: Bool{
        return true
    }
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var postContainerView: UIVisualEffectView!
    @IBOutlet weak var postContentTextView: UITextView!
    @IBOutlet weak var tableView: UITableView!
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
        if let selected = tableView.indexPathForSelectedRow{
            transitionCoordinator?.animate(alongsideTransition: { context in
                self.tableView.deselectRow(at: selected, animated: context.isAnimated)
            })
        }
    }
    
    lazy var tap = UITapGestureRecognizer(target: self, action: #selector(contentTapped(_:)))
    
    lazy var downPan = UIPanGestureRecognizer(target: self, action: #selector(pan(_:)))
    
    lazy var leftPan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(leftEdgePan(_:)))
    
    lazy var rightPan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(rightEdgePan(_:)))
    
    private func setupUI(){
        if #available(iOS 11.0, *) {
            postContentTextView.textDragInteraction?.isEnabled = false
        }
        scrollView.delegate = self
        tableView.tableFooterView = UIView()
        
        tableView.rowHeight = 50
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
        
        leftPan.edges = .left
        view.addGestureRecognizer(leftPan)
        
        rightPan.edges = .right
        view.addGestureRecognizer(rightPan)
        
        downPan.require(toFail: leftPan)
        downPan.require(toFail: rightPan)
        
        rightPan.require(toFail: leftPan)
    }
    
    private func loadMessage(){
        if post.content != nil{
            updateUI()
        }
        else{
            post.loadContent{[weak self] error in
                if self == nil{
                    return
                }
                DispatchQueue.main.async {
                    if error != nil{
                        self!.postContentTextView.attributedText = NSAttributedString(string: "Failed to load Post. "+error!.localizedDescription, attributes: [.font: UIFont.systemFont(ofSize: 28, weight: .bold)])
                    }
                    else{
                        self!.updateUI()
                    }
                }
            }
        }
    }
    
    func updateUI(){
        postContentTextView.attributedText = post.compoundMessage()
        tableView.reloadData()
        tableViewHeightConstraint.constant = CGFloat(post.attachments!.count * 50) + 5
        if post.canRespond{
            rightButton.animateVisible()
        }
        labelHeightConstraint.constant = post.attachments!.count > 0 ? 30:0
    }
    
    
    @objc func leftButtonClicked(){
        setReplyUIHidden()
    }
    
    @objc func contentTapped(_ sender: UITapGestureRecognizer){
        postContentTextView.resignFirstResponder()
        if post.content != nil{
            let index = postContentTextView.layoutManager.characterIndex(for: sender.location(in: postContentTextView), in: postContentTextView.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
            if index < postContentTextView.attributedText.length,
                let attachment = (postContentTextView.attributedText.attribute(.attachment, at: index, effectiveRange: nil) ?? postContentTextView.attributedText.attribute(.attachment, at: index-1, effectiveRange: nil)) as? NSTextAttachment{
                if let image = attachment.image(forBounds: attachment.bounds, textContainer: postContentTextView.textContainer, characterIndex: index){
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
    
    private func setupReplyUI(){
        if replyContainerView != nil{return}
        
        // setup reply segments
        
        replyContainerView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
        
        replyContainerView.isHidden = true
        replyContainerView.translatesAutoresizingMaskIntoConstraints = false
        replyContainerView.clipsToBounds = true
        replyContainerView.layer.cornerRadius = 10
        view.addSubview(replyContainerView)
        
        replyContainerView.topAnchor.constraint(equalTo: rightButton.bottomAnchor, constant: 16).isActive = true
        replyContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 17).isActive = true
        replyContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -17).isActive = true
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
        
        view.setNeedsLayout()
        
        // load previous reply, if any
        if let opt = post.responseOption, let con = post.responseContent{
            optionsSegment.selectedSegmentIndex = ["A","B","C","D","E"].index(of: opt)!
            responseTextView.text = con
        }
    }
    
    private func setReplyUIHidden(){
        responseTextView.resignFirstResponder()
        scrollView.animateVisible()
        isReplying = false
        leftButton.animateHidden()
        if scrollView.contentOffset.y <= 0{
            rightButton.animateVisible()
        }
        replyContainerView.animateHidden()
        view.gestureRecognizers?.forEach{
            $0.isEnabled = true
        }
    }
    
    private func setReplyUIVisible(){
        setupReplyUI()
        scrollView.animateHidden()
        isReplying = true
        leftButton.animateVisible()
        rightButton.animateVisible()
        replyContainerView.animateVisible()
        view.gestureRecognizers?.forEach{
            $0.isEnabled = false
        }
    }
    
    var isReplying = false
    
    @objc func rightButtonClicked(){
        if isReplying{
            let alr = UIAlertController(title: "Processing", message: "please wait for the reply to be sent", preferredStyle: .alert)
            responseTextView.resignFirstResponder()
            alr.present(in: self)
            let hasOption = optionsSegment.selectedSegmentIndex != UISegmentedControlNoSegment
            let option = hasOption ? optionsSegment.titleForSegment(at: optionsSegment.selectedSegmentIndex)!:""
            post.postResponse(option: option, content: responseTextView.text){ error in
                DispatchQueue.main.async {
                    if error != nil{
                        alr.title = "Failed to send"
                        alr.message = error!.localizedDescription
                    }
                    else{
                        alr.title = "Reply Sent"
                        alr.message = ""
                        self.setReplyUIHidden()
                    }
                    alr.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                }
            }
        }
        else{
            setReplyUIVisible()
        }
    }
    
    @objc func selectionChanged() {
        selectionFeedback()
    }
    
}

extension ViewPostController: UITableViewDataSource, UITableViewDelegate{
    
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
        if file.type == .embed{
            SFSafariViewController(url: file.url).present(in: self)
            return
        }
        if file.isDownloaded{
            let ctr = FilePreviewController()
            ctr.file = (post.attachments!.allObjects[indexPath.row] as! Attachment).cacheURL
            ctr.present(in: self)
        }
        else{
            let alert = UIAlertController(title: "Downloading", message: "initializing download...", preferredStyle: .alert)
            alert.present(in: self)
            file.download(progress: { progress in
                DispatchQueue.main.async {
                    alert.message = "\(round(progress*100))%"
                }
            }) { error in
                DispatchQueue.main.async {
                    if error != nil{
                        alert.title = "Failed"
                        alert.message = error!.localizedDescription
                        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    }
                    else{
                        alert.dismiss(animated: true){
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

fileprivate var startingVal: CGFloat?
fileprivate var isUpward = false
fileprivate var isAtTop = false

extension ViewPostController: UIGestureRecognizerDelegate{
    
    var interactor: Interactor{
        return (transitioningDelegate as! BoardTableController).interactor
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return !postContentTextView.isFirstResponder
    }
    
    @objc func pan(_ sender: UIPanGestureRecognizer){
        switch sender.state{
        case .began:
            startingVal = sender.location(in: nil).x
            interactor.hasStarted = true
        case .changed:
            let currentY = sender.location(in: nil).y
            if interactor.hasStarted{
                // calc local properties
                let isup = sender.velocity(in: view).y > 0
                let istop = scrollView.contentOffset.y <= 0
                if istop{
                    if !isAtTop{
                        isAtTop = true
                        // start transition when move to top & move up
                        if !isUpward && isup{
                            dismiss(animated: true)
                            startingVal = currentY
                        }
                        isUpward = isup
                        if post.canRespond{
                            rightButton.animateVisible()
                            lowerButton.animateHidden()
                        }
                    }
                    // update progress while at top
                    let progress = min((currentY-startingVal!)/(view.bounds.height/1.5), 1)
                    interactor.update(progress)
                }
                else{
                    if isAtTop{
                        // cancel transition when leave top
                        isAtTop = false
                        isUpward = false
                        interactor.shouldFinish = false
                        interactor.cancel()
                        if post.canRespond{
                            rightButton.animateHidden()
                            lowerButton.animateVisible()
                        }
                    }
                }
            }
        default:
            interactor.complete(extraCondition: sender.velocity(in: nil).y > 400)
            // reset stats
            isAtTop = false
            isUpward = false
            startingVal = nil
        }
    }
    
    @objc func leftEdgePan(_ sender: UIScreenEdgePanGestureRecognizer){
        switch  sender.state {
        case .began:
            startingVal = sender.location(in: nil).x
            interactor.hasStarted = true
            dismiss(animated: true)
        case .changed:
            if let startingVal = startingVal{
                let currentX = sender.location(in: nil).x
                let xOffset = currentX-startingVal
                let progress = min(xOffset/view.bounds.width*2, 1)
                interactor.update(progress)
            }
        default:
            interactor.complete(extraCondition: sender.velocity(in: nil).x > 300)
            // reset stats
            startingVal = nil
        }
    }
    
    @objc func rightEdgePan(_ sender: UIScreenEdgePanGestureRecognizer){
        switch  sender.state {
        case .began:
            startingVal = sender.location(in: nil).x
            interactor.hasStarted = true
            dismiss(animated: true)
        case .changed:
            if let startingVal = startingVal{
                let currentX = sender.location(in: nil).x
                let xOffset = startingVal-currentX
                let progress = min(xOffset/view.bounds.width*2, 1)
                interactor.update(progress)
            }
        default:
            interactor.complete(extraCondition: sender.velocity(in: nil).x < -300)
            // reset stats
            startingVal = nil
        }
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag)
        scrollView.contentOffset = CGPoint.zero
    }
}

fileprivate let subfont = UIFont.systemFont(ofSize: 13)
