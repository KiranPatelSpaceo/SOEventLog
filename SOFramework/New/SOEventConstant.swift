//
//  SOEventConstant.swift
//  SOFramework
//
//  Created by SOTSYS138 on 02/09/20.
//  Copyright © 2020 SOTSYS203. All rights reserved.
//

import UIKit


class SOEventConstant {
    static var baseURL : String {
        get{
            if SOAnalytics.shareInstance.isTestEnviorment {
                return localURL
            }
            return liveURL
        }
    }
    static var liveURL =  "https://g7ij4r9bvk.execute-api.ap-south-1.amazonaws.com/dev/"
    static var localURL =  "https://g7ij4r9bvk.execute-api.ap-south-1.amazonaws.com/dev/"

    struct Event {
        
        static let eventParameterKey = "event"
        static let firstAppOpenUserDefaultKey = "firstAppOpenUserDefault"
        static let appVersionUserDefaultKey = "appVersionUserDefault"
        static let firstAppOpen = "so_ae_first_open"
        static let appUpdated = "so_ae_updated"
        static let appLunched = "so_ae_launched"
        static let appSession = "so_ae_session"
        static let appCrashed = "so_ae_crashed"

    }
    static let appIdentifierKey = "appIdentifierKey"

    static let manufacture = "Apple"

    static let UDIdentifyKey = "so_identified_id"
}
enum EndPoints: String {
    case TRACK = "track"
    case IDENTIFY = "identify"
    case IMPORT = "import"
    case ENGAGE = "engage"
    case GROUPS = "groups"
    case DEVICE = "device"

}
