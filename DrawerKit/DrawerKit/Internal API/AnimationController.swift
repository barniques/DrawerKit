import UIKit

final class AnimationController: NSObject {
    private let isPresentation: Bool
    private let configuration: DrawerConfiguration

    let presentingDrawerAnimationActions: DrawerAnimationActions
    let presentedDrawerAnimationActions: DrawerAnimationActions

    init(isPresentation: Bool,
         configuration: DrawerConfiguration,
         presentingDrawerAnimationActions: DrawerAnimationActions,
         presentedDrawerAnimationActions: DrawerAnimationActions) {
        self.isPresentation = isPresentation
        self.configuration = configuration
        self.presentingDrawerAnimationActions = presentingDrawerAnimationActions
        self.presentedDrawerAnimationActions = presentedDrawerAnimationActions
        super.init()
    }
}

extension AnimationController: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        guard let context = transitionContext else { return 0 }
        let (_, presentedVC) = viewControllers(context, isPresentation)
        return actualTransitionDuration(presentedVC, context)
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let (presentingVC, presentedVC) = viewControllers(transitionContext, isPresentation)
        if isPresentation {
            transitionContext.containerView.addSubview(presentedVC.view)            
        }

        let duration = transitionDuration(using: transitionContext)

        let (initialFrame, finalFrame) = frames(presentedVC, transitionContext)

        let containerBounds = transitionContext.containerView.bounds
        let containerViewH = containerBounds.size.height

        let geometry = AnimationSupport.makeGeometry(containerBounds: containerBounds,
                                                     startingFrame: initialFrame,
                                                     endingFrame: finalFrame,
                                                     presentingVC: presentingVC,
                                                     presentedVC: presentedVC)

        var drawerPartialH = (presentedVC as? DrawerPresentable)?.heightOfPartiallyExpandedDrawer ?? 0
        if #available(iOS 11.0, *) {
            drawerPartialH = drawerPartialH + presentedVC.view.safeAreaInsets.bottom
        }
        let partialH = GeometryEvaluator.drawerPartialH(drawerPartialHeight: drawerPartialH,
                                                        containerViewHeight: containerViewH)

        let startDrawerState = GeometryEvaluator.drawerState(for: initialFrame.origin.y,
                                                             drawerPartialHeight: partialH,
                                                             containerViewHeight: containerViewH,
                                                             configuration: configuration)

        let targetDrawerState = GeometryEvaluator.drawerState(for: finalFrame.origin.y,
                                                              drawerPartialHeight: partialH,
                                                              containerViewHeight: containerViewH,
                                                              configuration: configuration)

        let info = AnimationSupport.makeInfo(startDrawerState: startDrawerState,
                                             targetDrawerState: targetDrawerState,
                                             configuration,
                                             geometry,
                                             duration,
                                             isPresentation)
        
        let presentationVC = presentedVC.presentationController as? PresentationController
        var animatesHandleDimming = false
        var endingHandleViewAlpha: CGFloat = 0.0
        var animatesDimmingView = false
        var endingDimmingViewAlpha: CGFloat = 0.0

        if let presentation = presentationVC {
            animatesHandleDimming = presentation.configuration.handleViewConfiguration != nil
            if animatesHandleDimming {
                endingHandleViewAlpha = presentation.handleViewAlpha(at: targetDrawerState)
                presentation.handleView?.alpha = presentation.handleViewAlpha(at: startDrawerState)
            }

            animatesDimmingView = presentation.configuration.drawerDimmingConfiguration != nil
            if animatesDimmingView {
                endingDimmingViewAlpha = presentation.dimmingViewAlpha(at: targetDrawerState)
                presentation.dimmingView?.alpha = presentation.dimmingViewAlpha(at: startDrawerState)
            }
        }
        
        let presentingAnimationActions = self.presentingDrawerAnimationActions
        let presentedAnimationActions = self.presentedDrawerAnimationActions

        AnimationSupport.clientPrepareViews(presentingDrawerAnimationActions: presentingAnimationActions,
                                            presentedDrawerAnimationActions: presentedAnimationActions,
                                            info)
        presentedVC.view.frame = initialFrame

        let animation = {
            presentedVC.view.frame = finalFrame
            if animatesDimmingView { presentationVC?.dimmingView?.alpha = endingDimmingViewAlpha }
            if animatesHandleDimming { presentationVC?.handleView?.alpha = endingHandleViewAlpha }
            AnimationSupport.clientAnimateAlong(presentingDrawerAnimationActions: presentingAnimationActions,
                                                presentedDrawerAnimationActions: presentedAnimationActions,
                                                info)
        }

        let completion: (Bool) -> Void = { finished in
            if animatesHandleDimming { presentationVC?.handleView?.alpha = endingHandleViewAlpha }
            if animatesDimmingView { presentationVC?.dimmingView?.alpha = endingDimmingViewAlpha }

            let currentState = GeometryEvaluator.drawerState(for: finalFrame.origin.y,
                                                                  drawerPartialHeight: partialH,
                                                                  containerViewHeight: containerViewH,
                                                                  configuration: self.configuration)
            
            let endingPosition: DrawerAnimatingPosition = currentState == targetDrawerState ? .end: .start
            
            AnimationSupport.clientCleanupViews(presentingDrawerAnimationActions: presentingAnimationActions,
                                                presentedDrawerAnimationActions: presentedAnimationActions,
                                                endingPosition,
                                                info)
            transitionContext.completeTransition(finished)
        }
        
        self.animateWithUIView(duration: duration,
                               animation: animation,
                               completion: completion)
    }
}

