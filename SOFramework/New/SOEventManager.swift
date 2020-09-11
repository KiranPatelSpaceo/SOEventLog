//
//  SOEventManager.swift
//  SOFramework
//
//  Created by SOTSYS138 on 01/09/20.
//  Copyright © 2020 SOTSYS203. All rights reserved.
//

import UIKit
import MobileCoreServices
import SystemConfiguration


class SOEventManager {
    
    static let manager : SOEventManager = SOEventManager()
    var deviceInfo : DeviceInfo?
    var endPoint = EndPoints.TRACK
    var inQueue: Bool = false {
        didSet{
            debugPrint("SOFramework : API Calling - \(self.inQueue)")
        }
    }
    
    var userIdentify_ID : String? {
        get {
            return UserDefaults.standard.value(forKey: SOEventConstant.UDIdentifyKey) as? String
        }
        set {
            UserDefaults.standard.set(newValue, forKey: SOEventConstant.UDIdentifyKey)
            UserDefaults.standard.synchronize()
        }
    }
    func addEngage(email: String?,phone: String?,name: String?,firstName: String?,lastName: String?, customProperty : Dictionary<String,String>?) {
        
        if let user_id = SOEventManager.manager.userIdentify_ID{
            
            let defaultDict = RequestParameter.sharedInstance().engageDictionary(email: email, phone: phone, name: name, firstName: firstName, lastName: lastName, customProperty: customProperty)
            
            let eventDM = SOEngageDM(distinct_id: user_id, deviceData: RequestParameter.sharedInstance().convertIntoJson(dict: defaultDict))
            eventDM.saveToLocalIfNeeded()
            syncRemainingEnage()
            
        }
    }
    func addIdentity(userID: String?) {
        
        userIdentify_ID = userID
        
        if let user_id = SOEventManager.manager.userIdentify_ID{
            
            let eventDM = SOIdentityDM(identified_id:user_id)
            eventDM.saveToLocalIfNeeded()
            syncRemainingIdentity()
            
        }else{
            debugPrint("SOFramework : User Identity not found. Add user id in addIdentity(userID)")
        }
    }
    
    func addEventTrack(event : String,customProperty:[String:String]?,forceupdate: Bool) {
        
        let defaultDict = RequestParameter.sharedInstance().trackDictionary(event: event,  localProperties: customProperty)
        let eventDM = SOEventDM(event: event,dict: RequestParameter.sharedInstance().convertIntoJson(dict: defaultDict))
        eventDM.saveToLocalIfNeeded()
        syncRemainingEvent()
        
    }
    func addNotificationEvent(deviceToken : String) {
        
        let eventDM = SONotificationDM(so_device_token: deviceToken)
        
        eventDM.saveToLocalIfNeeded()
        notificationAPI()
        
        
    }
    
