//
//  DeviceInfo.swift
//  SOFramework
//
//  Created by SOTSYS138 on 01/09/20.
//  Copyright © 2020 SOTSYS203. All rights reserved.
//

import UIKit

struct DeviceInfo {
    var build_number: String  {
        get{
            return "\(Bundle.main.buildNumber)"
        }
    }
    var version_number: String {
        get{
            return "\(Bundle.main.versionNumber)"
        }
    }
    var os_version: String {
        get{
            return "\(UIDevice.getSystemVersion())"
        }
    }

    var model: String {
        get {
            return "\(UIDevice.modelName)"
        }
    }
    var mp_device_model: String {
        get {
            return "\(UIDevice.modelName)"
        }
    }
    var device_id: String {
        get {
           return "\(UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString)"
        }
    }
    var distinct_id: String {
        get {
           return "\(UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString)"
        }
    }
    var system_version: String {
        get{
            return "\(UIDevice.getSystemVersion())"
        }
    }
//    var isWifi: String {
//        get{
//          return ""//getNetworkTyep() == .reachableViaWiFi ? "true" : "false"
//        }
//    }
    var height: Int {
        get{
            return Int(UIScreen.main.bounds.height)
        }
    }
    var width: Int {
        get{
            return Int(UIScreen.main.bounds.width)
        }
    }
    var language : String {
        get{
          return "\(Bundle.main.preferredLocalizations.first ?? "en")"
        }
    }
    var isWifi: String = "false"
    var carrier: String = ""
    var manufacturer: String = SOEventConstant.manufacture
    var lib_version: String = "1.0"
    var radio: String = ""
    
    init(carrier: String, radio: String) {
        self.carrier = carrier
        self.radio = radio
    }
     init() {
        
    }
    
}
