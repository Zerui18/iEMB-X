//
//  Functions.swift
//  iEMB X
//
//  Created by Chen Changheng on 13/9/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import UIKit
import QuickLook
import UserNotifications

func simpleAlert(title: String, message: String, block: ((UIAlertAction)->Void)? = nil)-> UIAlertController{
    let al = UIAlertController(title: title, message: message, preferredStyle: .alert)
    al.addAction(UIAlertAction(title: "OK", style: .cancel, handler: block))
    return al
}

func saveContext(completion: ((Error?)->Void)? = nil){
    do{
        try context.save()
    }
    catch{
        completion?(error)
    }
    completion?(nil)
}

func notificationFeedback(ofType type: UINotificationFeedbackType = .success){
    DispatchQueue.main.async {
        notificationFeedbackGenerator.notificationOccurred(type)
        notificationFeedbackGenerator.prepare()
    }
}

func selectionFeedback(){
    DispatchQueue.main.async {
        selectionFeedbackGenerator.selectionChanged()
        selectionFeedbackGenerator.prepare()
    }
}

func scheduleNotification(withTitle title: String, body: String){
    let content: UNMutableNotificationContent = UNMutableNotificationContent()
    content.title = title
    content.body = body
    content.sound = UNNotificationSound.default()
    UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "\(arc4random())_noti", content: content, trigger: nil))
}

func getHTML(request: URLRequest, completion: @escaping (String?, Error?)->Void){
    URLSession.shared.dataTask(with: request) { (data, res, err) in
        if err != nil{
            completion(nil, err)
        }
        else{
            print("initial attempt: ", res!.expectedContentLength)
            if res!.expectedContentLength == 1042 || res!.expectedContentLength == 2044{
                EMBReader.reLogin(then: { (success, error) in
                    if error == nil{
                        URLSession.shared.dataTask(with: request){ (data, res, err) in
                            if data != nil{
                                completion(String(data: data!, encoding: .utf8), nil)
                            }
                            else{
                                completion(nil, err)
                            }
                        }.resume()
                    }
                    else{
                        completion(nil, error)
                    }
                })
            }
            else{
                completion(String(data: data!, encoding: .utf8), nil)
            }
        }
    }.resume()
}
