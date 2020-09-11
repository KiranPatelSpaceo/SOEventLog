//
//  SONotificationDM.swift
//  SOFramework
//
//  Created by SOTSYS138 on 09/09/20.
//  Copyright © 2020 SOTSYS203. All rights reserved.
//

import UIKit


class SONotificationDM : Codable {
    
    let id  : String
    let timeStamp: Int64
    let so_device_token: String
    let so_last_used: String

    init(so_device_token : String,id:String) {
        self.so_device_token = so_device_token
        self.id = id
        self.timeStamp = Date().millisecondsSince1970
        self.so_last_used = String(Int64(Date().timeIntervalSince1970 * 1000))
    }
    
    convenience init(so_device_token:String) {
        self.init(so_device_token : so_device_token,id:UUID().uuidString)
    }
    
    static var pastEvent: [SONotificationDM] {
        get {
            
            do {
                let array = try JSONDecoder().decode([SONotificationDM].self, from: UserDefaults.standard.unSyncedNotification).sorted(by: { (event1, event2) -> Bool in
                    return event1.timeStamp < event2.timeStamp
                })
                return array
            } catch {
                return []
            }
            
        }set {
            do {
                UserDefaults.standard.unSyncedNotification = try JSONEncoder().encode(newValue)
            } catch {}
            
        }
    }
    
}
//---------------------------------------------------------
//MARK: - SOEventDM + Equatable
extension SONotificationDM: Equatable {
    static func == (lhs: SONotificationDM, rhs: SONotificationDM) -> Bool {
        return lhs.id == rhs.id
    }
}
extension SONotificationDM {
    
    // Save to local
    func saveToLocalIfNeeded() {
        
        var eventsDMs = SONotificationDM.pastEvent
        
        if eventsDMs.firstIndex(of: self) == nil {
            debugPrint("SOFramework : Save locally Notification")
            
            eventsDMs.append(self)
        }
        SONotificationDM.pastEvent = eventsDMs
        
    }
    
    static func removeFromLocalIfExists(events : [SONotificationDM]) {
        
        var pastEvents = SONotificationDM.pastEvent
        pastEvents.removeAll { (pastevent) -> Bool in
            return  events.contains(where: { (event) -> Bool in
                if event.timeStamp == pastevent.timeStamp{
                    debugPrint("SOFramework : remove locally Notification")
                    return true
                }
                return false
            })
        }
        SONotificationDM.pastEvent = pastEvents
    }
}


//---------------------------------------------------------
//MARK:-
private extension UserDefaults {
    var unSyncedNotification: Data {
        get {
            return (value(forKey: #function) as? Data) ?? Data()
        }
        set {
            set(newValue, forKey: #function); synchronize()
        }
    }
}


