//
//  TestViewController.swift
//  DrawerKitDemo
//
//  Created by Dmitrii Barmin on 16.08.2018.
//  Copyright © 2018 Babylon Health. All rights reserved.
//

import Foundation

import DrawerKit

class TestViewController: UIViewController {
    @IBOutlet weak var testLabel: UILabel!
}


extension TestViewController: DrawerPresentable {
    var heightOfPartiallyExpandedDrawer: CGFloat {
        if #available(iOS 11, *) {
            return testLabel.frame.maxY + view.safeAreaInsets.bottom
        } else {
            return testLabel.frame.maxY
        }
    }
}