private extension AnimationController {
    func actualTransitionDuration(_ controller: UIViewController,
                                  _ transitionContext: UIViewControllerContextTransitioning)
        -> TimeInterval {
            let (initialFrame, finalFrame) = frames(controller, transitionContext)

            let initialY = initialFrame.origin.y
            let finalY = finalFrame.origin.y
            let containerViewH = transitionContext.containerView.bounds.size.height

            return AnimationSupport.actualTransitionDuration(from: initialY,
                                                             to: finalY,
                                                             containerViewHeight: containerViewH,
                                                             configuration: configuration)
    }

    func frames(_ controller: UIViewController,
                _ transitionContext: UIViewControllerContextTransitioning)
        -> (initial: CGRect, final: CGRect) {
            let containerViewH = transitionContext.containerView.bounds.size.height
            let presentedFrame = transitionContext.finalFrame(for: controller)
            var dismissedFrame = presentedFrame
            dismissedFrame.origin.y = containerViewH

            let initialFrame = (isPresentation ? dismissedFrame : presentedFrame)
            let finalFrame = (isPresentation ? presentedFrame : dismissedFrame)

            return (initialFrame, finalFrame)
    }

    func viewControllers(_ transitionContext: UIViewControllerContextTransitioning,
                         _ isPresentation: Bool)
        -> (presenting: UIViewController, presented: UIViewController) {
            let presentingKey = (isPresentation ?
                UITransitionContextViewControllerKey.from :
                UITransitionContextViewControllerKey.to)

            let presentedKey = (isPresentation ?
                UITransitionContextViewControllerKey.to :
                UITransitionContextViewControllerKey.from)

            let presentingVC = transitionContext.viewController(forKey: presentingKey)!
            let presentedVC = transitionContext.viewController(forKey: presentedKey)!

            return (presentingVC, presentedVC)
    }
}

private extension AnimationController {
    
    func animateWithUIView(duration: TimeInterval,
                           animation: @escaping ()-> Void,
                           completion: ((Bool)-> Void)? ) {
        UIView.animate(withDuration: duration,
                       delay: 0,
                       options: [.allowUserInteraction, .beginFromCurrentState],
                       animations: animation,
                       completion: { (finished) in
                        completion?(finished)
        })
    }

}
