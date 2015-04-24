//
//  Status.swift
//  CampKit
//
//  Created by Brooks Newberry on 3/24/15.
//
//

import Foundation

public class Status:Post {
    var rawtext:String?
    public var text:String? {
        get {
            return rawtext?.precomposedStringWithCanonicalMapping
        }
        set(newtext) {
            rawtext = newtext
        }
    }
    public var location:(longitude:Double, latitude:Double)?
    
    public override func getCampyJSON() -> [String : AnyObject] {
        var json = super.getCampyJSON()
        
        if text != nil {
            var content:[String:AnyObject] = [:]
            content["text"] = text!
            
            if location != nil {
                content["location"] = ["latitude": String(stringInterpolationSegment:location!.latitude), "longitude": String(stringInterpolationSegment:location!.longitude)]
            }
            
            json["content"] = content
        } else {
            json.removeValueForKey("content")
        }
        
        return json
    }
}
