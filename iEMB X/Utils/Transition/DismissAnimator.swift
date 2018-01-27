//
//  DismissAnimator.swift
//  iEMB X
//
//  Created by Chen Changheng on 3/10/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import UIKit


class DismissAnimator: NSObject, UIViewControllerAnimatedTransitioning{
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return Constants.dismissTransitionDuraction
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        if let fromVC = transitionContext.viewController(forKey: .from), let toVC = transitionContext.viewController(forKey: .to){
            let scrollView = (fromVC as! ViewPostController).scrollView!
            scrollView.showsVerticalScrollIndicator = false
            let containerView = transitionContext.containerView
            toVC.view.frame = containerView.bounds
            containerView.insertSubview(toVC.view, belowSubview: fromVC.view)
            let screenBounds = UIScreen.main.bounds
            
            let darkenEffect = UIView(frame: screenBounds)
            darkenEffect.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.9469355194)
            containerView.insertSubview(darkenEffect, belowSubview: fromVC.view)
            
            UIView.animateKeyframes(withDuration: transitionDuration(using: transitionContext), delay: 0, options: [], animations: {
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.35){
                    fromVC.view.layer.transform = CATransform3DMakeScale(0.73, 0.73, 0.73)
                    fromVC.view.layer.cornerRadius = 40
                    darkenEffect.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.4049845951)
                }
                UIView.addKeyframe(withRelativeStartTime: 0.35, relativeDuration: 0.65){
                    fromVC.view.layer.transform = CATransform3DTranslate(fromVC.view.layer.transform, 0, screenBounds.height/4, 0)
                    fromVC.view.alpha = 0
                    darkenEffect.backgroundColor = .clear
                }
            }, completion: {finished in
                darkenEffect.removeFromSuperview()
                if transitionContext.transitionWasCancelled{
                    toVC.view.removeFromSuperview()
                }
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                scrollView.showsVerticalScrollIndicator = true
            })
        }
    }
    
}
