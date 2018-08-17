import UIKit
import DrawerKit

class PresenterViewController: UIViewController, DrawerCoordinating {
    /* strong */ var drawerDisplayController: DrawerDisplayController?

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let coordinator = self.transitionCoordinator,
            let presentedVC = self.presentedViewController as? (UIViewController & DrawerPresentable) {
            coordinator.animate(alongsideTransition: { (context) in
                presentedVC.drawerPresentationController?.prepareForDismissal()
            }, completion: nil)
        }

    }
    
    @IBAction func presentButtonTapped() {
        doModalPresentation()
    }
}

private extension PresenterViewController {
    func doModalPresentation() {
        guard self.presentedViewController == nil else { return }
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "TestViewController")
            as? TestViewController else { return }

        // you can provide the configuration values in the initialiser...
        var configuration = DrawerConfiguration(/* ..., ..., ..., */)

        // ... or after initialisation. All of these have default values so change only
        // what you need to configure differently. They're all listed here just so you
        // can see what can be configured. The values listed are the default ones,
        // except where indicated otherwise.
        configuration.totalDurationInSeconds = 0.4
        configuration.durationIsProportionalToDistanceTraveled = false
        // default is UISpringTimingParameters()
//        configuration.timingCurveProvider = UISpringTimingParameters(dampingRatio: 0.8)
        configuration.fullExpansionBehaviour = .leavesCustomGap(gap: 200)
        configuration.supportsPartialExpansion = true
        configuration.dismissesInStages = true
        configuration.isDrawerDraggable = true
        configuration.isFullyPresentableByDrawerTaps = true
        configuration.numberOfTapsForFullDrawerPresentation = 1
        configuration.isDismissableByOutsideDrawerTaps = true
        configuration.numberOfTapsForOutsideDrawerDismissal = 1
        configuration.flickSpeedThreshold = 3
        configuration.upperMarkGap = 100 // default is 40
        configuration.lowerMarkGap =  80 // default is 40
        
        configuration.maximumCornerRadius = 15
        configuration.cornerAnimationOption = .maximumAtPartialY
        
        configuration.shouldForwardTouchesToPresenterVC = true

        var handleViewConfiguration = HandleViewConfiguration()
        handleViewConfiguration.autoAnimatesDimming = true
        handleViewConfiguration.backgroundColor = .gray
        handleViewConfiguration.size = CGSize(width: 40, height: 6)
        handleViewConfiguration.top = 8
        handleViewConfiguration.cornerRadius = .automatic
        configuration.handleViewConfiguration = handleViewConfiguration

        configuration.drawerDimmingConfiguration = DrawerDimmingConfiguration(backgroundColor: UIColor.black.withAlphaComponent(0.2))
        
//        let borderColor = UIColor(red: 1, green: 0, blue: 0, alpha: 1)
//        let drawerBorderConfiguration = DrawerBorderConfiguration(borderThickness: 0.5,
//                                                                  borderColor: borderColor)
//        configuration.drawerBorderConfiguration = drawerBorderConfiguration // default is nil

        
        
        let drawerShadowConfiguration = DrawerShadowConfiguration(shadowOpacity: 1,
                                                                  shadowRadius: 32,
                                                                  shadowOffset: CGSize(width: 0, height: 8),
                                                                  shadowColor: UIColor.blue)
        configuration.drawerShadowConfiguration = drawerShadowConfiguration // default is nil

        drawerDisplayController = DrawerDisplayController(presentingViewController: self,
                                                          presentedViewController: vc,
                                                          configuration: configuration,
                                                          inDebugMode: true)

        present(vc, animated: true)
    }
}
