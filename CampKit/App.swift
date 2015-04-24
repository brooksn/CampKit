//
//  App.swift
//  CampKit
//
//  Created by Brooks Newberry on 3/31/15.
//
//

import Foundation

public class AppPost:Post {
    public var content:App!
    public let posttype = "https://tent.io/types/app/v0#"
    
    override init?(authorization: Authorization?, post: [String : AnyObject]) {
        if let content = post["content"] as? [String:AnyObject],
            name = content["name"] as? String,
            url = content["url"] as? String,
            types = content["types"] as? [String:AnyObject],
            read = types["read"] as? [String],
            write = types["write"] as? [String],
            redirect_uri = content["redirect_uri"] as? String,
            permissions = post["permissions"] as? [String:AnyObject],
            publicpost = permissions["public"] as? Bool
        {
            self.content = App(redirect_uri:redirect_uri, name:name, url:url, readtypes:read, writetypes:write, publicpost:publicpost)
        } else {
            super.init(authorization: authorization, post: post)
            return nil
        }
        super.init(authorization: authorization, post: post)
    }
    init(authorization:Authorization?, app:App) {
        content = app
        super.init(type: posttype, authorization: authorization)
    }
    
    public override func getCampyJSON() -> [String : AnyObject] {
        var json = super.getCampyJSON()
        json["type"] = posttype
        json["permissions"] = ["public":content.publicpost]
        var c = ["name": content.name, "url": content.url, "types": ["read": content.readtypes, "write": content.writetypes], "redirect_uri":content.redirect_uri, "scopes":["permissions"]]
        json["content"] = c
        return json
    }
}
