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
    
    private var observerForeground: NSObjectProtocol?
    private var observerBackgound: NSObjectProtocol?
    public var isTestEnviorment : Bool = false
    var backgroundTask = UIBackgroundTaskIdentifier.invalid
    var flushTimer: Timer?
    public var flushTime : Int = 0 {
        didSet {
            flushTimeActive = flushTime
        }
    }
    private var flushTimeActive : Int = 0 {
        didSet {
            flushTimer?.invalidate()
            if flushTime > 0 {
                flushTimer = Timer.scheduledTimer(timeInterval: TimeInterval(flushTime), target: self, selector: #selector(flush), userInfo: nil, repeats: true)
            }
        }
    }
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
    deinit {
        if let observer = observerForeground {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = observerBackgound {
            NotificationCenter.default.removeObserver(observer)
        }
        flushTimeActive = 0
    }
    //Starting framework with appId
    @objc public func initWithAppid(id : String, test_environment:Bool) {
        
        isTestEnviorment = test_environment
        appID = id
        debugPrint("SOFramework: Analytics init - \(id)")
        SOEventManager.manager.deviceInfo = DeviceInfo()
        
        if !isAppInstalled {
            self.setEventTrack(eventName: SOEventConstant.Event.firstAppOpen, customProperty: nil,forceUpdate: false)
        }
        isAppInstalled = true
        
        if let storeVersion = appVersion, let currentVersion = SOEventManager.manager.deviceInfo?.version_number{
            debugPrint("SOFramework :previous Version \(storeVersion)")
            debugPrint("SOFramework :current Version \(currentVersion)")
            
            if storeVersion.compare(currentVersion, options: .numeric) == .orderedAscending {
                debugPrint("SOFramework :store version is newer")
                self.setEventTrack(eventName: SOEventConstant.Event.appUpdated, customProperty: nil,forceUpdate: false)
                
            }
            
            appVersion = currentVersion
            
        }else{
            
            appVersion = SOEventManager.manager.deviceInfo?.version_number
        }
        self.setEventTrack(eventName: SOEventConstant.Event.appLunched, customProperty: nil,forceUpdate: true)
        
        observerForeground = NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) {  notification in
            debugPrint("SOFramework: willEnterForegroundNotification")
            self.referesh()
            self.flushTimeActive = self.flushTime
            
            DispatchQueue.global(qos: .background).async {
                // sends registration to background queue
                UIApplication.shared.endBackgroundTask(self.backgroundTask)
                self.backgroundTask = UIBackgroundTaskIdentifier.invalid
                
            }
        }
        
        observerBackgound = NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) {  notification in
            debugPrint("SOFramework: didEnterBackgroundNotification")
            self.flushTimeActive = 0
        }
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "SOFrameworkBackgroundTask") {
            
            debugPrint("SOFramework: SOFrameworkBackgroundTask")
            UIApplication.shared.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = UIBackgroundTaskIdentifier.invalid
            
        }
    }
    @objc private func flush(){
        referesh()
    }
    @objc public func referesh(){
        SOEventManager.manager.syncAllEvents()
        
    }
    @objc public func logOutUser(){
        UserDefaults.standard.removeObject(forKey: SOEventConstant.UDIdentifyKey)
        UserDefaults.standard.synchronize()
    }
    @objc public func setEngage(firstName: String?,lastName: String?,name: String?, email:String?,phone: String?, customProperty : Dictionary<String,String>?){
        
        SOEventManager.manager.addEngage(email: email, phone: phone, name: name, firstName: firstName, lastName: lastName,customProperty: customProperty)
    }
    @objc public func setIdentify(userID: String?){
        
        SOEventManager.manager.addIdentity(userID: userID)
    }
    @objc public func setNotitificationToken(deviceToken: String){
        
        SOEventManager.manager.addNotificationEvent(deviceToken: deviceToken)
    }
    //Tracking events of app
    @objc public func setEventTrack(eventName: String, customProperty : Dictionary<String,String>?,forceUpdate: Bool = true) {
        
        if SOEventManager.manager.deviceInfo == nil {
            SOEventManager.manager.deviceInfo = DeviceInfo(carrier: self.getCarrierName(), radio: self.radioGetProviders())
        }
        SOEventManager.manager.deviceInfo?.radio = self.radioGetProviders()
        SOEventManager.manager.deviceInfo?.carrier = self.getCarrierName()
        SOEventManager.manager.deviceInfo?.isWifi = getNetworkTyep() == .reachableViaWiFi ? "true" : "false"
        SOEventManager.manager.addEventTrack(event: eventName,customProperty: customProperty,forceupdate: forceUpdate)
    }
    
    var isAppInstalled : Bool {
        get {
            return UserDefaults.standard.bool(forKey: SOEventConstant.Event.firstAppOpenUserDefaultKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: SOEventConstant.Event.firstAppOpenUserDefaultKey)
            UserDefaults.standard.synchronize()
        }
    }
    var appVersion : String? {
        get {
            return UserDefaults.standard.value(forKey: SOEventConstant.Event.appVersionUserDefaultKey) as? String
        }
        set {
            UserDefaults.standard.set(newValue, forKey: SOEventConstant.Event.appVersionUserDefaultKey)
            UserDefaults.standard.synchronize()
        }
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
    func getCarrierName() -> String {
        let info = CTTelephonyNetworkInfo()
        var supplier:String = ""
        if #available(iOS 12.0, *) {
            if let carriers = info.serviceSubscriberCellularProviders {
                if carriers.keys.count == 0 {
                    return "NA"
                } else { //Get carrier information
                    for (index, carrier) in carriers.values.enumerated() {
                        guard carrier.carrierName != nil else { return "NA" }
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
                return "NA"
            }
        } else {
            if let carrier = info.subscriberCellularProvider {
                guard carrier.carrierName != nil else { return "NA" }
                return carrier.carrierName!
            } else{
                return "NA"
            }
        }
    }
    
    func radioGetProviders() -> String {
        let networkInfo = CTTelephonyNetworkInfo()
        var networkString: String = ""
        
        if #available(iOS 12.0, *) {
            networkString = networkInfo.currentRadioAccessTechnology ?? "NA"
            
        }else{
            guard let carrierType = networkInfo.currentRadioAccessTechnology else {
                return "NA"
            }
            networkString = carrierType
        }
        
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

extension Date {
    static var currentTimeStamp: Int64{
        return Int64(Date().timeIntervalSince1970 * 1000)
    }
}



