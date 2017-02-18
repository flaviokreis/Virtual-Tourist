//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Flavio Kreis on 18/02/17.
//  Copyright © 2017 Flavio Kreis. All rights reserved.
//

import UIKit

class FlickrClient: NSObject {
    
    // MARK: Properties
    
    var session = URLSession.shared
    
    static var shared = FlickrClient()
    
    // MARK: Initializer
    
    override private init() {
        super.init()
    }
    
    func getPhotos(latitude: Double, longitude: Double, page: Int?, completionHandlerForGetPhotos: @escaping (_ success: Bool, _ data: [String:AnyObject]?, _ errorString: String?) -> Void) {
        
        // Build Parameter
        let parameters = [ParamaterKeys.APIKey:Constants.APIKey, ParamaterKeys.Method:Constants.Method, ParamaterKeys.Latitude:latitude, ParamaterKeys.Longitude:longitude, ParamaterKeys.Format: "json", ParamaterKeys.CallBack: 1, ParamaterKeys.PerPage:20, ParamaterKeys.Page:page!] as [String : Any]
        
        // Make GET Method
        let _ = taskForGETMethod(parameters: parameters as [String : AnyObject]) { (result, error) in
            
            if let error = error {
                print(error)
                completionHandlerForGetPhotos(false, nil, "Error: getPhotos Method")
            } else {
                if let results = result?["photos"] as? [String:AnyObject] {
                    
                    completionHandlerForGetPhotos(true, results, nil)
                } else {
                    print("Could not find photos in \(result)")
                    completionHandlerForGetPhotos(false, nil, "Error: getPhotos Methods")
                }
            }
        }
    }
    
    func downloadPhoto(url: URL, completion: @escaping (_ data: Data?, _ response: URLResponse?, _ error: Error?) -> Void) {
        let task = session.dataTask(with: url) { (data, response, error) in
            completion(data, response, error)
        }
        
        task.resume()
    }
    
    static func createPhotoUrl(_ photo: [String:AnyObject]) -> URL {
        return URL(string: "https://farm\(photo[FlickrClient.JSONResponseKeys.Farm]!).staticflickr.com/\(photo[FlickrClient.JSONResponseKeys.Server]!)/\(photo[FlickrClient.JSONResponseKeys.ID]!)_\(photo[FlickrClient.JSONResponseKeys.Secret]!).jpg")!
    }
    
    // MARK: GET
    
    func taskForGETMethod(parameters: [String:AnyObject], completionHandlerForGET: @escaping (_ result: NSDictionary?, _ error: NSError?) -> Void) -> URLSessionDataTask {
        
        // Build URL
        let request = NSMutableURLRequest(url: parseURLFromParameters(parameters: parameters))
        
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            func sendError(_ error: String) {
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForGET(nil, NSError(domain: "Flickr Client (taskForGETMethod)", code: 1, userInfo: userInfo))
            }
            guard (error==nil) else {
                sendError("There was an error with your request: \(error)")
                return
            }
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned a status code other than 2xx!")
                return
            }
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            print(data)
            self.convertDataWithCompletionHandler(data, completionHandlerForConvertData: completionHandlerForGET)
        }
        task.resume()
        return task
    }
    
    private func convertDataWithCompletionHandler(_ data: Data, completionHandlerForConvertData: (_ result: NSDictionary?, _ error: NSError?) -> Void) {
        
        var parsedResult: NSDictionary! = nil
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! NSDictionary
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForConvertData(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        completionHandlerForConvertData(parsedResult, nil)
    }
    
    private func parseURLFromParameters(parameters: [String:AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.ApiScheme
        components.host = Constants.ApiHost
        components.path = Constants.ApiPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        return components.url!
    }
}
