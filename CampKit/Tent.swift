//
//  Tent.swift
//  CampKit
//
//  Created by Brooks Newberry on 3/5/15.
//
//

import Foundation

public func unixTimestamp() -> String {
    let now = Int(round(NSDate().timeIntervalSince1970))
    return String(stringInterpolationSegment: now)
}

let campyErrorDomain = "campkit.error"

public enum CampyErrorCode: Int {
    case PostNotReady = 1080
    case MustRepost = 1081
    case PostIsUnmodified = 1082
    case PostIsModified = 1083
    case URLIsNotEntity = 1084
    case NeedsEntity = 1085
    case OauthAuthNoCode = 1086
    case OauthAuthStateMismatch = 1087
    case NeedAppID = 1088
}



public enum CampyErrorDescription: String {
    case PostNotReady = "check the value of Post.status. You may be missing some fields."
    case MustRepost = "You did not author this post. Use Post.repost() instead."
    case PostIsUnmodified = "This post has already been published. Modify the post, then use Post.updatePost()"
    case PostIsModified = "This post was already published once. Use Post.updatePost() instead."
    case URLIsNotEntity = "Looked up the entity, didn't find an associated meta post."
    case NeedsEntity = "Set the Tent.entity property."
    case OauthAuthNoCode = "No code query parameter contained in oauth_auth callback URL."
    case OauthAuthStateMismatch = "The user-supplied state did not match the server-supplied state."
    case NeedAppID = "Set the \"appid\" parameter or set Tent.authorization."
}
public typealias CampyAuthState = (authurl:NSURL, appid:String, tempid:String, tempkey:String, state:String)
public typealias CampyError = (code:CampyErrorCode, desc:CampyErrorDescription, domain:String)
public typealias CampyEndpointParams = (entity:String?, post:String?, digest:String?, name:String?)
public typealias CampyQuery = (limit:String?, max_refs:String?, sort_by:String?, since:NSDate?, until:NSDate?, before:NSDate?, types:[String]?, entities:[String]?, mentions:[String]?)


extension String {
    mutating func deleteCharactersInRange(range: NSRange) {
        let startIndex = advance(self.startIndex, range.location)
        let length = range.length
        self.removeRange(Range<String.Index>(start: startIndex, end:advance(startIndex, length)))
    }
    func rangesOfString(findStr:String) -> [Range<String.Index>] {
        var arr = [Range<String.Index>]()
        var startInd = self.startIndex
        // check first that the first character of search string exists
        if contains(self, first(findStr)!) {
            // if so set this as the place to start searching
            startInd = find(self,first(findStr)!)!
        }
        else {
            // if not return empty array
            return arr
        }
        var i = distance(self.startIndex, startInd)
        while i<=count(self)-count(findStr) {
            if self[advance(self.startIndex, i)..<advance(self.startIndex, i+count(findStr))] == findStr {
                arr.append(Range(start:advance(self.startIndex, i),end:advance(self.startIndex, i+count(findStr))))
                i = i+count(findStr)-1
                // check again for first occurrence of character (this reduces number of times loop will run
                if contains(self[advance(self.startIndex, i)..<self.endIndex], first(findStr)!) {
                    // if so set this as the place to start searching
                    i = distance(self.startIndex,find(self[advance(self.startIndex, i)..<self.endIndex],first(findStr)!)!) + i
                    count(findStr)
                }
                else {
                    return arr
                }
                
            }
            i++
        }
        return arr
    }
    mutating func replace(string:String, replacement:String) {

        let ranges = self.rangesOfString(string)

        for r in ranges {
            self.replaceRange(r, with: replacement)
        }
    }
    var length:Int {
        return count(self)
    }
    subscript (i:Int) -> Character {
        return self[advance(self.startIndex, i)]
    }
    func stringInRange(range: NSRange) -> String {
        let startIndex = advance(self.startIndex, range.location)
        let length = range.length
        if range.location + range.length > self.length {
            return self.substringWithRange(Range<String.Index>(start: startIndex, end:advance(startIndex, self.length-range.location)))
        } else {
            return self.substringWithRange(Range<String.Index>(start: startIndex, end:advance(startIndex, length)))
        }
    }
    mutating func stripRightChars(char:Character) {
        while self[advance(self.startIndex, count(self)-1)] == char {
            self = self.stringInRange(NSRange(location: 0, length: count(self)-1))
        }
    }
    mutating func stripLeftChars(char:Character) {
        while self[self.startIndex] == char {
            self = self.stringInRange(NSRange(location: 1, length: count(self)-1))
        }
    }
    func encodeToBase64Encoding() -> String {
        let utf8str = self.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        return utf8str.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.Encoding64CharacterLineLength)
    }
}



