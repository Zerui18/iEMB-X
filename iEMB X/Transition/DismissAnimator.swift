//
//  DismissAnimator.swift
//  iEMB X
//
//  Created by Chen Changheng on 3/10/17.
//  Copyright © 2017 Chen Zerui. All rights reserved.
//

import UIKit


class DismissAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    enum AnimationType {
        case close, shrink
    }
    
    private let animation: AnimationType
    
    init(animation: AnimationType) {
        self.animation = animation
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return Constants.dismissTransitionDuraction
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        guard let fromVC = transitionContext.viewController(forKey: .from) as? ViewPostControllerLegacy,
            let toVC = transitionContext.viewController(forKey: .to) else {
            return
        }
        
        let scrollView = fromVC.scrollView!
        scrollView.showsVerticalScrollIndicator = false
        let containerView = transitionContext.containerView
        toVC.view.frame = containerView.bounds
        containerView.insertSubview(toVC.view, belowSubview: fromVC.view)
        let screenBounds = UIScreen.main.bounds
        
        let darkenEffect = UIView(frame: screenBounds)
        darkenEffect.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.9469355194)
        containerView.insertSubview(darkenEffect, belowSubview: fromVC.view)
        
        UIView.animateKeyframes(withDuration: transitionDuration(using: transitionContext), delay: 0, options: [], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.35) {
                fromVC.backgroundView.alpha = 0.3
                fromVC.view.layer.cornerRadius = 40
                darkenEffect.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.195037412)
            }
            UIView.addKeyframe(withRelativeStartTime: 0.35, relativeDuration: 0.65) {
                fromVC.view.alpha = 0
                darkenEffect.backgroundColor = .clear
            }
            if self.animation == .shrink {
                UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1) {
                    fromVC.view.layer.transform = CATransform3DScale(fromVC.view.layer.transform, 0.1, 0.1, 1)
                }
            }
        }, completion: { finished in
            darkenEffect.removeFromSuperview()
            if transitionContext.transitionWasCancelled {
                if self.animation == .shrink {
                    fromVC.view.layer.transform = CATransform3DScale(fromVC.view.layer.transform, 1, 1, 1)
                }
                toVC.view.removeFromSuperview()
                scrollView.showsVerticalScrollIndicator = true
            }
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
    
}
