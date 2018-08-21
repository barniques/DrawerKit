import UIKit

extension PresentationController {
    func animateTransition(to endingState: DrawerState, animateAlongside: (() -> Void)? = nil, completion: (() -> Void)? = nil, forceUIViewAnimation: Bool = false) {
        let startingState = currentDrawerState

        let maxCornerRadius = maximumCornerRadius
        let endingCornerRadius = cornerRadius(at: endingState)

        let (startingPositionY, endingPositionY) = positionsY(startingState: startingState,
                                                              endingState: endingState)

        let duration = AnimationSupport.actualTransitionDuration(from: startingPositionY,
                                                                 to: endingPositionY,
                                                                 containerViewHeight: containerViewHeight,
                                                                 configuration: configuration)
        
        let presentingVC = presentingViewController
        let presentedVC = presentedViewController

        let presentedViewFrame = presentedView?.frame ?? .zero

        var startingFrame = presentedViewFrame
        startingFrame.origin.y = startingPositionY

        var endingFrame = presentedViewFrame
        endingFrame.origin.y = endingPositionY

        let geometry = AnimationSupport.makeGeometry(containerBounds: containerViewBounds,
                                                     startingFrame: startingFrame,
                                                     endingFrame: endingFrame,
                                                     presentingVC: presentingVC,
                                                     presentedVC: presentedVC)

        let info = AnimationSupport.makeInfo(startDrawerState: startingState,
                                             targetDrawerState: endingState,
                                             configuration,
                                             geometry,
                                             duration,
                                             endingPositionY < startingPositionY)

        
        let autoAnimatesHandleDimming = configuration.handleViewConfiguration?.autoAnimatesDimming ?? false
        let startingHandleViewAlpha = handleViewAlpha(at: startingState)
        let endingHandleViewAlpha = handleViewAlpha(at: endingState)
        if autoAnimatesHandleDimming {
            self.handleView?.alpha = startingHandleViewAlpha
        }
        
        let autoAnimatesDimmingView = configuration.drawerDimmingConfiguration != nil
        let startingDimmingViewAlpha = dimmingViewAlpha(at: startingState)
        let endingDimmingViewAlpha = dimmingViewAlpha(at: endingState)
        if autoAnimatesDimmingView {
            self.dimmingView?.alpha = startingDimmingViewAlpha
        }
        
        let presentingAnimationActions = self.presentingDrawerAnimationActions
        let presentedAnimationActions = self.presentedDrawerAnimationActions

        AnimationSupport.clientPrepareViews(presentingDrawerAnimationActions: presentingAnimationActions,
                                            presentedDrawerAnimationActions: presentedAnimationActions,
                                            info)

        targetDrawerState = endingState

        let animation = {
            self.currentDrawerY = endingPositionY
            if autoAnimatesHandleDimming { self.handleView?.alpha = endingHandleViewAlpha }
            if autoAnimatesDimmingView { self.dimmingView?.alpha = endingDimmingViewAlpha }
            if maxCornerRadius != 0 { self.currentDrawerCornerRadius = endingCornerRadius }
            AnimationSupport.clientAnimateAlong(presentingDrawerAnimationActions: presentingAnimationActions,
                                                presentedDrawerAnimationActions: presentedAnimationActions,
                                                info)
            animateAlongside?()
        }

        let completion: (DrawerAnimatingPosition) -> Void = { endingPosition in
            
            if autoAnimatesHandleDimming {
                self.handleView?.alpha = endingPosition == .end ? endingHandleViewAlpha : startingHandleViewAlpha
            }
            if autoAnimatesDimmingView {
                self.dimmingView?.alpha = endingPosition == .end ? endingDimmingViewAlpha : startingDimmingViewAlpha
            }

            let isStartingStateCollapsed = (startingState == .collapsed)
            let isEndingStateCollapsed = (endingState == .collapsed)

            let shouldDismiss =
                (isStartingStateCollapsed && endingPosition == .start) ||
                    (isEndingStateCollapsed && endingPosition == .end)

            if shouldDismiss {
                self.presentedViewController.dismiss(animated: true)
            }

            let isStartingStateCollapsedOrFullyExpanded =
                (startingState == .collapsed || startingState == .fullyExpanded)

            let isEndingStateCollapsedOrFullyExpanded =
                (endingState == .collapsed || endingState == .fullyExpanded)

            let shouldSetCornerRadiusToZero =
                ((isEndingStateCollapsedOrFullyExpanded && endingPosition == .end) ||
                    (isStartingStateCollapsedOrFullyExpanded && endingPosition == .start)) &&
                    (self.configuration.cornerAnimationOption != .always)

            if maxCornerRadius != 0 && shouldSetCornerRadiusToZero {
                self.currentDrawerCornerRadius = 0
            }

            if endingPosition != .end {
                self.targetDrawerState = GeometryEvaluator.drawerState(for: self.currentDrawerY,
                                                                       drawerPartialHeight: self.drawerPartialHeight,
                                                                       containerViewHeight: self.containerViewHeight,
                                                                       configuration: self.configuration)
                print("after completion", self.targetDrawerState)
            }

            AnimationSupport.clientCleanupViews(presentingDrawerAnimationActions: presentingAnimationActions,
                                                presentedDrawerAnimationActions: presentedAnimationActions,
                                                endingPosition,
                                                info)

            completion?()
        }
        
        if #available(iOS 10.0, *), !forceUIViewAnimation {
            self.animateWithPropertyAnimator(duration: duration,
                                             animation: animation,
                                             completion: completion)
        } else {
            self.animateWithUIView(duration: duration,
                                   animation: animation,
                                   completion: completion)
        }
    }

    func addCornerRadiusAnimationEnding(at endingState: DrawerState) {
        let drawerFullY = configuration.fullExpansionBehaviour.drawerFullY
        guard maximumCornerRadius != 0
            && drawerPartialY != drawerFullY
            && endingState != currentDrawerState
            else { return }

        let startingState = currentDrawerState
        let (startingPositionY, endingPositionY) = positionsY(startingState: startingState,
                                                              endingState: endingState)

        let duration = AnimationSupport.actualTransitionDuration(from: startingPositionY,
                                                                 to: endingPositionY,
                                                                 containerViewHeight: containerViewHeight,
                                                                 configuration: configuration)
        
        let endingCornerRadius = cornerRadius(at: endingState)
        
        let animation = {
            self.currentDrawerCornerRadius = endingCornerRadius
        }

        let isStartingStateCollapsedOrFullyExpanded =
            (startingState == .collapsed || startingState == .fullyExpanded)

        let isEndingStateCollapsedOrFullyExpanded =
            (endingState == .collapsed || endingState == .fullyExpanded)

        var completion: ((DrawerAnimatingPosition) -> Void)? = nil
        
        if isStartingStateCollapsedOrFullyExpanded || isEndingStateCollapsedOrFullyExpanded {
            completion = { endingPosition in
                let shouldSetCornerRadiusToZero =
                    (isEndingStateCollapsedOrFullyExpanded && endingPosition == .end) ||
                    (isStartingStateCollapsedOrFullyExpanded && endingPosition == .start)
                if shouldSetCornerRadiusToZero {
                    self.currentDrawerCornerRadius = 0
                }
            }
        }
        
        if #available(iOS 10.0, *) {
            self.animateWithPropertyAnimator(duration: duration,
                                             animation: animation,
                                             completion: completion)
        } else {
            self.animateWithUIView(duration: duration,
                                   animation: animation,
                                   completion: completion)
        }
    }

    private func positionsY(startingState: DrawerState,
                            endingState: DrawerState) -> (starting: CGFloat, ending: CGFloat) {
        let drawerFullY = configuration.fullExpansionBehaviour.drawerFullY
        let startingPositionY =
            GeometryEvaluator.drawerPositionY(for: startingState,
                                              drawerPartialHeight: drawerPartialHeight,
                                              containerViewHeight: containerViewHeight,
                                              drawerFullY: drawerFullY)

        let endingPositionY =
            GeometryEvaluator.drawerPositionY(for: endingState,
                                              drawerPartialHeight: drawerPartialHeight,
                                              containerViewHeight: containerViewHeight,
                                              drawerFullY: drawerFullY)

        return (startingPositionY, endingPositionY)
    }
}

