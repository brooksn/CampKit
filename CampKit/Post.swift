//
//  Post.swift
//  CampKit
//
//  Created by Brooks Newberry on 3/6/15.
//
//

import Foundation

public typealias CampyDict = [String:AnyObject]
public typealias CampyList = [[String:AnyObject]]
public typealias CampyStringDict = [String:String]
public typealias CampyStringList = [String]

func campyListToJSON(inout json:CampyDict, key:String, list:[PostContent]?) {
    if list != nil {
        var campylist:[AnyObject] = []
        for i in 0..<list!.count {
            campylist[i] = list![i].getCampyJSON()
        }
        if campylist.count > 0 {
            json[key] = campylist
        }
    }
}
func campyDictOf(key:String, list:[PostContent]) -> [String:AnyObject] {
    var campylist:[AnyObject] = []
    for i in 0..<list.count {
        campylist[i] = list[i].getCampyJSON()
    }
    return [key:campylist]
}
func campyListOf(list:[PostContent]) -> [AnyObject] {
    var campylist:[AnyObject] = []
    for i in 0..<list.count {
        campylist[i] = list[i].getCampyJSON()
    }
    return campylist
}

public protocol PostContent {
    func getCampyJSON() -> [String:AnyObject]
}

public class Attachment:PostContent {
    public var data:NSData? {
        willSet(newdata) {
            if newdata != nil {
                self.size = newdata?.length
            }
        }
    }
    public var category:String?
    public var content_type:String?
    public var digest:String?
    public var name:String?
    public var size:Int?
    
    init?(attachment:CampyDict) {
        self.category = attachment["category"] as? String
        self.content_type = attachment["content_type"] as? String
        self.digest = attachment["digest"] as? String
        self.name = attachment["name"] as? String
        self.size = attachment["size"] as? Int
    }
    
    public func getCampyJSON() -> [String : AnyObject] {
        var json = [String:AnyObject]()
        json["category"] = category!
        json["content_type"] = content_type!
        json["digest"] = digest!
        json["name"] = name!
        return json
    }
    
}


public class PostRef:PostContent {
    var entity:String?
    var original_entity:String?
    var post:String
    var version:String?
    var type:String?
    
    init?(ref:[String:String]) {
        if let post = ref["post"] {
            self.post = post
        } else {
            post="";
            return nil
        }
        entity = ref["entity"]
        original_entity = ref["original_entity"]
        version = ref["version"]
        type = ref["type"]
    }
    public func getCampyJSON() -> [String:AnyObject] {
        var json = CampyStringDict()
        json["post"] = self.post
        json["entity"] = entity!
        json["original_entity"] = original_entity!
        json["type"] = type!
        json["version"] = version!
        return json
    }
}

public class PostMention:PostRef {
    var pub:Bool?
    
    init?(mention: [String : AnyObject]) {
        if let ispublic = mention["public"] as? Bool {
            var m = mention
            m.removeValueForKey("public")
            super.init(ref: m as! [String:String])
            self.pub = ispublic
        } else {
            super.init(ref: mention as! [String:String])
        }
    }
    public override func getCampyJSON() -> [String : AnyObject] {
        var json = super.getCampyJSON()
        if self.pub != nil { json["public"] = self.pub }
        return json
    }
}


public class Post:Tent, PostContent {
    public enum PostStatus {
        case Unowned, Unpublished, Modified, Unmodified
    }
    override public var entity:String? {
        willSet {
            if self.entity != self.postEntity {
                self.postStatus = .Unowned
            }
        }
    }
    public var postStatus:PostStatus?
    public var attachments:[Attachment] = []
    public var postEntity:String! {
        willSet {
            if self.postEntity != self.entity {
                self.postStatus = .Unowned
            }
        }
    }
    public var version:(id:String, published_at:NSDate, parents:[[String:String]])?
    public var app:(name:String, url:String)?
    public var published_at:NSDate?
    public var id:String?
    public var type:String
    public var refs:[PostRef] = []
    public var mentions:[PostMention] = []
    public var permissions_entities:[String] = []
    public var permissions_groups:[String] = []
    public var permissions_public:Bool = false
    public var postcontent:[String:AnyObject]?
    
    init(type:String, authorization:Authorization?){
        self.type = type
        super.init(authorization:authorization)
    }
    
