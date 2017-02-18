//
//  FlickrContants.swift
//  Virtual Tourist
//
//  Created by Flavio Kreis on 18/02/17.
//  Copyright © 2017 Flavio Kreis. All rights reserved.
//

import Foundation

extension FlickrClient {
    
    // MARK: Constants
    
    struct Constants {
        static let ApiScheme = "https"
        static let ApiHost = "api.flickr.com"
        static let ApiPath = "/services/rest/"
        static let APIKey = "YOUR_KEY"
        static let Method = "flickr.photos.search"
        
    }
    
    struct ParamaterKeys {
        static let Method = "method"
        static let APIKey = "api_key"
        static let Latitude = "lat"
        static let Longitude = "lon"
        static let PerPage = "per_page"
        static let Page = "page"
        static let Format = "format"
        static let CallBack = "nojsoncallback"
    }
    
    struct JSONResponseKeys {
        static let ID = "id"
        static let Secret = "secret"
        static let Server = "server"
        static let Farm = "farm"
        static let Photo = "photo"
    }
    
}
