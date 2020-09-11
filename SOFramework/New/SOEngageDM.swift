//
//  SOEngageManager.swift
//  SOFramework
//
//  Created by SOTSYS138 on 03/09/20.
//  Copyright © 2020 SOTSYS203. All rights reserved.
//

import UIKit
class SOEngageDM : Codable {
    let id  : String
    let timeStamp: Int64
    
    let created: String
    let distinct_id: String
    let deviceData: String
    init(id : String,timeStamp: Int64,distinct_id: String,deviceData:String) {
        self.id = id
        self.timeStamp = timeStamp
        self.created = String(Int64(Date().timeIntervalSince1970 * 1000))
        self.distinct_id = distinct_id
        self.deviceData = deviceData
    }
    
    convenience init(distinct_id: String,deviceData: String) {
        self.init( id : UUID().uuidString, timeStamp: Date().millisecondsSince1970,distinct_id:distinct_id,deviceData:deviceData)
    }
    
    static var pastEvent: [SOEngageDM] {
        get {
            
            do {
                let array = try JSONDecoder().decode([SOEngageDM].self, from: UserDefaults.standard.unSyncedEngage).sorted(by: { (event1, event2) -> Bool in
                    return event1.timeStamp < event2.timeStamp
                })
                return array
            } catch {
                return []
            }
            
        }set {
            do {
                UserDefaults.standard.unSyncedEngage = try JSONEncoder().encode(newValue)
            } catch {}
            
        }
    }
    
}
//---------------------------------------------------------
//MARK: - SOEventDM + Equatable
extension SOEngageDM: Equatable {
    static func == (lhs: SOEngageDM, rhs: SOEngageDM) -> Bool {
        return lhs.id == rhs.id
    }
}

//---------------------------------------------------------

extension SOEngageDM {
    
    // Save to local
    func saveToLocalIfNeeded() {
        
        var eventsDMs = SOEngageDM.pastEvent
        
        if eventsDMs.firstIndex(of: self) == nil {
            debugPrint("SOFramework : Save locally engage")
            eventsDMs.append(self)
        }
        SOEngageDM.pastEvent = eventsDMs
    }
    static func removeFromLocalIfExists(events : [SOEngageDM]) {
        
        var pastEvents = SOEngageDM.pastEvent
        
        pastEvents.removeAll { (pastevent) -> Bool in
            return  events.contains(where: { (event) -> Bool in
                if event.timeStamp == pastevent.timeStamp{
                    debugPrint("SOFramework : remove locally engage")
                    return true
                }
                return false
                
            })
        }
        SOEngageDM.pastEvent = pastEvents
    }
}
private extension UserDefaults {
    var unSyncedEngage: Data {
        get {
            return (value(forKey: #function) as? Data) ?? Data()
        }
        set {
            set(newValue, forKey: #function); synchronize()
        }
    }
}
