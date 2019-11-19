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
import Components

@available(iOS 13, *)
class ViewPostController: UIViewController {
    
    //MARK: - Properties
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var postContentTextView: UITextView!
    @IBOutlet weak var attachmentsLabel: UILabel!
    @IBOutlet weak var attachmentsTable: UITableView!
    @IBOutlet weak var attachmentsTableHContraint: NSLayoutConstraint!
    @IBOutlet weak var replyButton: UIButton!
    
    private lazy var tap = UITapGestureRecognizer(target: self, action: #selector(contentTapped(_:)))
    private lazy var replyVC = ReplyViewController(post: post)
    
    // The current post displayed by this vc, internal since it needs to be set by parent vc.
    var post: Post!
    
    //MARK: - ViewController Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    //MARK: - Methods
    
    private func setupUI() {
        attachmentsLabel.isHidden = true
        
        postContentTextView.textDragInteraction?.isEnabled = false
        postContentTextView.addGestureRecognizer(tap)
        
        scrollView.showsVerticalScrollIndicator = false
        
        attachmentsTable.tableFooterView = UIView()
        attachmentsTable.rowHeight = 50
        
        replyButton.layer.cornerRadius = 24
        replyButton.backgroundColor = UIColor.systemFill
    }
    
    private func loadMessage() {
        if post.content != nil {
            updateUI()
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
                        self.updateUI()
                    }
                }
            }
        }
    }
    
    func updateUI() {
        attachmentsTableHContraint.constant = CGFloat(post.attachments!.count * 50)
        if post.attachments!.count > 0 {
            attachmentsLabel.isHidden = false
            attachmentsTable.reloadSections([0], with: .none)
        }
        if post.canReply {
            replyButton.isUserInteractionEnabled = true
            UIView.animate(withDuration: 0.5) {
                self.replyButton.alpha = 1
            }
        }
        postContentTextView.attributedText = post.compoundMessage()
        view.layoutIfNeeded()
    }
    
    
    @objc func contentTapped(_ sender: UITapGestureRecognizer) {
        postContentTextView.resignFirstResponder()
        
        guard post.content != nil else {
            return
        }
        
        
        let index = postContentTextView.layoutManager.characterIndex(for: sender.location(in: postContentTextView), in: postContentTextView.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        
        guard index < postContentTextView.attributedText.length,
            let attachment = (postContentTextView.attributedText.attribute(.attachment, at: index, effectiveRange: nil) ?? postContentTextView.attributedText.attribute(.attachment, at: index-1, effectiveRange: nil)) as? NSTextAttachment,
            let image = attachment.image(forBounds: attachment.bounds, textContainer: postContentTextView.textContainer, characterIndex: index) else {
                return
        }
        
        let tempImage = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(attachment.fileWrapper?.filename ?? "Image.png")
        try! image.pngData()!.write(to: tempImage)
        
        let ctr = FilePreviewController()
        ctr.file = tempImage
        ctr.deletesFileOnDismiss = true
        ctr.present(in: self)
    }
    
    @IBAction func presentReplyVC(_ sender: Any) {
        replyVC.present(in: self)
    }
}

//MARK: - UITableView DataSource & Delegate Methods
@available(iOS 13, *)
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
        guard file.type != .embedding else {
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
                    
                    guard error == nil else {
                        alert.title = "Failed"
                        alert.message = error!.localizedDescription
                        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                        return
                    }
                    
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