public func hexStringToBase64(string: String) -> String {
    // Based on: http://stackoverflow.com/a/2505561/313633
    //adapted from CryptoCoinSwift/RIPEMD-Swift
    var data = NSMutableData()
    
    var temp = ""
    
    for char in string {
        temp+=String(char)
        if(count(temp) == 2) {
            let scanner = NSScanner(string: temp)
            var value: CUnsignedInt = 0
            scanner.scanHexInt(&value)
            data.appendBytes(&value, length: 1)
            temp = ""
        }
        
    }
    
    return data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions())
}

public func normalizedHawkRequestString(method:Method, ts:String, nonce:String, url:NSURL, hash:String?, ext:String?, app:String?, dlg:String?) -> String{
    let h = hash ?? ""
    let a = app ?? ""
    let d = dlg ?? ""
    let e = ext ?? ""
    let hawkheader = "hawk.1.header"
    let resource = url.relativePath ?? ""
    let host = url.host ?? ""
    var port = ""
    
    if let p = url.port {
        port = p.stringValue
    } else if url.scheme == "https" {
        port = "443"
    } else {
        port = "80"
    }
    
    return "\(hawkheader)\n\(ts)\n\(nonce)\n\(method.rawValue)\n\(resource)\n\(host)\n\(port)\n\(h)\n\(e)\n\(a)\n\(d)\n"
}

public func hawkRequestHeader(mac:String, hawkid:String, method:Method, ts:String, nonce:String, url:NSURL, hash:String?, ext:String?, app:String?, dlg:String?) -> String{
    var h = ""
    var a = ""
    if hash != nil {
        h = ", hash=\"\(hash!)\""
    }
    if app != nil {
        a = ", app=\"\(app!)\""
    }

    return "Hawk id=\"\(hawkid)\", mac=\"\(mac)\", ts=\"\(ts)\", nonce=\"\(nonce)\"\(h)\(a)"
}
public func randomString(length:Int) -> String {
    let lettersnumbers = "qwertyuiopasdfghjklzxcvbnmQWERTYUIOPASDFGHJKLZXCVBNM1234567890"
    var line:String = ""
    for a in 1...length {
        line += "\(lettersnumbers[Int(arc4random_uniform(UInt32(lettersnumbers.length)))])"
    }
    return line
}
public func JSONify(data:NSData!) -> [String:AnyObject]?{
    return NSJSONSerialization.JSONObjectWithData(data as NSData, options: nil, error: nil) as? [String: AnyObject]
}

public func JSONStringify(value: AnyObject, pretty: Bool = false) -> String? {
    var options = pretty ? NSJSONWritingOptions.PrettyPrinted : nil
    if NSJSONSerialization.isValidJSONObject(value) {
        if let data = NSJSONSerialization.dataWithJSONObject(value, options: options, error: nil), string = NSString(data: data, encoding: NSUTF8StringEncoding) as? String {
            return string
        }
    }
    return nil
}

public func stringToBase64(string:String) -> String {
    let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
    return data!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions())
}

func sha256(string:String) -> String {
    let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
    let res = NSMutableData(length: Int(CC_SHA256_DIGEST_LENGTH))
    CC_SHA256(data!.bytes, CC_LONG(data!.length), UnsafeMutablePointer(res!.mutableBytes))
    return res!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions())
}

