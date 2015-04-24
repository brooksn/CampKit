//
//  File.swift
//  CampKit
//
//  Created by Brooks Newberry on 3/19/15.
//
//

import Foundation

public class File {
    
    public class func exists (path: String) -> Bool {
        return NSFileManager().fileExistsAtPath(path)
    }
    
    public class func read (path: String, encoding: NSStringEncoding = NSUTF8StringEncoding) -> String? {
        if File.exists(path) {
            return String(contentsOfFile:path, encoding: encoding, error: nil)!
        }
        
        return nil
    }
    
    public class func write (path: String, content: String, encoding: NSStringEncoding = NSUTF8StringEncoding) -> Bool {
        return content.writeToFile(path, atomically: true, encoding: encoding, error: nil)
    }
}
