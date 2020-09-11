//
//  SOIdentityDM.swift
//  SOFramework
//
//  Created by SOTSYS138 on 04/09/20.
//  Copyright © 2020 SOTSYS203. All rights reserved.
//

import UIKit


class SOIdentityDM : Codable {
    
    let identified_id : String
    let dictinct_id : String
    let id  : String
    let timeStamp: Int64
    let created: String
    
    init( id : String,timeStamp: Int64,identified_id: String) {
        self.identified_id = identified_id
        self.id = id
        self.dictinct_id = DeviceInfo().distinct_id
        self.timeStamp = timeStamp
        self.created = String(Int64(Date().timeIntervalSince1970 * 1000))
    }
    
    convenience init(identified_id: String) {
        self.init(id : UUID().uuidString, timeStamp: Date().millisecondsSince1970,identified_id: identified_id)
    }
    
    static var pastEvent: [SOIdentityDM] {
        get {
            
            do {
                let array = try JSONDecoder().decode([SOIdentityDM].self, from: UserDefaults.standard.unSyncedIdentity).sorted(by: { (event1, event2) -> Bool in
                    return event1.timeStamp < event2.timeStamp
                })
                return array
            } catch {
                return []
            }
            
        }set {
            do {
                UserDefaults.standard.unSyncedIdentity = try JSONEncoder().encode(newValue)
            } catch {}
            
        }
    }
    
}
//---------------------------------------------------------
//MARK: - SOEventDM + Equatable
extension SOIdentityDM: Equatable {
    static func == (lhs: SOIdentityDM, rhs: SOIdentityDM) -> Bool {
        return lhs.id == rhs.id
    }
}

//---------------------------------------------------------

extension SOIdentityDM {
    
    // Save to local
    func saveToLocalIfNeeded() {
        
        var eventsDMs = SOIdentityDM.pastEvent
        
        if eventsDMs.firstIndex(of: self) == nil {
            debugPrint("SOFramework : Save locally identity")
            eventsDMs.append(self)
        }
        SOIdentityDM.pastEvent = eventsDMs
    }
    static func removeFromLocalIfExists(events : [SOIdentityDM]) {
        
        var pastEvents = SOIdentityDM.pastEvent
        pastEvents.removeAll { (pastevent) -> Bool in
            return  events.contains(where: { (event) -> Bool in
                if event.timeStamp == pastevent.timeStamp{
                    debugPrint("SOFramework : remove locally identity")
                    return true
                }
                return false
            })
        }
        SOIdentityDM.pastEvent = pastEvents
    }
}

private extension UserDefaults {
    var unSyncedIdentity: Data {
        get {
            return (value(forKey: #function) as? Data) ?? Data()
        }
        set {
            set(newValue, forKey: #function); synchronize()
        }
    }
}
