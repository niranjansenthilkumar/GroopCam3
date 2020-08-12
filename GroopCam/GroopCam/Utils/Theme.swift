//
//  Theme.swift
//  GroopCam
//
//  Created by Niranjan Senthilkumar on 1/5/20.
//  Copyright © 2020 NJ. All rights reserved.
//

import Foundation
import UIKit

class Theme: UIColor {
    static func rgb(red: CGFloat, green: CGFloat, blue: CGFloat) -> UIColor {
        return UIColor(red: red/255, green: green/255, blue: blue/255, alpha: 1)
    }
    
    static let backgroundColor = rgb(red: 234, green: 82, blue: 111)
//    static let backgroundColor = UIColor.black

    static let cellColor = rgb(red: 154, green: 47, blue: 68)
    
    static let buttonColor = rgb(red: 170, green: 0, blue: 42)
    
    static let verylgColor = rgb(red: 201, green: 201, blue: 201)

    static let lgColor = rgb(red: 141, green: 141, blue: 141)
    static let gColor = rgb(red: 115, green: 115, blue: 115)
    static let bColor = rgb(red: 23, green: 18, blue: 90)
    
    static let lessgColor = rgb(red: 129, green: 129, blue: 129)
    
    static let whiteopacity = UIColor(red: 1, green: 1, blue: 1, alpha: 0.75)



    
}

extension UIColor {
    // Swift unfortunately doesn't yet have a clean way of checking for iOS 13 at compile-time, so we attempt to import CryptoKit, a framework that only exists on iOS 13.
    // We can delete all of these awful #if canImport() blocks once the iOS 13 SDK is required for App Store submissions, probably ~March 2020.
    static let stripeBrightGreen : UIColor = {
        var color = UIColor(red: 33/255, green: 180/255, blue: 126/255, alpha: 1.0)
        #if canImport(CryptoKit)
        if #available(iOS 13.0, *) {
            color = UIColor.init(dynamicProvider: { (tc) -> UIColor in
                return (tc.userInterfaceStyle == .light) ?
                    UIColor(red: 33/255, green: 180/255, blue: 126/255, alpha: 1.0) :
                    UIColor(red: 39/255, green: 213/255, blue: 149/255, alpha: 1.0)
            })
        }
        #endif
        return color
    }()
    static let stripeDarkBlue : UIColor = {
        var color = UIColor(red: 80/255, green: 95/255, blue: 127/255, alpha: 1.0)
        #if canImport(CryptoKit)
        if #available(iOS 13.0, *) {
            color = UIColor.init(dynamicProvider: { (tc) -> UIColor in
                return (tc.userInterfaceStyle == .light) ?
                    UIColor(red: 80/255, green: 95/255, blue: 127/255, alpha: 1.0) :
                    UIColor(red: 121/255, green: 142/255, blue: 188/255, alpha: 1.0)
            })
        }
        #endif
        return color
    }()
}
