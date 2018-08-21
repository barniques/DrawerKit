import UIKit

final class PresentationController: UIPresentationController {
    let configuration: DrawerConfiguration // intentionally internal and immutable
    let inDebugMode: Bool
    let forwardingView: ForwardingView?
    let handleView: UIView?
    let dimmingView: UIView?
    
    let shadowLayer: CAShapeLayer?
    let cornerLayer: CAShapeLayer?
    
    //system can't run two dismissal transitions,
    //therefor we should animate "dismiss" before call dismiss function
    //only for simultaneously dismiss presentation vc and presenting vc
    var currentAnimator: Any?
    
    let presentingDrawerAnimationActions: DrawerAnimationActions
    let presentedDrawerAnimationActions: DrawerAnimationActions

    var drawerFullExpansionTapGR: UITapGestureRecognizer?
    var drawerDismissalTapGR: UITapGestureRecognizer?
    var drawerDragGR: UIPanGestureRecognizer?

    /// The target state of the drawer. If no presentation animation is in
    /// progress, the value should be equivalent to `currentDrawerState`.
    var targetDrawerState: DrawerState {
        didSet {
            gestureAvailabilityConditionsDidChange()
        }
    }

    var startingDrawerStateForDrag: DrawerState?

    var pullToDismissManager: PullToDismissManager?

    weak var scrollViewForPullToDismiss: UIScrollView? {
        willSet {
            if let manager = pullToDismissManager {
                scrollViewForPullToDismiss?.delegate = manager.delegate
                pullToDismissManager = nil
            }
        }

        didSet {
            if let scrollView = scrollViewForPullToDismiss {
                pullToDismissManager = PullToDismissManager(delegate: scrollView.delegate,
                                                            presentationController: self)
                scrollView.delegate = pullToDismissManager
                drawerDragGR?.require(toFail: scrollView.panGestureRecognizer)
            }

            gestureAvailabilityConditionsDidChange()
        }
    }

    init(presentingVC: UIViewController?,
         presentingDrawerAnimationActions: DrawerAnimationActions,
         presentedVC: UIViewController,
         presentedDrawerAnimationActions: DrawerAnimationActions,
         configuration: DrawerConfiguration,
         inDebugMode: Bool = false) {
        self.configuration = configuration
        self.inDebugMode = inDebugMode
        self.handleView = (configuration.handleViewConfiguration != nil ? UIView() : nil)
        self.dimmingView = (configuration.drawerDimmingConfiguration != nil ? UIView() : nil)
        self.forwardingView = (configuration.shouldForwardTouchesToPresenterVC ? ForwardingView() : nil)
        self.shadowLayer = (configuration.drawerShadowConfiguration != nil ? CAShapeLayer() : nil)
        self.cornerLayer = (configuration.drawerShadowConfiguration != nil ? CAShapeLayer() : nil)
        self.presentingDrawerAnimationActions = presentingDrawerAnimationActions
        self.presentedDrawerAnimationActions = presentedDrawerAnimationActions
        self.targetDrawerState = configuration.supportsPartialExpansion ? .partiallyExpanded : .fullyExpanded

        super.init(presentedViewController: presentedVC, presenting: presentingVC)
    }

    func gestureAvailabilityConditionsDidChange() {
        drawerDismissalTapGR?.isEnabled = targetDrawerState == .partiallyExpanded
        drawerFullExpansionTapGR?.isEnabled = targetDrawerState == .partiallyExpanded

        if let scrollView = scrollViewForPullToDismiss, let manager = pullToDismissManager {
            switch targetDrawerState {
            case .partiallyExpanded, .collapsed:
                scrollView.isScrollEnabled = false
            case .transitioning, .fullyExpanded:
                scrollView.isScrollEnabled = !manager.scrollViewNeedsTransitionAsDragEnds
            }
        }
    }
}

extension PresentationController {
    override var frameOfPresentedViewInContainerView: CGRect {
        var frame: CGRect = .zero
        let drawerFullY = configuration.fullExpansionBehaviour.drawerFullY
        let height = containerViewHeight - drawerFullY
        frame.size = size(forChildContentContainer: presentedViewController,
                          withParentContainerSize: CGSize(width: containerViewSize.width, height: height))
        frame.origin.y = GeometryEvaluator.drawerPositionY(for: targetDrawerState,
                                                           drawerPartialHeight: drawerPartialHeight,
                                                           containerViewHeight: containerViewHeight,
                                                           drawerFullY: drawerFullY)
        return frame
    }

    override func presentationTransitionWillBegin() {
        // NOTE: `targetDrawerState.didSet` is not invoked within the
        //        initializer.
        gestureAvailabilityConditionsDidChange()

        presentedViewController.view.layoutIfNeeded()
        containerView?.backgroundColor = .clear
        setupDrawerFullExpansionTapRecogniser()
        setupDrawerDismissalTapRecogniser()
        setupDrawerDragRecogniser()
        setupDebugHeightMarks()
        setupHandleView()
        setupDimmmingView()
        setupForwardingView()
        setupDrawerBorder()
        setupDrawerShadow()
        addCornerRadiusAnimationEnding(at: .partiallyExpanded)
        enableDrawerFullExpansionTapRecogniser(enabled: false)
        enableDrawerDismissalTapRecogniser(enabled: false)
    }

    override func presentationTransitionDidEnd(_ completed: Bool) {
        if !configuration.shouldForwardTouchesToPresenterVC {
            enableDrawerFullExpansionTapRecogniser(enabled: true)
            enableDrawerDismissalTapRecogniser(enabled: true)
        }
    }

    override func dismissalTransitionWillBegin() {
        addCornerRadiusAnimationEnding(at: .collapsed)
        enableDrawerFullExpansionTapRecogniser(enabled: false)
        enableDrawerDismissalTapRecogniser(enabled: false)
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        removeDrawerFullExpansionTapRecogniser()
        removeDrawerDismissalTapRecogniser()
        removeDrawerDragRecogniser()
        removeHandleView()
    }

    override func containerViewWillLayoutSubviews() {
        presentedView?.frame = frameOfPresentedViewInContainerView
    }
}

extension PresentationController: DrawerPresentationControlling {
    
    func partlyExpand() {
        animateTransition(to: .partiallyExpanded)
    }
    
    func expandDrawer() {
        animateTransition(to: .fullyExpanded)
    }
    
    func hideDrawer() {
        animateTransition(to: .collapsed)
    }
    
    func prepareForDismissal() {
        animateTransition(to: .collapsed, forceUIViewAnimation: true)
    }

}
