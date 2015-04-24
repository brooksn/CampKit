//
//  Meta.swift
//  CampKit
//
//  Created by Brooks Newberry on 3/17/15.
//
//

import Foundation

public class Profile:PostContent {
    public var name:String?
    public var bio:String?
    public var location:String?
    public var website:String?
    
    init?(profile:[String:String]){
        //super.init()
        name = profile["name"]
        bio = profile["bio"]
        location = profile["location"]
        website = profile["website"]
        if name == nil && bio == nil && location == nil && website == nil {
            return nil
        }
    }
    public func getCampyJSON() -> [String:AnyObject]{
        var json = CampyStringDict()
        
        json["name"] = name!
        json["bio"] = bio!
        json["location"] = location!
        json["website"] = website!
        return json
    }
}

public class ServerURLs:PostContent {
    public var oauth_auth:String
    public var oauth_token:String
    public var posts_feed:String
    public var new_post:String
    public var post:String
    public var post_attachment:String
    public var attachment:String
    public var batch:String?
    public var server_info:String?
    public var discover:String?
    
    init?(urls:[String:String]){
        if let
            oauth_auth = urls["oauth_auth"],
            oauth_token = urls["oauth_token"],
            posts_feed = urls["posts_feed"],
            new_post = urls["new_post"],
            post = urls["post"],
            post_attachment = urls["post_attachment"],
            attachment = urls["attachment"]
        {
            self.oauth_auth = oauth_auth
            self.oauth_token = oauth_token
            self.posts_feed = posts_feed
            self.new_post = new_post
            self.post = post
            self.post_attachment = post_attachment
            self.attachment = attachment
        } else {
            oauth_token=""; oauth_auth=""; posts_feed=""; post=""; post_attachment=""; attachment=""; new_post=""
            //super.init()
            return nil
        }
        self.batch = urls["batch"]
        self.server_info = urls["server_info"]
        self.discover = urls["discover"]
        //super.init()
    }
    public func getCampyJSON() -> [String:AnyObject] {
        var json = CampyStringDict()
        json["oauth_auth"] = oauth_auth
        json["oauth_token"] = oauth_token
        json["posts_feed"] = posts_feed
        json["new_post"] = new_post
        json["post"] = post
        json["post_attachment"] = post_attachment
        json["attachment"] = attachment
        json["batch"] = batch!
        json["server_info"] = server_info!
        json["discover"] = discover!
        return json
    }
}

public class Server:PostContent {
    public var version:String?
    public var preference:Int?
    public var urls:ServerURLs!
    
    init?(server:[String:AnyObject]) {
        if let version = server["version"] as? String, preference = server["preference"] as? Int, urls = server["urls"] as? [String:String] {
            self.version = version
            self.preference = preference
            if let serverurls = ServerURLs(urls: urls) {
                self.urls = serverurls
            } else {
                //super.init()
                return nil
            }
        } else {
            //super.init()
            return nil
        }
        //super.init()
    }
    public func getCampyJSON() -> [String:AnyObject] {
        var json = CampyDict()
        json["version"] = version!
        json["preference"] = preference!
        json["urls"] = urls.getCampyJSON()
        return json
    }
}


public class MetaContent:PostContent {
    public var entity:String
    public var previous_entities:[String]?
    public var servers:[Server] = []
    public var profile:Profile?
    
    init?(content: [String:AnyObject]){
        if let entity = content["entity"] as? String {
            self.entity = entity
        } else {
            entity = ""
            return nil
        }
        self.previous_entities = content["previous_entities"] as? [String]
        if let profile = content["profile"] as? [String:String] {
           self.profile = Profile(profile: profile)
        }
        if let servers = content["servers"] as? [[String:AnyObject]] {
            for aserver in servers {
                if let server = Server(server:aserver) {
                    self.servers.append(server)
                }
            }
        }
    }
    public func getCampyJSON() -> [String:AnyObject] {
        var json = CampyDict()
        json["entity"] = entity
        json["previous_entities"] = previous_entities!
        json["profile"] = self.profile?.getCampyJSON()
        var servlist:[AnyObject] = []
        for server in servers {
            servlist.append( server.getCampyJSON() )
        }
        if servlist.count > 0 {
            json["servers"] = servlist
        }
        return json
    }
}

/**
    A Post which must be initialized with data from an existing meta post.
*/
public class Meta:Post {
    public var content:MetaContent!
    
    override init?(authorization:Authorization?, post:[String:AnyObject]){
        if let contentjson = post["content"] as? [String:AnyObject],  content = MetaContent(content: contentjson) {
            self.content = content
        } else {
            super.init(authorization: authorization, post: post)
            return nil
        }
        super.init(authorization: authorization, post: post)
    }
    convenience init?(post:[String:AnyObject]){
        self.init(authorization:nil, post:post)
    }
    
    override public func getCampyJSON() -> [String:AnyObject] {
        var json = super.getCampyJSON()
        json["content"] = content?.getCampyJSON()
        return json
    }
    
}
