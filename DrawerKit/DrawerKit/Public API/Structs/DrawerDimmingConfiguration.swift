import UIKit

/// Configuration options for the drawer's shadow.

public struct DrawerDimmingConfiguration {
    public let backgroundColor: UIColor
    
    public init(backgroundColor: UIColor = UIColor.black) {
        self.backgroundColor = backgroundColor
    }
}

extension DrawerDimmingConfiguration: Equatable {
    public static func ==(lhs: DrawerDimmingConfiguration, rhs: DrawerDimmingConfiguration) -> Bool {
        return lhs.backgroundColor == rhs.backgroundColor
    }
}
