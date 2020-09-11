                                  //
//  APIManager.swift
//  Sohil R. Memon
//  Version 1.0 - Swift 3.0

import UIKit
import MobileCoreServices
import SystemConfiguration

let BASEURL = "https://g7ij4r9bvk.execute-api.ap-south-1.amazonaws.com/dev/"

enum URLRequestType: String {
    case POST
    case GET
    case DELETE
}
                                  
enum apiEndPoints: String {
    case TRACK = "track"
    case IMPORT = "import"
    case ENGAGE = "engage"
    case GROUPS = "groups"
}

struct SOAPIManager {
    
    let getTask : URLSession 
    
    //MARK: Calling API
    
    static func callAPI(_ apiEndPoint: apiEndPoints, of type: URLRequestType, paramaters: [String : Any]? = nil, headers: [String : String]? = nil, _ completion : @escaping (_ dictResponse: Dictionary<String, AnyObject>?, _ error: Error?, _ statuscode: Int?) -> ()){
        let strAPI = BASEURL+apiEndPoint.rawValue
        
        switch type.rawValue {
        case "POST":
            postWebService(strAPI, paramaters!, headers, completion)
        case "GET":
            getWebService(strAPI, completionHandler: completion)
        default:
            break
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
    
    
    //MARK: Post API With Formdata
    
    static func postWebService(_ apiURL: String, _ paramaters: [String : Any]? = nil, _ headers: [String : String]? = nil, _ completion : @escaping (_ dictResponse: Dictionary<String, AnyObject>?, _ error: Error?, _ statuscode: Int?) -> ()){
        if SOAnalyticsReachability.isConnectedToNetwork() {
            let url = URL(string: apiURL)
            var request = URLRequest(url: url!)
            request.httpMethod = URLRequestType.POST.rawValue
            request.cachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalCacheData
            if let headers = headers{
                for value in headers.enumerated(){
                    request.setValue(value.element.value, forHTTPHeaderField: value.element.key)
                }
            }
            var paramString = String()
            for (key, value) in paramaters! {
                paramString = paramString + (key) + "=" + "\(value)" + "&"
            }
            request.httpBody = paramString.data(using: .utf8)
            let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
                DispatchQueue.main.async {
                    do{
                        
                        if let data = data{
                            if let httpResponse = response as? HTTPURLResponse {
                                //print(httpResponse.statusCode)
                                
                                if httpResponse.statusCode == 200 {
                                    //print("======> Data =====>", String(data: data, encoding: .utf8) as Any)
                                    
                                    var dict = Dictionary<String, AnyObject>()
                                    dict["success"] = String(data: data, encoding: .utf8) as AnyObject?
                                    print("responce \(dict)")
                                    completion(dict, nil, httpResponse.statusCode)
                                    /*
                                    let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String, AnyObject>
                                    if let parsedJSON = json{
                                        //Parsed JSON
                                        completion(parsedJSON, nil, httpResponse.statusCode)
                                    }else{
                                        // Woa, okay the json object was nil, something went worng. Maybe the server isn't running?
                                        let jsonStr = String(data: data, encoding: .utf8)
                                        #if DEBUG
                                        print("Error could not parse JSON: \(jsonStr ?? "Json String")")
                                        #endif
                                    }*/
                                } else {
                                    completion(nil, nil, httpResponse.statusCode)
                                }
                            } else {
                                print("Problem in success code")
                            }
                        } else{
                            completion(nil, error, -400)
                        }
                    } catch let error{
                        completion(nil, error, -400)
                    }
                }
            })
            task.resume()
        }else{
            print("Error calling analytics")
        }
    }
    
    
    //MARK: GET API
    
