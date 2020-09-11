//
//  SOAnalytics.swift
//  SOFramework
//
//  Created by SOTSYS203 on 26/08/20.
//  Copyright © 2020 SOTSYS203. All rights reserved.
//

import UIKit
import CoreTelephony

@objc public class SOAnalytics: NSObject {
    
    // Singleton instance
    private static var instance : SOAnalytics?
    
    //Variables Using Globally
    public var appID = ""
    
    // Creating sharedinstance
    @objc public class var shareInstance: SOAnalytics {
        get {
            struct Static {
                static var instance: SOAnalytics? = SOAnalytics()
                static var token = {0}()
            }
            _ = Static.token
            
            return Static.instance!
        }
    }
    
    //Starting framework with appId
    @objc public func initWithAppid(id : String) {
        appID = id
    }
    
    //Tracking events of app
    @objc public func setEventTrack(eventName: String, customProperty : Dictionary<String,String>?) {
        //print("Event Name => \(eventName)")
        /*
        //Profile Properties
        print("City ==> Not Available")
        print("Region ==> Not Available")
        print("Country ==> Not Available")
        print("Geo Source ==> Not Available")
        print("Private IP ==> \(UIDevice.current.getPrivateIPAddress())")
        print("Timezone ==> \(getCurrentTimeZone())")
        print("iOS App Release ($ios_app_release)  ==> \(Bundle.main.buildNumber)")
        print("iOS App Version ($ios_app_version)   ==> \(Bundle.main.versionNumber)")
        print("iOS Device Model ($ios_device_model)   ==> \(UIDevice.deviceModelName())")
        print("iOS Lib Version ($ios_lib_version)    ==> \(1.0)")
        print("iOS Version ($ios_version)    ==> \(UIDevice.getSystemVersion())")
        print("Last Seen ($last_seen)    ==> \(Date.currentTimeStamp)")
        print("Total App Sessions    ==> \(0)") // Manage by user default
        print("Total App Session Length    ==> \(0.00)") // Manage by user default
        print("First App Open Date    ==> \(Date.currentTimeStamp)")
        
        
        //Event properties
        print("City ==> Not Available")
        print("Region ==> Not Available")
        print("Country ==> Not Available")
        print("iOS App Release ($ios_app_release)  ==> \(Bundle.main.buildNumber)")
        print("iOS App Version ($ios_app_version)   ==> \(Bundle.main.versionNumber)")
        print("Carrier ($carrier)  ==> \(self.carrierName())")
        print("iOS Version ($ios_version)    ==> \(UIDevice.getSystemVersion())")
        print("Manufacturer ($manufacturer)    ==> Apple")
        print("Lib Version ($lib_version)    ==> \(1.0)")
        print("Mixpanel Library (mp_lib)    ==> Not Availble")
        print("Model ($model)    ==> \(UIDevice.deviceModelName())")
        print("Device Model (mp_device_model)     ==> \(UIDevice.deviceModelName())")
        print("Device ID ($device_id)     ==> \(UIDevice.current.identifierForVendor?.uuidString ?? "Not Available")")
        print("Operating System ($os)     ==> \(UIDevice.getSystemVersion())")
        print("Radio ($radio)    ==> \(self.radioGetProviders())")
        print("Screen Height ($screen_height)    ==> \(UIScreen.main.bounds.height)")
        print("Screen Width ($screen_width)     ==> \(UIScreen.main.bounds.width)")
        print("Wifi ($wifi)    ==> Checking..")
        print("Processing Time (mp_processing_time_ms)    ==> Checking...")
        
        print("Version Detail ==> \(Bundle.main.appName) v \(Bundle.main.versionNumber) (Build \(Bundle.main.buildNumber))")
        print("BundleID ==> \(Bundle.main.bundleId)")
        */
        
        let header = RequestParameter.sharedInstance().headerData()
        let createData = RequestParameter.sharedInstance().trackCreateDictionary(event: eventName, radio: self.radioGetProviders(), carrier: self.getCarrierName(), localProperties: customProperty)
        
        let param = RequestParameter.sharedInstance().trackOrder(dictionary: createData)
        print("SOAnalytics param ==>",param)
        print("SOAnalytics header ==>",header)

        SOAPIManager.callAPI(.TRACK, of: .POST, paramaters: param, headers: header) { (result, error, statuscode) in
            print("SOAnalytics Statuscode ==>", statuscode as Any)
            print("SOAnalytics result ==>",result as Any)
            print("SOAnalytics error ==>",error as Any)
        }
    }
    