func sha256(data:NSData) -> String {
    let res = NSMutableData(length: Int(CC_SHA256_DIGEST_LENGTH))
    CC_SHA256(data.bytes, CC_LONG(data.length), UnsafeMutablePointer(res!.mutableBytes))
    return res!.base64EncodedStringWithOptions(NSDataBase64EncodingOptions())
}


public protocol CampKitMetaCache: class {
    func cacheFindMeta(entity:String) -> Meta?
    func cacheSaveMeta(meta:Meta)
}
public enum Endpoint: String {
    case oauth_auth = "oauth_auth"
    case oauth_token = "oauth_token"
    case posts_feed = "posts_feed"
    case new_post = "new_post"
    case post = "post"
    case post_attachment = "post_attachment"
    case attachment = "attachment"
    case batch = "batch"
    case server_info = "server_info"
    case discover = "discover"
}
public enum Method: String {
    case HEAD = "HEAD"
    case GET = "GET"
    case POST = "POST"
    case DELETE = "DELETE"
    case PUT = "PUT"
}
public struct Authorization {
    public init(entity:String, hawkID:String, hawkKey:String, appID:String) {
        self.entity = entity
        self.hawkID = hawkID
        self.hawkKey = hawkKey
        self.appID = appID
    }
    public let entity:String
    public let hawkID:String
    public let hawkKey:String
    public let appID:String
}
public struct App {
    public let redirect_uri:String
    public let name:String
    public let url:String
    public let readtypes:[String]
    public let writetypes:[String]
    public let publicpost:Bool
    public init(redirect_uri:String, name:String, url:String, readtypes:[String], writetypes:[String], publicpost:Bool) {
        self.redirect_uri = redirect_uri
        self.name = name
        self.url = url
        self.readtypes = readtypes
        self.writetypes = writetypes
        self.publicpost = publicpost
    }
}

public class Tent: CampKitMetaCache {
    
    public enum TentStatus {
        case Ready, Unauthorized, NeedsReauthorization, WaitingForAuthCallback
    }
    
    let a = "Hello, this is a Tent!"
    let httprange = "http://".rangeOfString("http://")
    let httpsrange = "https://".rangeOfString("https://")
    public var authcallbackurltoken:String
    weak var appOpenedObserver:AnyObject? {
        willSet(newObserver) {
            if appOpenedObserver != nil {
                //NSNotificationCenter.defaultCenter().removeObserver(appOpenedObserver!, name: "UIApplicationDidBecomeActiveNotification", object: nil)
            }
        }
        didSet {
            
        }
    }
    public var authstate:CampyAuthState?
    public var tentStatus:TentStatus = .Unauthorized
    public var authorization:Authorization? {
        didSet {
            if self.authorization != nil {
                self.tentStatus = .Ready
                self.entity = self.authorization?.entity
            }
        }
    }

    weak var MetaCacheDelegate:CampKitMetaCache? {
        didSet {
            if self.meta == nil && self.entity != nil && MetaCacheDelegate != nil {
                self.meta = MetaCacheDelegate!.cacheFindMeta(self.entity!)
            }
        }
    }
    public var entity:String?
    public var meta:Meta?
    
    public init(authorization:Authorization?){
        authcallbackurltoken = randomString(12)
        self.authorization = authorization
        if let entity = authorization?.entity {
            self.entity = entity
        }
    }
    public convenience init(meta:Meta?){
        self.init(authorization: nil)
        self.meta = meta
        if let entity = meta?.content.entity {
            self.entity = entity
        }
    }
    public convenience init(entity:String){
        self.init(meta:nil)
        self.entity = entity
        self.MetaCacheDelegate = self
    }

    public func greeting() -> String {
        return a
    }