    func syncAllEvents(){
        if SOAnalyticsReachability.isConnectedToNetwork() {
            if SOAnalytics.shareInstance.appID.count == 0 {
                debugPrint("SOFramework : App Id not found")
                return
            }
            if !self.inQueue {
                let arryTracks = SOEventDM.pastEvent
                let arryIdentity = SOIdentityDM.pastEvent
                let arryEngage = SOEngageDM.pastEvent
                let arryNotification = SONotificationDM.pastEvent
                
                let header = RequestParameter.sharedInstance().headerData()
                debugPrint("SOFramework : header \(header)")
                var mainDictionary : Dictionary<String, Any> = Dictionary()
                var keyDictionary : Dictionary<String, Any> = Dictionary()
                var arryData : Array<Dictionary<String, Any>> = []
                
                for notification in arryNotification {
                    
                    var requestDictionary : Dictionary<String, Any> = Dictionary()
                    
                    let requestParameters = RequestParameter.sharedInstance().notificationDictionary(detail: notification)
                    
                    requestDictionary["data"] = requestParameters
                    requestDictionary["type"] = EndPoints.DEVICE.rawValue
                    arryData.append(requestDictionary)
                    
                }
                for event in arryTracks {
                    
                    var requestDictionary : Dictionary<String, Any> = Dictionary()
                    
                    if var requestParameters = RequestParameter.sharedInstance().convertToDictionary(text: event.dictData) {
                        requestParameters[SOEventConstant.Event.eventParameterKey] = event.event
                        requestDictionary["data"] = requestParameters
                        requestDictionary["type"] = EndPoints.TRACK.rawValue
                        arryData.append(requestDictionary)
                    }
                }
                for event in arryIdentity {
                    
                    var requestDictionary : Dictionary<String, Any> = Dictionary()
                    
                    let requestParameters = RequestParameter.sharedInstance().identityDictionary(detail: event)
                    
                    requestDictionary["data"] = requestParameters
                    requestDictionary["type"] = EndPoints.IDENTIFY.rawValue
                    arryData.append(requestDictionary)
                }
                for event in arryEngage {
                    
                    var requestDictionary : Dictionary<String, Any> = Dictionary()
                    if let requestParameters = RequestParameter.sharedInstance().convertToDictionary(text: event.deviceData) {
                        
                        requestDictionary["data"] = requestParameters
                        requestDictionary["type"] = EndPoints.ENGAGE.rawValue
                        arryData.append(requestDictionary)
                    }
                }
                if arryData.count > 0 {
                    keyDictionary["data"] = arryData
                    
                    debugPrint("SOFramework : Request \(keyDictionary)")
                    mainDictionary["data"] = RequestParameter.sharedInstance().convertIntoJson(dict: keyDictionary)
                    self.postWebService(SOEventConstant.baseURL + EndPoints.IMPORT.rawValue,mainDictionary,header) { (dict, error, value) in
                        debugPrint("SOFramework : Responce \(String(describing: dict))")
                        debugPrint("SOFramework :Error \(String(describing: error)) Status Code: \(String(describing: value))")
                        
                        if error == nil{
                            SOEventDM.removeFromLocalIfExists(events: arryTracks)
                            SOEngageDM.removeFromLocalIfExists(events: arryEngage)
                            SOIdentityDM.removeFromLocalIfExists(events: arryIdentity)
                            SONotificationDM.removeFromLocalIfExists(events: arryNotification)
                            
                            self.syncAllEvents()
                        }
                        self.inQueue = false
                        
                    }
                }else{
                    
                    debugPrint("SOFramework : No data available")
                    
                    self.inQueue = false
                }
            }
        }
    }
    func notificationAPI(){
        if SOAnalyticsReachability.isConnectedToNetwork() {
            
            if let notification = SONotificationDM.pastEvent.last {
                
                if SOAnalytics.shareInstance.appID != "" {
                    if !self.inQueue {
                        let requestParameters = RequestParameter.sharedInstance().notificationDictionary(detail: notification)
                        
                        let param = RequestParameter.sharedInstance().convertToJSONDict(type: nil, dictionary: requestParameters)
                        let header = RequestParameter.sharedInstance().headerData()
                        
                        debugPrint(SOEventConstant.baseURL + EndPoints.DEVICE.rawValue)
                        debugPrint("SOFramework : paramaters \(param)")
                        
                        self.postWebService(SOEventConstant.baseURL + EndPoints.DEVICE.rawValue,param,header) { (dict, error, value) in
                            debugPrint("SOFramework : Responce \(String(describing: dict))")
                            debugPrint("SOFramework : Error \(String(describing: error))")
                            if error == nil{
                                SONotificationDM.removeFromLocalIfExists(events: [notification])
                                self.inQueue = false
                                self.syncAllEvents()
                            }else{
                                self.inQueue = false

                            }
                            
                        }
                    }
                }
            }
        }
    }
    func syncRemainingEnage(){
        
        if SOAnalyticsReachability.isConnectedToNetwork() {
            
            if let event = SOEngageDM.pastEvent.first {
                
                if let requestParameters = RequestParameter.sharedInstance().convertToDictionary(text: event.deviceData) {
                    if !self.inQueue {
                        let param = RequestParameter.sharedInstance().convertToJSONDict(type: .ENGAGE, dictionary: requestParameters)
                        let header = RequestParameter.sharedInstance().headerData()
                        
                        debugPrint(SOEventConstant.baseURL + EndPoints.ENGAGE.rawValue)
                        
                        self.postWebService(SOEventConstant.baseURL + EndPoints.ENGAGE.rawValue,param,header) { (dict, error, value) in
                            debugPrint("SOFramework : Responce \(String(describing: dict))")
                            debugPrint("SOFramework : Error \(String(describing: error))")
                            if error == nil{
                                SOEngageDM.removeFromLocalIfExists(events: [event])
                                self.inQueue = false
                                self.syncAllEvents()
                            }else{
                                self.inQueue = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    func syncRemainingIdentity(){
        
        if SOAnalyticsReachability.isConnectedToNetwork() {
            
            if let event = SOIdentityDM.pastEvent.first {
                
                if !self.inQueue {
                    let defaultDict = RequestParameter.sharedInstance().identityDictionary(detail: event)
                    let param = RequestParameter.sharedInstance().convertToJSONDict(type: .IDENTIFY, dictionary: defaultDict)
                    let header = RequestParameter.sharedInstance().headerData()
                    
                    debugPrint(SOEventConstant.baseURL + EndPoints.IDENTIFY.rawValue)
                    // debugPrint("SOFramework : \(param)")
                    
                    self.postWebService(SOEventConstant.baseURL + EndPoints.IDENTIFY.rawValue,param,header) { (dict, error, value) in
                        debugPrint("SOFramework : Responce \(String(describing: dict))")
                        
                        if error == nil{
                            SOIdentityDM.removeFromLocalIfExists(events: [event])
                            self.inQueue = false
                            self.syncAllEvents()
                        }else{
                            self.inQueue = false
                        }
                    }
                }
            }
        }
    }
    
    func syncRemainingEvent(){
                    
            if SOAnalyticsReachability.isConnectedToNetwork() {
                
                if let event = SOEventDM.pastEvent.first {
                    debugPrint("SOFramework : \(String(describing: event.event)) - \(event.timeStamp)")
                    requestLog(event: event)
                }
            }
    }
    
    private func requestLog(event : SOEventDM) {
        
        if var requestParameters = RequestParameter.sharedInstance().convertToDictionary(text: event.dictData) {
            if !self.inQueue {
                requestParameters[SOEventConstant.Event.eventParameterKey] = event.event
                let param = RequestParameter.sharedInstance().convertToJSONDict(type: nil, dictionary: requestParameters)
                
                let header = RequestParameter.sharedInstance().headerData()
                debugPrint("SOFramework : \(param)")
                
                self.postWebService(SOEventConstant.baseURL + self.endPoint.rawValue,param,header) { (dict, error, value) in
                    debugPrint("SOFramework : Responce \(String(describing: dict))")
                    debugPrint("SOFramework :Error \(String(describing: error))")
                    
                    
                    if error == nil && value != -400{
                        SOEventDM.removeFromLocalIfExists(events: [event])
                        self.inQueue = false
                        
                        self.syncAllEvents()
                    }else{
                        self.inQueue = false
                    }
                }
            }
        }
        
    }
    
    func postWebService(_ apiURL: String, _ paramaters: [String : Any]? = nil, _ headers: [String : String]? = nil, _ completion : @escaping (_ dictResponse: Dictionary<String, AnyObject>?, _ error: Error?, _ statuscode: Int?) -> ()){
        
        if SOAnalyticsReachability.isConnectedToNetwork() {
            guard let url = URL(string: apiURL) else {
                debugPrint("❌ Base URL not found ❌")
                completion(nil, nil, -400)
                return
            }
            if self.inQueue {
                debugPrint("SOFramework : inQueue")
                completion(nil, nil, -400)
                return
            }
            
            self.inQueue = true
            debugPrint("URL -\(url)")
            
            DispatchQueue.global(qos: .background).async {
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.cachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalCacheData
                if let headers = headers{
                    for value in headers.enumerated(){
                        request.setValue(value.element.value, forHTTPHeaderField: value.element.key)
                    }
                }
                var paramString = String()
                if paramaters != nil {
                    for (key, value) in paramaters!  {
                        paramString = paramString + (key) + "=" + "\(value)" + "&"
                    }
                }
                
                var escapedString = paramString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
                
                escapedString = escapedString?.replacingOccurrences(of: "+", with: "%2B")
                if let string = escapedString {
                    request.httpBody = string.data(using: .utf8)
                }else{
                    request.httpBody = paramString.data(using: .utf8)
                }
                let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
                    
                    
                    debugPrint("error -\(String(describing: error))")
                    
                    if let data = data{
                        if let httpResponse = response as? HTTPURLResponse {
                            //print(httpResponse.statusCode)
                            
                            if httpResponse.statusCode == 200 {
                                
                                var dict = Dictionary<String, AnyObject>()
                                dict["success"] = String(data: data, encoding: .utf8) as AnyObject?
                                print("responce \(dict)")
                                completion(dict, nil, httpResponse.statusCode)
                                
                            } else {
                                completion(nil, nil, httpResponse.statusCode)
                            }
                        } else {
                            print("Problem in success code")
                        }
                    } else{
                        completion(nil, error, -400)
                    }
                    
                })
                task.resume()
            }
        }else{
            print("Error calling analytics")
        }
    }
    
    
    public class SOAnalyticsReachability {
        
        class func isConnectedToNetwork() -> Bool {
            
            var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
            zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
            zeroAddress.sin_family = sa_family_t(AF_INET)
            
            let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) { $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in  SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
                }
            }
            
            var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
            if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
                return false
            }
            
            /* Only Working for WIFI
             let isReachable = flags == .reachable
             let needsConnection = flags == .connectionRequired
             
             return isReachable && !needsConnection
             */
            
            // Working for Cellular and WIFI
            let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
            let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
            let ret = (isReachable && !needsConnection)
            
            return ret
            
        }
    }
}


extension Date {
    var millisecondsSince1970:Int64 {
        return Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
    
    init(milliseconds:Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}