    init?(authorization:Authorization?, post:[String:AnyObject]){
        if let entity = post["entity"] as? String, type = post["type"] as? String, id = post["id"] as? String, date = post["published_at"] as? Int {
            self.postEntity = entity
            self.type = type
            self.id = id
            self.published_at = NSDate(timeIntervalSince1970: Double(date))
            
        } else {
            type = ""
            super.init(authorization: nil)
            return nil
        }
        if let app = post["app"] as? [String:String], appname = app["name"], appurl = app["url"] {
            self.app = (name:appname, url:appurl)
        }
        if let permissions = post["permissions"] as? CampyDict {
            self.permissions_public = permissions["public"] as? Bool ?? false
            if let groups = permissions["groups"] as? [[String:String]] {
                for i in 0..<groups.count {
                    if let group = groups[i]["post"] {
                        self.permissions_groups[i] = group
                    }
                }
            }
            if let entities = permissions["entities"] as? [String] {
                self.permissions_entities = entities
            }
        }
        if let attachments = post["attachments"] as? [[String:AnyObject]] {
            for attachment in attachments {
                if let a = Attachment(attachment: attachment) {
                    self.attachments.append(a)
                }
            }
        }
        if let version = post["version"] as? [String:AnyObject] {
            if let versionid = version["id"] as? String, versionpublished = version["published_at"] as? Int {
                self.version = (id:versionid, published_at:NSDate(timeIntervalSince1970: Double(versionpublished)), parents:[])
                if let versionparents = version["parents"] as? [[String:String]] {
                    self.version!.parents = versionparents
                }
            }
        }
        super.init(authorization: authorization)
    }

    public convenience init?(post:[String:AnyObject]) {
        self.init(authorization:nil, post:post)
    }
    
    public func getCampyJSON() -> [String:AnyObject] {
        var json = CampyDict()
        json["type"] = type
        json["entity"] = self.postEntity
        json["id"] = id ?? nil
        if published_at != nil { json["published_at"] = Int(published_at!.timeIntervalSince1970) }
        if refs.count > 0 {
            json["refs"] = campyListOf(refs)
        }
        
        campyListToJSON(&json, "mentions", mentions)
        var permissions:[String:AnyObject] = [:]
        if permissions_entities.count > 0 {
            permissions["entities"] = permissions_entities
        }
        if permissions_groups.count > 0 {
            var groups:[[String:String]] = []
            for i in 0..<permissions_groups.count {
                groups.append(["post": permissions_entities[i]])
            }
            permissions["groups"] = groups
        }
        if permissions.count > 0 {
            json["permissions"] = permissions
        }
        json["content"] = postcontent
        if let app = self.app {
            json["app"] = ["name":app.name, "url":app.url]
        }
        
        var a:[[String:AnyObject]] = []
        for i in 0..<attachments.count {
            a.append(attachments[i].getCampyJSON())
        }
        if a.count > 0 {
            json["attachments"] = a
        }
        
        if version != nil {
            var v:[String:AnyObject] = ["id": version!.id, "published_at": version!.published_at.timeIntervalSince1970]
            if version!.parents.count > 0 {
                v["parents"] = version!.parents
            }
            json["version"] = v
        }
        
        return json
    }
    
    public func getCampyJSONString() -> NSString? {
        var json = getCampyJSON()
        var prettyPrinted = true
        var options = prettyPrinted ? NSJSONWritingOptions.PrettyPrinted : nil
        if NSJSONSerialization.isValidJSONObject(json) {
            if let data = NSJSONSerialization.dataWithJSONObject(json, options: options, error: nil), string = NSString(data: data, encoding: NSUTF8StringEncoding) {
                return string
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    
    public func post(callback:(error:NSError?)->()){
        self.postLogic(callback, needsAuth: true)
    }
    public func unauthorizedPost(callback:(error:NSError?)->()){
        self.postLogic(callback, needsAuth:false)
    }
    func postLogic(callback:(error:NSError?)->(), needsAuth:Bool){
        if self.tentStatus != .Ready {
            callback(error: NSError(domain: campyErrorDomain, code: CampyErrorCode.PostNotReady.rawValue, userInfo: [NSLocalizedDescriptionKey:CampyErrorCode.PostNotReady.rawValue]))
        } else if self.postStatus == .Unowned {
            callback(error: NSError(domain: campyErrorDomain, code: CampyErrorCode.MustRepost.rawValue, userInfo: [NSLocalizedDescriptionKey:CampyErrorCode.MustRepost.rawValue]))
        } else if self.postStatus == .Unmodified {
            callback(error: NSError(domain: campyErrorDomain, code: CampyErrorCode.PostIsUnmodified.rawValue, userInfo: [NSLocalizedDescriptionKey:CampyErrorCode.PostIsUnmodified.rawValue]))
        } else if self.postStatus == .Modified {
            callback(error: NSError(domain: campyErrorDomain, code: CampyErrorCode.PostIsModified.rawValue, userInfo: [NSLocalizedDescriptionKey:CampyErrorCode.PostIsModified.rawValue]))
        } else if self.authorization == nil && needsAuth == true {
            callback(error: NSError(domain: campyErrorDomain, code: CampyErrorCode.PostIsModified.rawValue, userInfo: Tent.errDesc(.PostIsModified)))
        } else if self.postStatus == .Unpublished {
            //do something with self.postContent
            //then do Tent stuff
            //pass along callback
            callback(error: nil)
        } else {
            //endpointRequest(<#endpoint: String#>, data: <#CampyDict?#>, callback: <#(CampyDict?, NSError?) -> ()##(CampyDict?, NSError?) -> ()#>)
        }
    }
}
