//
//  Device.swift
//  ArenaDeviceSDK
//
//  Created by 张琳 on 2017/10/21.
//  Copyright © 2017年 张琳. All rights reserved.
//

import Foundation

class Device: NSObject {
    
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
    
        
}
