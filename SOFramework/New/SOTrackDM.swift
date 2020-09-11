//
//  SOTrackManager.swift
//  SOFramework
//
//  Created by SOTSYS138 on 04/09/20.
//  Copyright © 2020 SOTSYS203. All rights reserved.
//

import UIKit

class SOEventDM : Codable {
    
    let event : String
    let id  : String
    let timeStamp: Int64
    let dictData: String
    let appID: String
    init(event : String,dict:String,id:String) {
        self.event = event
        self.id = id
        self.timeStamp = Date().millisecondsSince1970
        self.dictData = dict
        self.appID = SOAnalytics.shareInstance.appID
    }
    
    convenience init(event : String,dict:String) {
        self.init(event : event, dict: dict,id:UUID().uuidString)
    }
    
    static var pastEvent: [SOEventDM] {
        get {
            
            do {
                let array = try JSONDecoder().decode([SOEventDM].self, from: UserDefaults.standard.unSyncedEvents).sorted(by: { (event1, event2) -> Bool in
                    return event1.timeStamp < event2.timeStamp
                })
                return array
            } catch {
                return []
            }
            
        }set {
            do {
                UserDefaults.standard.unSyncedEvents = try JSONEncoder().encode(newValue)
            } catch {}
            
        }
    }
    
}
//---------------------------------------------------------
//MARK: - SOEventDM + Equatable
extension SOEventDM: Equatable {
    static func == (lhs: SOEventDM, rhs: SOEventDM) -> Bool {
        return lhs.id == rhs.id
    }
}

//---------------------------------------------------------

extension SOEventDM {
    
    // Save to local
    func saveToLocalIfNeeded() {
        
        var eventsDMs = SOEventDM.pastEvent
        
        if eventsDMs.firstIndex(of: self) == nil {
            debugPrint("SOFramework : Save locally \(self.event)")
            
            eventsDMs.append(self)
        }
        SOEventDM.pastEvent = eventsDMs
        
    }
    
    static func removeFromLocalIfExists(events : [SOEventDM]) {
        
        var pastEvents = SOEventDM.pastEvent
        pastEvents.removeAll { (pastevent) -> Bool in
            return  events.contains(where: { (event) -> Bool in
                if event.timeStamp == pastevent.timeStamp{
                    debugPrint("SOFramework : remove locally \(event.event)")
                    return true
                }
                return false
            })
        }
        SOEventDM.pastEvent = pastEvents
    }
}


//---------------------------------------------------------
//MARK:-
private extension UserDefaults {
    var unSyncedEvents: Data {
        get {
            return (value(forKey: #function) as? Data) ?? Data()
        }
        set {
            set(newValue, forKey: #function); synchronize()
        }
    }
}


