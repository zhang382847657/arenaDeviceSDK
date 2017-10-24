//
//  UIViewController.swift
//  ArenaDeviceSDK
//
//  Created by 张琳 on 2017/10/23.
//  Copyright © 2017年 张琳. All rights reserved.
//

import Foundation

extension UIViewController {
    class func currentViewController(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return currentViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return currentViewController(base: tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return currentViewController(base: presented)
        }
        return base
    }
}