private extension PresentationController {
    
    @available(iOS 10.0, *)
    func animateWithPropertyAnimator(duration: TimeInterval,
                                     animation: @escaping ()-> Void,
                                     completion: ((DrawerAnimatingPosition)-> Void)?) {
        let timingCurveProvider = configuration.timingCurveProvider as? UITimingCurveProvider ?? UISpringTimingParameters()
        let animator = UIViewPropertyAnimator(duration: duration, timingParameters: timingCurveProvider)
        
        animator.addAnimations(animation)
        
        if let completion = completion {
            animator.addCompletion { (endingPosition) in
                let drawerEndingPosition = DrawerAnimatingPosition.position(from: endingPosition)
                completion(drawerEndingPosition)
            }
        }
        
        animator.startAnimation()
        
        self.currentAnimator = animator
    }

    
    func animateWithUIView(duration: TimeInterval,
                           animation: @escaping ()-> Void,
                           completion: ((DrawerAnimatingPosition)-> Void)? ) {
        UIView.animate(withDuration: duration,
                       delay: 0,
                       options: [.allowUserInteraction, .beginFromCurrentState],
                       animations: animation,
                       completion: { (finished) in
                        let currentState = GeometryEvaluator.drawerState(for: self.currentDrawerY,
                                                                         drawerPartialHeight: self.drawerPartialHeight,
                                                                         containerViewHeight: self.containerViewHeight,
                                                                         configuration: self.configuration)
                        print("before completion", currentState, self.targetDrawerState)
                        if currentState == self.targetDrawerState {
                            completion?(.end)
                        } else {
                            completion?(.start)
                        }
        })

    }
    
}