    class func errDesc(code:CampyErrorDescription) -> [NSObject:AnyObject] {
        return [NSLocalizedDescriptionKey: code.rawValue]
    }
    public class func err(code:CampyErrorCode, desc:CampyErrorDescription) -> NSError {
        return NSError(domain: campyErrorDomain, code: code.rawValue, userInfo: Tent.errDesc(desc))
    }
    public func registerMetaCacheDelegate(MetaCacheDelegate:CampKitMetaCache) {
        self.MetaCacheDelegate = MetaCacheDelegate
    }
    
    public func cacheFindMeta(entity:String) -> Meta? {
        println("looking for cached meta in Tent.findMeta")
        return NSCache().objectForKey(entity) as? Meta
    }
    public func cacheSaveMeta(meta:Meta){
        println("caching meta in Tent.findMeta")
        NSCache().setObject(meta, forKey: meta.content.entity)
    }
    
    func reduceEntity(entity:String) -> String{
        //var r = NSRegularExpression(pattern: <#String#>, options: <#NSRegularExpressionOptions#>, error: nil)
        return "reduced"
    }
    
    func tentIsAuthorized() -> Bool {
        if(entity != nil && authorization != nil){
            return true
        } else {
            return false
        }
    }
    
    public func getMeta(entity: String, callback:(meta:Meta?)->()) {
        if MetaCacheDelegate != nil {
            let cachedmeta = MetaCacheDelegate!.cacheFindMeta(entity)
            if cachedmeta != nil {
                callback(meta: cachedmeta)
            } else {
                freshMeta(entity, callback: callback)
            }
        } else {
            println("no MetaCacheDelegate. Going to get a fresh post")
            freshMeta(entity, callback: callback)
        }
    }
    
    func freshMeta(entity:String, callback:(meta:Meta?)->()){
        discoverMetaURL(entity) { url in
            if url == nil {
                callback(meta: nil)
                return;
            }
            let metaurl = url!
            
            let retrievedhttprange = metaurl.rangeOfString("http://")
            let retrievedhttpsrange = metaurl.rangeOfString("https://")
            var absolutemetapath = metaurl
            if retrievedhttprange != self.httprange && retrievedhttpsrange != self.httpsrange {
                var e = entity
                e.stripRightChars("/")
                var p = metaurl
                p.stripLeftChars("/")
                absolutemetapath = e + "/" + p
            }
            let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            var request = NSMutableURLRequest(URL: NSURL(string: absolutemetapath)!)
            request.HTTPMethod = "GET"
            let session = NSURLSession(configuration: configuration)
            let task = session.dataTaskWithRequest(request) { (data, response, error) in
                if let json = NSJSONSerialization.JSONObjectWithData(data as NSData, options: nil, error: nil) as? [String: AnyObject], post = json["post"] as? [String:AnyObject]{
                    self.meta = Meta(authorization: self.authorization, post: post)
                    callback(meta: self.meta)
                } else {
                    callback(meta: nil)
                }
            }
            task.resume()
        }
    }
    
    public class func payloadDigest(payload:String, type:String) -> String {
        let hawkheader = "hawk.1.payload"
        let p = "\(hawkheader)\n\(type)\n\(payload)\n"
        return sha256(p)
    }
    public class func hashHMAC(key:String, payload:String) -> String {
        let hmacEncrypt:SweetHMAC = SweetHMAC(message: payload, secret: key)
        let sha = hmacEncrypt.HMAC(.SHA256)
        return sha
    }
    class func request(method:Method, url:NSURL, data:CampyDict?, headers:[String:String]?, authorization:Authorization?, callback:(NSData!, NSURLResponse!, NSError!)->()){
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        var request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = method.rawValue
        //var headers:[String:String] = Dictionary<String, String>()
        
        if headers != nil {
            configuration.HTTPAdditionalHeaders = headers!
            for h in headers! {
                request.setValue(h.1, forHTTPHeaderField: h.0)
            }
        }

