//
//  PresentAnimator.swift
//  iEMB X
//
//  Created by Chen Changheng on 4/10/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import UIKit

class PresentAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return Constants.presentTransitionDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        guard let toVC = transitionContext.viewController(forKey: .to) as?ViewPostController else {
            return
        }
        
        let containerView = transitionContext.containerView
        containerView.addSubview(toVC.view)
        let screenBounds = UIScreen.main.bounds
        
        let darkenEffect = UIView(frame: screenBounds)
        darkenEffect.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0)
        containerView.insertSubview(darkenEffect, belowSubview: toVC.view)
        
        toVC.view.transform = CGAffineTransform(scaleX: 0.73, y: 0.73).translatedBy(x: 0, y: screenBounds.height/2)
        toVC.backgroundView.alpha = 0.3
        toVC.view.alpha = 0.3
        toVC.view.layer.cornerRadius = 40
        
        UIView.animateKeyframes(withDuration: transitionDuration(using: transitionContext), delay: 0, options: [], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.65) {
                toVC.view.alpha = 1
                toVC.backgroundView.alpha = 1
                toVC.view.transform = toVC.view.transform.translatedBy(x: 0, y: -screenBounds.height/2)
                darkenEffect.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.4049845951)
            }
            UIView.addKeyframe(withRelativeStartTime: 0.65, relativeDuration: 0.35) {
                toVC.view.transform = CGAffineTransform(scaleX: 1, y: 1)
                toVC.view.layer.cornerRadius = 0
                darkenEffect.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.95)
            }
        }, completion: {_ in
            darkenEffect.removeFromSuperview()
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
}
