//
//  Device.swift
//  ArenaDeviceSDK
//  设备相关API
//  Created by 张琳 on 2017/10/21.
//  Copyright © 2017年 张琳. All rights reserved.
//

import Foundation

public class Device: NSObject {
    
    ///获取UUID
    public class func uuid() -> String? {
        return UIDevice.current.identifierForVendor?.uuidString
    }
    
    ///获取系统版本号
    public class func systemVersion() -> String {
        return UIDevice.current.systemVersion
    }
    
    ///获取APP版本号
    public class func appVersion() -> String? {
        let infoDic = Bundle.main.infoDictionary
        return infoDic?["CFBundleShortVersionString"] as? String
    }
    
    ///获取APPbuild版本
    public class func appBuildVersion() -> String? {
        let infoDic = Bundle.main.infoDictionary
        return infoDic?["CFBundleVersion"] as? String
    }
    
    ///获取APP名字
    public class func appName() -> String? {
        let infoDic = Bundle.main.infoDictionary
        return infoDic?["CFBundleDisplayName"] as? String
    }
    
    ///扫描二维码、条形码
    public class func scanQRCode(_ data:Dictionary<String,Any>) {
        let scanViewController = QRViewController(data: data)
        
        UIViewController.currentViewController()?.present(scanViewController, animated: true, completion: nil)
    }
    
    ///拍照+选照片
    public class func takePhoto(_ data:Dictionary<String,Any>){
        
        let imagePicker =  ImagePicker.sharedInstance
        imagePicker.data = data
        imagePicker.presentImagePicker()
        
    }
    
    
    /* 递归找最上面的viewController */
     class func topViewController() -> UIViewController? {
        
        return Device.topViewControllerWithRootViewController(viewController: Device.getCurrentWindow()?.rootViewController)
    }
    
     class func topViewControllerWithRootViewController(viewController :UIViewController?) -> UIViewController? {
        
        if viewController == nil {
            
            return nil
        }
        
        if viewController?.presentedViewController != nil {
            
            return Device.topViewControllerWithRootViewController(viewController: viewController?.presentedViewController!)
        }
        else if viewController?.isKind(of: UITabBarController.self) == true {
            
            return Device.topViewControllerWithRootViewController(viewController: (viewController as! UITabBarController).selectedViewController)
        }
        else if viewController?.isKind(of: UINavigationController.self) == true {
            
            return Device.topViewControllerWithRootViewController(viewController: (viewController as! UINavigationController).visibleViewController)
        }
        else {
            
            return viewController
        }
    }
    
    // MARK: 获取当前屏幕显示的viewController
    class func getCurrentViewController1() -> UIViewController? {
        
        // 1.声明UIViewController类型的指针
        var viewController: UIViewController?
        
        // 2.找到当前显示的UIWindow
        
        let window: UIWindow? = Device.getCurrentWindow()
        
        // 3.获得当前显示的UIWindow展示在最上面的view
        let frontView = window?.subviews.first
        
        // 4.找到这个view的nextResponder
        let nextResponder = frontView?.next
        
        if nextResponder?.isKind(of: UIViewController.classForCoder()) == true {
            
            viewController = nextResponder as? UIViewController
        }
        else {
            
            viewController = window?.rootViewController
        }
        
        return viewController
    }
    
    // 找到当前显示的window
    class func getCurrentWindow() -> UIWindow? {
        
        // 找到当前显示的UIWindow
        var window: UIWindow? = UIApplication.shared.keyWindow
        /**
         window有一个属性：windowLevel
         当 windowLevel == UIWindowLevelNormal 的时候，表示这个window是当前屏幕正在显示的window
         */
        if window?.windowLevel != UIWindowLevelNormal {
            
            for tempWindow in UIApplication.shared.windows {
                
                if tempWindow.windowLevel == UIWindowLevelNormal {
                    
                    window = tempWindow
                    break
                }
            }
        }
        
        return window
    }
    
        
}