        var jsonError:NSError?
        if data != nil {
            //var error: NSError?
            
            if let str = JSONStringify(data!, pretty: true) {
                request.HTTPBody = str.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
            } else if let js = NSJSONSerialization.dataWithJSONObject(data!, options: nil, error: &jsonError) {
                request.HTTPBody = js
            } else {
                println("JSON error: \(jsonError)")
            }
        }
        let session = NSURLSession(configuration: configuration)
        let task = session.dataTaskWithRequest(request, completionHandler: callback)
        if jsonError == nil {
            task.resume()
        } else {
            callback(nil, nil, jsonError)
        }
    }
    
    public func endpointRequest(endpoint:String, method:Method, data:CampyDict?, query:CampyQuery?, endpointParams:CampyEndpointParams?, callback:(CampyDict?, NSError?)->()){
        self.endpointRequestWithAuthorization(self.authorization, endpoint:endpoint, method: method, data: data, query:query, endpointParams:endpointParams, callback: callback)
    }
    
    func endpointRequestWithAuthorization(authorization:Authorization?, endpoint:String, method:Method, data:CampyDict?, query:CampyQuery?, endpointParams:CampyEndpointParams?, callback:(CampyDict?, NSError?)->()) {
        let auth = authorization ?? self.authorization
        if self.entity == nil {
            callback(nil, Tent.err(.NeedsEntity, desc: .NeedsEntity))
        } else if self.meta != nil {
            self.endpointRequestWithMeta(auth, endpoint:endpoint, method: method, data: data, query:query, endpointParams:endpointParams, callback: callback)
        } else if self.entity != nil {
            getMeta(self.entity!) { meta in
                if meta != nil {
                    self.endpointRequestWithMeta(auth, endpoint:endpoint, method: method, data: data, query:query, endpointParams:endpointParams, callback: callback)
                } else {
                    callback(nil, Tent.err(.URLIsNotEntity, desc: .URLIsNotEntity))
                }
            }
        }
    }
    
