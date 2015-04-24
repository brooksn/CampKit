//
//  CampKitTests.swift
//  CampKitTests
//
//  Created by Brooks Newberry on 3/5/15.
//
//

import XCTest
import CampKit

class CampKitTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        XCTAssert(true, "Pass")
    }

    func testSweetHMAC() {
        var hmac = Tent.hashHMAC("Jefe", payload:"what do ya want for nothing?")

        XCTAssert(hmac == "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843", "HMAC with SHA256")
    }
    
    func testHawkRequestEncode(){
        let req = "hawk.1.header\n1353832234\nj4h3g2\nGET\n/resource/1?b=1&a=2\nexample.com\n8000\n\nsome-app-ext-data\n"
        let reqhash = Tent.hashHMAC("werxhqb98rpaxn39848xrunpaw3489ruxnpa98w4rxn", payload: req)
        let base64hash = hexStringToBase64(reqhash)
        XCTAssert(base64hash == "6R4rV5iE+NPoym+WwjeHzjAGXUtLNIxmo1vpMofpLAE=", "base64 encoding of hmac works")
    }
    
    func testPayloadHash(){
        var pload = "{\"type\":\"https://tent.io/types/status/v0#\"}"
        var type = "application/vnd.tent.post.v0+json"
        var t1payload = Tent.payloadDigest(pload, type:type)
        var t2payload = Tent.payloadDigest("Thank you for flying Hawk", type: "text/plain")
        XCTAssert(t1payload == "neQFHgYKl/jFqDINrC21uLS0gkFglTz789rzcSr7HYU=", "Tent sample payload")
        XCTAssert(t2payload == "Yi9LfIIFRtBEPt74PVmbTF/xVAwPn7ub15ePICfgnuY=", "Hawk sample payload")
    }
    
    func testRequestMac(){
        let pload = "{\"type\":\"https://tent.io/types/status/v0#\"}"
        var type = "application/vnd.tent.post.v0+json"
        let hash = Tent.payloadDigest(pload, type:type)
        let ext:String? = nil
        let app = "wn6yzHGe5TLaT-fvOPbAyQ"
        let method = Method.POST
        let nonce = "3yuYCD4Z"
        let ts = "1368996800"
        let dlg:String? = nil
        let id = "exqbZWtykFZIh2D7cXi9dA"
        
        let testheader = "Hawk id=\"exqbZWtykFZIh2D7cXi9dA\", mac=\"2sttHCQJG9ejj1x7eCi35FP23Miu9VtlaUgwk68DTpM=\", ts=\"1368996800\", nonce=\"3yuYCD4Z\", hash=\"neQFHgYKl/jFqDINrC21uLS0gkFglTz789rzcSr7HYU=\", app=\"wn6yzHGe5TLaT-fvOPbAyQ\""

        let t1 = normalizedHawkRequestString(.POST, ts, nonce, NSURL(string: "https://example.com/posts")!, hash, nil, app, nil)
        println(t1)
        let s1 = "hawk.1.header\n1368996800\n3yuYCD4Z\nPOST\n/posts\nexample.com\n443\nneQFHgYKl/jFqDINrC21uLS0gkFglTz789rzcSr7HYU=\n\nwn6yzHGe5TLaT-fvOPbAyQ\n\n"
        
        var t1key = "HX9QcbD-r3ItFEnRcAuOSg"
        let t1mac = hexStringToBase64(Tent.hashHMAC(t1key, payload: t1))
        let t1authheader = hawkRequestHeader(t1mac, id, .POST, ts, nonce, NSURL(string: "https://example.com/posts")!, hash, nil, app, nil)
        println("t1authheader: \(t1authheader)")
        println("mac: \(t1mac)")
        XCTAssert(t1 == s1, "correct normalized string")
        XCTAssert(t1mac == "2sttHCQJG9ejj1x7eCi35FP23Miu9VtlaUgwk68DTpM=", "correct Mac")
        XCTAssert(t1authheader == testheader, "correct Authorization header")
    }
    
    func testMyEntity() {
        let expectation = expectationWithDescription("should get a profile.")
        
        var t = Tent(entity: "https://brooks.cupcake.is")
        t.getMeta("https://brooks.cupcake.is") { opmeta in
            expectation.fulfill()
            if let meta = opmeta {
                XCTAssert(meta.content.entity == "https://brooks.cupcake.is", "Found my own profile")
            } else {
                XCTFail("Couldn't find my profile")
            }
        }
        
        waitForExpectationsWithTimeout(10) { (error) in
            
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
