//
//  LoginViewController.swift
//  iEMB X
//
//  Created by Chen Changheng on 13/9/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import UIKit
import Components
import EMBClient

class LoginViewController: UIViewController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask{
        return .portrait
    }

    // MARK: Private Properties
    private let bgImageView = UIImageView(image: #imageLiteral(resourceName: "hci_dark"))
    private let iconImageView = UIImageView(image: #imageLiteral(resourceName: "icon_light"))
    private let usernameField = AuthView(frame: .zero)
    private let passwordField = AuthView(frame: .zero)
    private let loginButton = UIButton(type: .custom)
    private let spinner = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
    
    // MARK: Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: Private Methods
    private func setupUI() {
        
        usernameField.translatesAutoresizingMaskIntoConstraints = false
        passwordField.translatesAutoresizingMaskIntoConstraints = false
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        bgImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        spinner.translatesAutoresizingMaskIntoConstraints = false
        
        usernameField.placeholder = "username"
        usernameField.icon = #imageLiteral(resourceName: "ic_person")
        usernameField.nextView = passwordField
        passwordField.placeholder = "password"
        passwordField.icon = #imageLiteral(resourceName: "ic_lock")
        passwordField.isSecureTextEntry = true
        
        loginButton.setTitle("Login", for: UIControlState())
        loginButton.backgroundColor = #colorLiteral(red: 0.937254902, green: 0.937254902, blue: 0.937254902, alpha: 0.8998287671)
        loginButton.setTitleColor(.darkGray, for: .normal)
        loginButton.setTitleColor(.black, for: .highlighted)
        loginButton.titleLabel?.font = UIFont.systemFont(ofSize: 26, weight: .medium)
        loginButton.clipsToBounds = true
        
        view.addSubview(bgImageView)
        view.addSubview(iconImageView)
        view.addSubview(usernameField)
        view.addSubview(passwordField)
        view.addSubview(loginButton)
        view.addSubview(spinner)
        
        // setup constraints
        bgImageView.widthAnchor.constraint(equalTo: bgImageView.heightAnchor, multiplier: bgImageView.bounds.width / bgImageView.bounds.height).isActive = true
        bgImageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        bgImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        bgImageView.contentMode = .scaleAspectFit
        
        iconImageView.widthAnchor.constraint(equalTo: view.safeAreaLayoutGuide.widthAnchor, multiplier: 0.33).isActive = true
        iconImageView.heightAnchor.constraint(equalTo: iconImageView.widthAnchor, multiplier: iconImageView.bounds.height/iconImageView.bounds.width).isActive = true
        iconImageView.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        iconImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: view.bounds.height/10).isActive = true
        
        usernameField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        usernameField.bottomAnchor.constraint(equalTo: passwordField.topAnchor, constant: -20).isActive = true
        usernameField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 46).isActive = true
        usernameField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -46).isActive = true
        
        passwordField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        passwordField.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor, constant: 20).isActive = true
        passwordField.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 46).isActive = true
        passwordField.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -46).isActive = true
        
        loginButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 40).isActive = true
        loginButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        loginButton.widthAnchor.constraint(equalTo: passwordField.widthAnchor).isActive = true
        loginButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        spinner.centerXAnchor.constraint(equalTo: loginButton.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: loginButton.centerYAnchor).isActive = true
        
        
        // layout and round corners
        view.layoutIfNeeded()
        loginButton.layer.cornerRadius = loginButton.bounds.height / 2
        
        // setup actions
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(viewTapped)))
        loginButton.addTarget(self, action: #selector(login), for: .touchUpInside)
    }
    
    @objc private func viewTapped() {
        view.endEditing(true)
    }
    
    @objc func login() {
        guard let username = usernameField.text, let password = passwordField.text,
                !(username.isEmpty || password.isEmpty) else {
            return
        }
        
        view.isUserInteractionEnabled = false
        spinner.startAnimating()
        UIView.animate(withDuration: 0.3) {
            self.loginButton.alpha = 0.0
        }
        
        EMBClient.shared.login(username: username, password: password) { success, error in
            DispatchQueue.main.async {
                guard success else {
                    notificationFeedback(ofType: .error)
                    self.spinner.stopAnimating()
                    UIView.animate(withDuration: 0.3) {
                        self.passwordField.alpha = 1.0
                    }
                    self.view.isUserInteractionEnabled = true
                    return
                }
                
                try! EMBClient.shared.resetCache()
                userDefaults.removeObject(forKey: "lastRefreshed_1048")
                backgroungFetchInterval = 30 * 60
            }
        }
    }

}