    func endpointRequestWithMeta(authorization:Authorization?, endpoint:String, method:Method, data:CampyDict?, query:CampyQuery?, endpointParams:CampyEndpointParams?, callback:(CampyDict?, NSError?)->()){
        if self.meta != nil {
            if let endpturl = urlFromEndpoint(self.meta!, endpoint:endpoint, query: query, endpointParams: endpointParams), url = NSURL(string:endpturl) ?? NSURL(string: endpoint) {
                var headers = ["Accept":"application/vnd.tent.post.v0+json", "Content-Type":"application/vnd.tent.post.v0+json"]
                if endpoint == "oauth_auth" || endpoint == "oauth_token" || authorization == nil {
                    headers = ["Accept":"application/json", "Content-Type":"application/json"]
                }
                let timestamp = unixTimestamp()
                let nonce = randomString(8)
                if authorization != nil {
                    let app = authorization!.appID
                    var hash:String?
                    if data != nil {
                        if let body = JSONStringify(data!, pretty: false){
                            hash = Tent.payloadDigest(body, type: headers["Content-Type"]!)
                        }
                    }
                    let normalizedreq = normalizedHawkRequestString(method, timestamp, nonce, url, hash, nil, app, nil)
                    
                    let mac = hexStringToBase64(Tent.hashHMAC(authorization!.hawkKey, payload: normalizedreq))
                    let authheader = hawkRequestHeader(mac, authorization!.hawkID, method, timestamp, nonce, url, hash, nil, app, nil)
                    headers["Authorization"] = authheader
                }
                Tent.request(method, url: url, data: data, headers:headers, authorization: nil){ data, res, err in
                    let json = NSJSONSerialization.JSONObjectWithData(data as NSData, options: nil, error: nil) as? [String:AnyObject]
                    callback(json, err)
                }
            } else {
                callback(nil, NSError(domain: campyErrorDomain, code: CampyErrorCode.URLIsNotEntity.rawValue, userInfo: Tent.errDesc(.URLIsNotEntity)))
            }
        } else {
            callback(nil, NSError(domain: campyErrorDomain, code: CampyErrorCode.URLIsNotEntity.rawValue, userInfo: Tent.errDesc(.URLIsNotEntity)))
        }
    }
    func urlFromEndpoint(meta:Meta, endpoint:String, query:CampyQuery?, endpointParams:CampyEndpointParams?) -> String? {
        let pref = meta.content.servers[0].preference ?? 0
        let urls = meta.content.servers[pref].urls
        var url = String()
        switch endpoint {
            case "oauth_auth":
                url = urls.oauth_auth
            case "oauth_token":
                url = urls.oauth_token
            case "posts_feed":
                url = urls.posts_feed
            case "post":
                url = urls.post
            case "new_post":
                url = urls.new_post
            case "post_attachment":
                url = urls.post_attachment
            case "attachment":
                url = urls.attachment
            case "batch":
                url = urls.batch ?? ""
            case "server_info":
                url = urls.server_info ?? ""
            case "discover":
                url = urls.discover ?? ""
            default:
                return nil
        }
        if endpointParams != nil {
            if endpointParams!.entity != nil {
                url.replace("{entity}", replacement: endpointParams!.entity!)
            }
            if endpointParams!.digest != nil {
                url.replace("{digest}", replacement: endpointParams!.digest!)
            }
            if endpointParams!.name != nil {
                url.replace("{name}", replacement: endpointParams!.name!)
            }
            if endpointParams!.post != nil {
                url.replace("{post}", replacement: endpointParams!.post!)
            }
        }
        
        if query != nil {
            var querycounter = 0
            var querystring = "?"
            if query!.before != nil {
                querystring += "before=\"\(query!.before!.timeIntervalSince1970)\""
                querycounter++
            }
            if query!.entities != nil {
                if querycounter > 0 { querystring += "&" }
                querycounter++
                querystring += "entities="
                var entitycounter = 0
                for e in query!.entities! {
                    if entitycounter > 0 {
                        querystring += ","
                    }
                    querystring += e
                    entitycounter++
                }
            }
            if query!.limit != nil {
                if querycounter > 0 { querystring += "&" }
                querycounter++
                querystring != "limit=\(query!.limit!)"
            }
            if query!.max_refs != nil {
                if querycounter > 0 { querystring += "&" }
                querycounter++
                querystring != "max_refs=\(query!.max_refs!)"
            }
            if query!.mentions != nil {
                if querycounter > 0 { querystring += "&" }
                querycounter++
                querystring += "mentions="
                var mentioncounter = 0
                for m in query!.mentions! {
                    if mentioncounter > 0 {
                        querystring += ","
                    }
                    querystring += m
                    mentioncounter++
                }
            }
            if query!.since != nil {
                if querycounter > 0 { querystring += "&" }
                querycounter++
                querystring != "since=\(query!.since!.timeIntervalSince1970)"
            }
            if query!.sort_by != nil {
                if querycounter > 0 { querystring += "&" }
                querycounter++
                querystring += "sort_by=\(query!.sort_by!)"
            }
            if query!.types != nil {
                if querycounter > 0 { querystring += "&" }
                querycounter++
                querystring += "types="
                var typecounter = 0
                for t in query!.types! {
                    if typecounter > 0 {
                        querystring += ","
                    }
                    querystring += t
                    typecounter++
                }
            }
            url += querystring
        }
        
        if url == "" {
            return nil
        } else {
            return url
        }
    }
    