    static func getWebService(_ apiURL: String, completionHandler: @escaping (_ dictResponse: Dictionary<String, AnyObject>?, _ error: Error?, _ statuscode: Int?) -> ()){
        let getTask = URLSession.shared.dataTask(with: URL(string: apiURL)!) { (responseData, _, error) in
            DispatchQueue.main.async {
                do{
                    if responseData != nil{
                        
                        if let httpResponse = responseData as? HTTPURLResponse {
                            //print(httpResponse.statusCode)
                            if httpResponse.statusCode == 200 {
                                let json = try JSONSerialization.jsonObject(with: responseData!, options: JSONSerialization.ReadingOptions.allowFragments) as? Dictionary<String, AnyObject>
                                if let parsedJSON = json{
                                    //Json Parsed Successfully
                                    completionHandler(parsedJSON, nil, httpResponse.statusCode)
                                }else{
                                    //Cannot parse json or data must be nil
                                    let jsonStr = String(data: responseData!, encoding: String.Encoding.utf8)
                                    #if DEBUG
                                    print("Error could not parse JSON: \(jsonStr ?? "Json String")")
                                    #endif
                                }
                            } else {
                                completionHandler(nil, nil, httpResponse.statusCode)
                            }
                        } else {
                            print("Problem in success code")
                        }
                    }else{
                        completionHandler(nil, error, -400)
                    }
                }catch let error{
                    print(error.localizedDescription)
                    completionHandler(nil, error, -400)
                }
            }
        }
        getTask.resume()
    }

    //MARK: POST API With Image Upload
    
    //MARK: Post API With Formdata
    
    static func postAPIWithImageUpload(_ apiURL: String, _ paramaters: [String : Any]? = nil, _ headers: [String : String]? = nil, _ completion : @escaping (_ dictResponse: Dictionary<String, AnyObject>?, _ error: Error?) -> ()){
        if SOAnalyticsReachability.isConnectedToNetwork(){
            let strAPI = (apiURL.contains("://")) ? apiURL : BASEURL+apiURL
            
            let request = createRequest(strAPI, paramaters!, headers)
            let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
                DispatchQueue.main.async {
                    do{
                        if let data = data{
                            let json = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? Dictionary<String, AnyObject>
                            if let parsedJSON = json{
                                //Parsed JSON
                                completion(parsedJSON, nil)
                            }else{
                                // Woa, okay the json object was nil, something went worng. Maybe the server isn't running?
                                let jsonStr = String(data: data, encoding: .utf8)
                                #if DEBUG
                                print("Error could not parse JSON: \(jsonStr ?? "Json String")")
                                #endif
                            }
                        }else{
                            completion(nil, error)
                        }
                    }catch let error{
                        completion(nil, error)
                    }
                }
            })
            task.resume()
        }else{
            print("Error calling analytics")
        }
    }
    
    fileprivate static func createRequest(_ apiURL: String, _ paramaters: [String : Any]? = nil, _ headers: [String : String]? = nil) -> URLRequest{
        // build your dictionary however appropriate
        let boundary = generateBoundary()
        let url = URL(string: apiURL)
        var request = URLRequest(url: url!)
        request.httpMethod = URLRequestType.POST.rawValue
        request.timeoutInterval = 300
        if let headers = headers{
            for value in headers.enumerated(){
                request.setValue(value.element.value, forHTTPHeaderField: value.element.key)
            }
        }
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = createBody(withParamaters: paramaters, boundary)
        return request
        
    }
    
    /// Create boundary string for multipart/form-data request
    ///
    /// - returns:            The boundary string that consists of "Boundary-" followed by a UUID string.
    
    fileprivate static func generateBoundary() -> String {
        return "Boundary-\(UUID().uuidString)"
    }
    
    /// Create body of the multipart/form-data request
    ///
    /// - parameter parameters:   The optional dictionary containing keys and values to be passed to web service
    /// - parameter filePathKey:  The optional field name to be used when uploading files. If you supply paths, you must supply filePathKey, too.
    /// - parameter paths:        The optional array of file paths of the files to be uploaded
    /// - parameter boundary:     The multipart/form-data boundary
    ///
    /// - returns:                The Data of the body of the request
    
    fileprivate static func createBody(withParamaters paramaters: [String : Any]? = nil, _ boundary: String) -> Data{
        var body = Data()
        if let paramaters = paramaters{
            for value in paramaters.enumerated(){
                
                if let imgData = value.element.value as? Data{
                    body.append("--\(boundary)\r\n".data(using: .utf8)!)
                    body.append("Content-Disposition: form-data; name=\"\(value.element.key)\"; filename=\"img.jpg\"\r\n".data(using: .utf8)!)
                    body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
                    body.append(imgData)
                    body.append("\r\n".data(using: .utf8)!)
                }else{
                    body.append("--\(boundary)\r\n".data(using: .utf8)!)
                    body.append("Content-Disposition: form-data; name=\"\(value.element.key)\"\r\n\r\n".data(using: .utf8)!)
                    body.append("\(value.element.value)\r\n".data(using: .utf8)!)
                }
            }
        }
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        return body
    }
}

