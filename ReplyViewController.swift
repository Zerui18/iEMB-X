//
//  ReplyViewController.swift
//  iEMB X
//
//  Created by Zerui Chen on 19/11/19.
//  Copyright © 2019 Chen Zerui. All rights reserved.
//

import UIKit
import EMBClient
import Components

@available(iOS 13.0, *)
class ReplyViewController: UIViewController {
    
    let post: Post
    
    // MARK: UI Components
    let replyLabel = UILabel()
    let sendButton = UIButton()
    let optionsSegment = UISegmentedControl(items: ["A","B","C","D","E"])
    let responseTextView = RSKPlaceholderTextView()
    
    // MARK: Init
    init(post: Post) {
        self.post = post
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // setup big reply label
        replyLabel.translatesAutoresizingMaskIntoConstraints = false
        replyLabel.text = "Reply"
        replyLabel.font = .boldSystemFont(ofSize: 32)
        view.addSubview(replyLabel)
        replyLabel.topAnchor.constraint(equalTo: view.topAnchor, constant: 16).isActive = true
        replyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
      
        // setup send button
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.setImage(UIImage(named: "send"), for: .normal)
        sendButton.addTarget(self, action: #selector(sendReply), for: .touchUpInside)
        view.addSubview(sendButton)
        sendButton.widthAnchor.constraint(equalToConstant: 36).isActive = true
        sendButton.heightAnchor.constraint(equalToConstant: 36).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: replyLabel.centerYAnchor).isActive = true
        sendButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true
        
        // setup options segment
        optionsSegment.translatesAutoresizingMaskIntoConstraints = false
        optionsSegment.backgroundColor = .tertiarySystemFill
        view.addSubview(optionsSegment)
        optionsSegment.topAnchor.constraint(equalTo: replyLabel.bottomAnchor, constant: 16).isActive = true
        optionsSegment.heightAnchor.constraint(equalToConstant: 30).isActive = true
        optionsSegment.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        optionsSegment.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        optionsSegment.addTarget(self, action: #selector(optionChanged), for: .valueChanged)
        
        // setup reply text view
        responseTextView.font = .systemFont(ofSize: 20)
        responseTextView.placeholder = "Your message..."
        responseTextView.backgroundColor = .clear
        responseTextView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(responseTextView)
        responseTextView.topAnchor.constraint(equalTo: optionsSegment.bottomAnchor, constant: 16).isActive = true
        responseTextView.leadingAnchor.constraint(equalTo: optionsSegment.leadingAnchor).isActive = true
        responseTextView.trailingAnchor.constraint(equalTo: optionsSegment.trailingAnchor).isActive = true
        responseTextView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 60).isActive = true
        
        view.layoutIfNeeded()
        
        // select saved option
        if let option = post.responseOption {
            optionsSegment.selectedSegmentIndex = ["A","B","C","D","E"].firstIndex(of: option)!
        }
        // else select none
        else {
            optionsSegment.selectedSegmentIndex = UISegmentedControl.noSegment
        }
        responseTextView.text = post.responseContent
    }
    
    // MARK: Selector Methods
    @objc private func sendReply() {
        let alr = UIAlertController(title: "Sending", message: "in one moment...", preferredStyle: .alert)
        responseTextView.resignFirstResponder()
        alr.present(in: self)
        
        post.sendReply(option: post.responseOption ?? "", content: responseTextView.text) { error in
            
            DispatchQueue.main.async {
                alr.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                
                guard error == nil else {
                    alr.title = "Failed to send"
                    alr.message = error!.localizedDescription
                    return
                }
                
                alr.title = "Reply Sent"
                alr.message = ""
            }
        }
    }
    
    @objc private func optionChanged() {
        selectionFeedback()
        post.responseOption = optionsSegment.titleForSegment(at: optionsSegment.selectedSegmentIndex)!
    }
}