    func discoverMetaURL(entity:String, callback:(metaurl:String?)->()){
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        var request = NSMutableURLRequest(URL: NSURL(string: entity)!)
        request.HTTPMethod = "HEAD"
        let session = NSURLSession(configuration: configuration)
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            if error != nil {
                println(error)
                callback(metaurl:nil)
                return;
            }
            if let r = response as? NSHTTPURLResponse, let linkheader = r.allHeaderFields["Link"] as? String, link = Tent.linkHeaderToMeta(linkheader, entity: entity) {
                //let link = Tent.linkToMeta(linkheader, entity: entity)
                callback(metaurl:link)
            } else {
                callback(metaurl:nil)
            }
        }
        task.resume()
    }
    
    /** 
    The first step to authorize an app.
    
    :param: app  This will be made into the Tent app post
    
    :return: Save the state, as Tent.authorizeApp will compare the redirect_uri for security. The URL is the location of the Tent login page, and this must be shown to the user. The page will then redirect to the redirect_uri.
    */
    public func registerApp(app:App, callback:(state:CampyAuthState?, error:NSError?)->()) {
        if self.entity == nil {
            callback(state: nil, error:Tent.err(.NeedsEntity, desc: .NeedsEntity))
            return;
        }
        getMeta(self.entity!) { meta in
            if meta == nil {
                callback(state: nil, error: Tent.err(.URLIsNotEntity, desc: .URLIsNotEntity))
                return;
            }
            let servpref:Int = meta!.content.servers[0].preference ?? 0
            let appPost = AppPost(authorization: nil, app: app)
            let appjson = appPost.getCampyJSON()
            let url = NSURL(string: meta!.content.servers[servpref].urls.new_post)
            Tent.request(.POST, url: url!, data: ["type":appPost.type,"content":appjson["content"]!], headers:["Content-Type":"application/vnd.tent.post.v0+json; type=\"\(appPost.type)\""], authorization: nil) { data, response, error in
                
                if error != nil {
                    callback(state: nil, error: error)
                    return;
                }
                let s = NSString(data: data, encoding: NSUTF8StringEncoding)
                let aj = NSJSONSerialization.JSONObjectWithData(data as NSData, options: nil, error: nil) as? [String:AnyObject]
                
                let p = aj?["post"] as? [String:AnyObject]
                
                let ad = p?["id"] as? String
                
                if let
                    appjson = NSJSONSerialization.JSONObjectWithData(data as NSData, options: nil,
                    error: nil) as? [String:AnyObject],
                    post = appjson["post"] as? [String:AnyObject],
                    appid = post["id"] as? String,
                    r = response as? NSHTTPURLResponse,
                    linkheader = r.allHeaderFields["Link"] as? String,
                    link = Tent.linkHeaderToCredentials(linkheader),
                    credentialsurl = NSURL(string: link)
                {
                    
                    Tent.request(.GET, url: credentialsurl, data: nil, headers:nil, authorization: nil) { data, response, error in
                        if let
                            json = NSJSONSerialization.JSONObjectWithData(data as NSData, options: nil, error: nil) as? [String: AnyObject],
                            post = json["post"] as? [String:AnyObject],
                            content = post["content"] as? [String:AnyObject],
                            tempid = post["id"] as? String,
                            tempkey = content["hawk_key"] as? String
                        {
                            let state = randomString(12)
                            let oauth_auth = meta!.content.servers[servpref].urls.oauth_auth
                            let urlcomps = NSURLComponents(string: oauth_auth)
                            let client_id = NSURLQueryItem(name: "client_id", value: appid)
                            let stateparam = NSURLQueryItem(name: "state", value: state)
                            if urlcomps?.queryItems != nil {
                                urlcomps?.queryItems?.append(client_id)
                                urlcomps?.queryItems?.append(stateparam)
                            } else {
                                urlcomps?.queryItems = [client_id, stateparam]
                            }
                            let oauth_url = urlcomps?.URL
                            self.authstate = (oauth_url!, appid, tempid, tempkey, state)
                            callback(state: self.authstate, error: nil)
                        }
                    }
                }
            }
        }
    }
    
    /**
        The seconds step to authorize an app, following Tent.registerApp()
    */
    
    public func authorizeApp(callbackURL:NSURL, state stateFromRegistration:CampyAuthState?, callback:(authorization:Authorization?, error:NSError?)->()) {
        if self.entity == nil {
            callback(authorization: nil, error:Tent.err(.NeedsEntity, desc: .NeedsEntity))
        } else {
            getMeta(self.entity!) { meta in
                if meta == nil {
                    callback(authorization: nil, error: Tent.err(.URLIsNotEntity, desc: .URLIsNotEntity))
                    return;
                }
                let servpref:Int = meta!.content.servers[0].preference ?? 0
                if let appid = stateFromRegistration?.appid ?? self.authstate?.appid,
                    tempid = stateFromRegistration?.tempid ?? self.authstate?.tempid,
                    tempkey = stateFromRegistration?.tempkey ?? self.authstate?.tempkey
                {
                    let query = callbackURL.query?.componentsSeparatedByString("&")
                    if query != nil {
                        var queryDict:[String:String] = [:]
                        for i in 0..<query!.count {
                            let splitparam = query![i].componentsSeparatedByString("=")
                            if splitparam.count == 2 {
                                queryDict[splitparam[0]] = splitparam[1]
                            }
                        }
                        let state = queryDict["state"]
                        let code = queryDict["code"]
                        if code == nil || (false) {
                            callback(authorization: nil, error: Tent.err(.OauthAuthNoCode, desc: .OauthAuthNoCode))
                            return;
                        }
                        if stateFromRegistration != nil && state != nil && stateFromRegistration!.state != state! {
                            callback(authorization: nil, error: Tent.err(.OauthAuthStateMismatch, desc: .OauthAuthStateMismatch))
                            return;
                        }
                        let oauth_token = meta!.content.servers[servpref].urls.oauth_token
                        let auth = Authorization(entity: self.entity!, hawkID: tempid, hawkKey: tempkey, appID: appid)
                        self.endpointRequestWithAuthorization(auth, endpoint: "oauth_token", method: .POST, data: ["code":code!, "token_type":"https://tent.io/oauth/hawk-token"], query: nil, endpointParams: nil){ response, error in
                            
                            if error != nil {
                                callback(authorization: nil, error: error)
                            } else if let json = response,
                                hawkid = json["access_token"] as? String,
                                hawkkey = json["hawk_key"] as? String
                            {
                                self.authorization = Authorization(entity: self.entity!, hawkID: hawkid, hawkKey: hawkkey, appID: appid)
                                callback(authorization: self.authorization, error: nil)
                            } else {
                                callback(authorization: nil, error: NSError())
                            }
                        }
                    } else {
                        callback(authorization: nil, error: Tent.err(.OauthAuthNoCode, desc: .OauthAuthNoCode))
                    }
                } else {
                    callback(authorization: nil, error: Tent.err(.NeedAppID, desc: .NeedAppID))
                }
            }
        }
    }
    
    private class func linkHeaderToCredentials(linkheader:String) -> String? {
        
        return linkHeader(linkheader, entity:nil, rel: "https://tent.io/rels/credentials")
    }
    
    private class func linkHeaderToMeta(linkheader:String, entity:String)->String? {
        return linkHeader(linkheader, entity:entity, rel:"https://tent.io/rels/meta-post")
    }
    
    private class func linkHeader(linkheader:String, entity:String?, rel:String)->String? {
        var link:String? = nil
        if linkheader.rangeOfString("rel=\"\(rel)\"") != nil {
            var charcounter = 0
            var brackettoken = false
            var endtoken = false
            for char in linkheader {
                if charcounter == 0 {
                    if char == "<" {
                        charcounter++
                        link = ""
                    } else {
                        link = nil
                        break
                    }
                } else if char == ">" {
                    brackettoken = true
                } else if brackettoken == true && char == ";" {
                    endtoken = true
                    break
                } else if endtoken == false {
                    link?.append(char)
                }
                charcounter++
            }
            if endtoken == false {
                link = nil
            }
        }
        if entity != nil && link != nil && link?.stringInRange(NSRange(location: 0, length: 1)) == "/" {
            if entity!.stringInRange(NSRange(location: entity!.length-1, length: 1)) == "/" {
                link = entity!.stringInRange(NSRange(location: 0, length: entity!.length-1)) + link!
            } else {
                link = entity! + link!
            }
        }
        
        return link
    }
}