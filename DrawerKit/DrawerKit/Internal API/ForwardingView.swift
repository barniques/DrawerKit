//
//  ForwardingView.swift
//  DrawerKit
//
//  Created by Dmitrii Barmin on 07.08.2018.
//  Copyright © 2018 Babylon Health. All rights reserved.
//

import Foundation

class ForwardingView: UIView {
    
    var passthroughViews = [UIView]()
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let hitView = super.hitTest(point, with: event), hitView != self {
            return hitView
        }
        
        for passthroughView in self.passthroughViews {
            if let hitView = passthroughView.hitTest(self.convert(point, to: passthroughView), with: event) {
                return hitView
            }
        }
        
        return self
    }
    
}
