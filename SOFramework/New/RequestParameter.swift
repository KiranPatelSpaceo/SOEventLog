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
        func headerData() -> Dictionary<String,String> {
            
            var requestDictionary : Dictionary<String,String> = Dictionary()
            requestDictionary["Content-Type"] = "application/x-www-form-urlencoded"
            requestDictionary["Accept"] = "multipart/form-data"
            requestDictionary["app_id"] = SOAnalytics.shareInstance.appID
            return requestDictionary
        }
        func deviceDictionary()-> Dictionary<String, Any>{
            let deviceInfo = SOEventManager.manager.deviceInfo ?? DeviceInfo()
            var dictProperty : Dictionary<String, Any> = Dictionary()
            dictProperty["so_app_build_number"] = deviceInfo.build_number
            dictProperty["so_app_version_string"] = deviceInfo.version_number
            dictProperty["so_carrier"] = deviceInfo.carrier
            dictProperty["so_os_version"] = deviceInfo.system_version
            dictProperty["so_manufacturer"] = deviceInfo.manufacturer
            dictProperty["so_lib_version"] = deviceInfo.lib_version
            dictProperty["so_model"] = deviceInfo.model
            dictProperty["so_mp_device_model"] = deviceInfo.mp_device_model
            dictProperty["so_device_id"] = deviceInfo.device_id
            dictProperty["so_os"] =  deviceInfo.os_version
            dictProperty["so_radio"] =  deviceInfo.radio
            dictProperty["so_screen_height"] =  deviceInfo.height
            dictProperty["so_screen_width"] =  deviceInfo.width
            dictProperty["so_wifi"] =  deviceInfo.isWifi
            dictProperty["so_language"] =  deviceInfo.language
            let credated = String(Int64(Date().timeIntervalSince1970 * 1000))
            debugPrint("CurrentTime:\(credated)")
            dictProperty["so_created"] = credated
            dictProperty["so_time"] = credated
            
            if let user_id = SOEventManager.manager.userIdentify_ID {
                dictProperty["so_distinct_id"] =  user_id//deviceInfo.distinct_id

            }else{
                dictProperty["so_distinct_id"] =  deviceInfo.distinct_id

            }
            return dictProperty
            
        }
      func notificationDictionary(detail:SONotificationDM) -> Dictionary<String, Any> {
          var requestDictionary : Dictionary<String, Any> = Dictionary()

          var requestParameters : Dictionary<String, Any> = Dictionary()
        requestParameters["so_distinct_id"] = SOEventManager.manager.userIdentify_ID ?? DeviceInfo().distinct_id
        requestParameters["so_device_token"] = detail.so_device_token
        requestParameters["so_manufacturer"] = SOEventConstant.manufacture
        requestParameters["so_last_used"] = detail.so_last_used
        requestDictionary["properties"] = requestParameters

          return requestDictionary
      }
        func trackDictionary(event : String, localProperties : Dictionary<String,String>?) -> Dictionary<String, Any> {
            
            var requestDictionary : Dictionary<String, Any> = Dictionary()
            requestDictionary["properties"] = deviceDictionary()
            
            if localProperties != nil {
                var dictCustProperty : Dictionary<String, Any> = Dictionary()
                for (key, value) in localProperties! {
                    dictCustProperty[key] = value
                }
                requestDictionary["custom_properties"] = dictCustProperty
            }
            return requestDictionary
        }
        func identityDictionary(detail:SOIdentityDM) -> Dictionary<String, Any> {
            
            var requestDictionary : Dictionary<String, Any> = Dictionary()
            var dictProperty : Dictionary<String, Any> = Dictionary()
            
            dictProperty["so_identified_id"] = detail.identified_id
            dictProperty["so_distinct_id"] = detail.dictinct_id
            dictProperty["so_created"] = detail.created
            dictProperty["so_time"] = detail.created
            requestDictionary["properties"] = dictProperty
            return requestDictionary
        }
       
        func engageDictionary(email: String?,phone: String?,name: String?,firstName: String?,lastName: String?, customProperty : Dictionary<String,String>?) -> Dictionary<String, Any> {
            
            var requestDictionary : Dictionary<String, Any> = Dictionary()
            var dictProperty : Dictionary<String, Any> = deviceDictionary()
            
            if email != nil{
                dictProperty["so_email"] = email
            }
            if phone != nil {
                dictProperty["so_phone"] = phone
            }
            if firstName != nil{
                dictProperty["so_first_name"] = firstName
            }
            if lastName != nil{
                dictProperty["so_last_name"] = lastName
            }
            if name != nil{
                dictProperty["so_name"] = name
            }
            let credated = String(Int64(Date().timeIntervalSince1970 * 1000))
            dictProperty["so_created"] = credated
            dictProperty["so_time"] = credated
            
            requestDictionary["properties"] = dictProperty
            
            
            if customProperty != nil {
                           var dictCustProperty : Dictionary<String, Any> = Dictionary()
                           for (key, value) in customProperty! {
                               dictCustProperty[key] = value
                           }
                           requestDictionary["custom_properties"] = dictCustProperty
                       }
            return requestDictionary
        }
        func convertToJSONDict(type:EndPoints?, dictionary:Dictionary<String, Any>) -> Dictionary<String, Any> {
            
            var requestDictionary : Dictionary<String, Any> = Dictionary()
            requestDictionary["data"] = self.convertIntoJson(dict: dictionary)
            if type != nil{
                requestDictionary["type"] = type!.rawValue
            }

            return requestDictionary
        }
    
        func convertToDictionary(text: String) -> [String: Any]? {
               if let data = text.data(using: .utf8) {
                   do {
                       return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                   } catch {
                       print(error.localizedDescription)
                   }
               }
               return nil
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
    
