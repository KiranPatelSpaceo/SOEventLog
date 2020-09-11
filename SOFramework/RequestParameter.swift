//
//  RequestParameter.swift
//  CodeStructure
//
//  Created by Hitesh on 11/29/16.
//  Copyright © 2016 myCompany. All rights reserved.
//

import UIKit

class RequestParameter: NSObject {
    static var instance: RequestParameter!
    
    // SHARED INSTANCE
    class func sharedInstance() -> RequestParameter {
        self.instance = (self.instance ?? RequestParameter())
        return self.instance
    }
    
    // Pass dictionary to header
    func headerData() -> Dictionary<String,String> {
        
        var requestDictionary : Dictionary<String,String> = Dictionary()
        requestDictionary["Content-Type"] = "application/x-www-form-urlencoded"
        requestDictionary["Accept"] = "multipart/form-data"
        requestDictionary["APP_ID"] = SOAnalytics.shareInstance.appID
        
        //print("Header =>", requestDictionary)
        return requestDictionary
    }
    
    
    func trackCreateDictionary(event : String, radio : String, carrier : String, localProperties : Dictionary<String,String>?) -> Dictionary<String, Any> {
        /* {
         "event": "Play game",
         "properties": {
         "distinct_id": "13793",
         "token": "e3bb4100330c35722740fb8c6f5abddc",
         "Level": "3"
         }*/
        
        let height = Int(UIScreen.main.bounds.height)
        let width = Int(UIScreen.main.bounds.width)
        
        var requestDictionary1 : Dictionary<String, Any> = Dictionary()
        requestDictionary1["event"] = event
        
        var requestDictionary2 : Dictionary<String, Any> = Dictionary()
        requestDictionary2["so_app_build_number"] = "\(Bundle.main.buildNumber)"
        requestDictionary2["so_app_version_string"] = "\(Bundle.main.versionNumber)"
        requestDictionary2["so_carrier"] = carrier
        requestDictionary2["so_os_version"] = "\(UIDevice.getSystemVersion())"
        requestDictionary2["so_manufacturer"] = "Apple"
        requestDictionary2["so_lib_version"] = "1.0"
        requestDictionary2["so_model"] = "\(UIDevice.deviceModelName())"
        requestDictionary2["so_mp_device_model"] = "\(UIDevice.deviceModelName())"
        requestDictionary2["so_device_id"] = "\(UIDevice.current.identifierForVendor?.uuidString ?? "Not Available")"
        requestDictionary2["so_os"] = "\(UIDevice.getSystemVersion())"
        requestDictionary2["so_radio"] = radio
        requestDictionary2["so_screen_height"] = "\(height)"
        requestDictionary2["so_screen_width"] = "\(width)"
        requestDictionary2["so_wifi"] = getNetworkTyep() == .reachableViaWiFi ? "true" : "false"
        
        requestDictionary1["properties"] = requestDictionary2
        
        if localProperties != nil {
            var requestDictionary3 : Dictionary<String, Any> = Dictionary()
            for (key, value) in localProperties! {
                requestDictionary3[key] = value
            }
            requestDictionary1["custom_properties"] = requestDictionary3
        }
        //print(requestDictionary1)
        return requestDictionary1
    }
    
    func trackOrder(dictionary:Dictionary<String, Any>) -> Dictionary<String, Any> {
        var requestDictionary : Dictionary<String, Any> = Dictionary()
        requestDictionary["data"] = self.convertIntoJson(dict: dictionary)
        return requestDictionary
    }
    
    func convertIntoJson(dict : Dictionary<String, Any>) -> String {
        
        if let theJSONData = try?  JSONSerialization.data(
            withJSONObject: dict,
            options: .prettyPrinted
            ),
            let theJSONText = String(data: theJSONData,
                                     encoding: String.Encoding.ascii) {
            //print("JSON string = \n\(theJSONText)")
            return theJSONText
        }
        
        return ""
    }
}