    @objc public func setImport(importName: String) {
 //       print("Import Name => \(importName)")
//        SOAPIManager.callAPI(.IMPORT, of: .POST, paramaters: nil, headers: nil) { (result, error) in
//
//        }
    }
    
    @objc public func setEngage(engageName: String) {
//        print("Engate Name => \(engageName)")
//        SOAPIManager.callAPI(.ENGAGE, of: .POST, paramaters: nil, headers: nil) { (result, error) in
//
//        }
    }
    
    @objc public func setGroup(groupName: String) {
//        print("Group Name => \(groupName)")
//        SOAPIManager.callAPI(.GROUPS, of: .POST, paramaters: nil, headers: nil) { (result, error) in
//
//        }
    }
    /*
    func getCarrierName() -> String {
        let networkStatus = CTTelephonyNetworkInfo()
        if let info = networkStatus.serviceSubscriberCellularProviders,
            let carrier = info["serviceSubscriberCellularProvider"] {
            //work with carrier object
//            print(carrier.isoCountryCode)
//            print(carrier.mobileCountryCode)
//            print(carrier.mobileNetworkCode)
            return carrier.carrierName!
        }
        
        return "NA"
    }*/
    
    func getCarrierName() -> String {
        let info = CTTelephonyNetworkInfo()
        var supplier:String = ""
        if #available(iOS 12.0, *) {
            if let carriers = info.serviceSubscriberCellularProviders {
                if carriers.keys.count == 0 {
                    return "no phone card"
                } else { //Get carrier information
                    for (index, carrier) in carriers.values.enumerated() {
                        guard carrier.carrierName != nil else { return "no phone card" }
                        // View operator information through the CTCarrier class
                        if index == 0 {
                            supplier = carrier.carrierName!
                        } else {
                            supplier = supplier + "," + carrier.carrierName!
                        }
                    }
                    return supplier
                }
            } else{
                return "no phone card"
            }
        } else {
            if let carrier = info.subscriberCellularProvider {
                guard carrier.carrierName != nil else { return "no phone card" }
                return carrier.carrierName!
            } else{
                return "no phone card"
            }
        }
    }
    
    func radioGetProviders() -> String {
        let networkInfo = CTTelephonyNetworkInfo()
        let networkString = networkInfo.currentRadioAccessTechnology
        
        if networkString == CTRadioAccessTechnologyLTE{
            // LTE (4G)
            return "4G"
        }else if networkString == CTRadioAccessTechnologyWCDMA{
            // 3G
            return "3G"
        }else if networkString == CTRadioAccessTechnologyEdge{
            // EDGE (2G)
            return "2G"
        }
        return "NA"
    }
}

extension SOAnalytics {
    func getCurrentTimeZone() -> String {
        let currentDate = Date()
        // 1) Create a DateFormatter() object.
        let format = DateFormatter()
        // 2) Set the current timezone to .current, or America/Chicago.
        format.timeZone = .current
        // 3) Set the format of the altered date.
        format.dateFormat = "ZZZZ"
        // 4) Set the current date, altered by timezone.
        let dateString = format.string(from: currentDate)
        //print(dateString)
        return dateString
    }
}

extension Date {
    static var currentTimeStamp: Int64{
        return Int64(Date().timeIntervalSince1970 * 1000)
    }
}



