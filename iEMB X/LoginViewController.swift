//
//  LoginViewController.swift
//  iEMB X
//
//  Created by Chen Changheng on 13/9/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import UIKit
import EMBClient

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask{
        return .portrait
    }

    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        loginButton.layer.cornerRadius = 10
        
        
        if let oldU = userDefaults.string(forKey: "u") {
            usernameField.text = oldU
        }
        
        usernameField.delegate = self
        passwordField.delegate = self
        
        loginButton.addTarget(self, action: #selector(login), for: .touchUpInside)
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissTextField)))
    }
    
    @objc func dismissTextField() {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.tag == 0 {
            passwordField.becomeFirstResponder()
        }
        else {
            textField.resignFirstResponder()
        }
        return true
    }
    
    @objc func login() {
        if let u = usernameField.text, let p = passwordField.text, !u.isEmpty, !p.isEmpty {
            view.isUserInteractionEnabled = false
            activityIndicator.startAnimating()
            UIView.animate(withDuration: 0.3) {
                self.usernameField.alpha = 0.0
                self.passwordField.alpha = 0.0
                self.loginButton.alpha = 0.0
            }
            
            EMBClient.shared.login(username: u, password: p) {success, error in
                DispatchQueue.main.async {
                    if success {
                        try! EMBClient.shared.resetCache()
                        backgroungFetchInterval = 30 * 60
                        self.dismiss(animated: true) {
                            menuViewController.presentedBoardVC.reloadBoard()
                        }
                    }
                    else {
                        notificationFeedback(ofType: .error)
                        self.activityIndicator.stopAnimating()
                        UIView.animate(withDuration: 0.3) {
                            self.loginButton.alpha = 1.0
                            self.usernameField.alpha = 1.0
                            self.passwordField.alpha = 1.0
                        }
                        self.view.isUserInteractionEnabled = true
                    }
                }
            }
        }
    }

}
