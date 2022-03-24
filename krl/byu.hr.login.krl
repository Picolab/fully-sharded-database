ruleset byu.hr.login {
  meta {
    use module io.picolabs.wrangler alias wrangler
    use module id.trinsic.sdk alias trinsic
      with apiKey = meta:rulesetConfig{"api_key"} // a String from Trinsic
    shares verificationResponse, getVerification,
      listURL
  }
  global {
    domainRoot = meta:host.extract(re#(http.*):\d+$#).head()
    policyId = "abacb4f4-ed09-427f-c4cf-08d8ef1f9e90"
    verificationResponse = function(){
      ent:lastResponse
    }
    getVerification = function(verificationId){
      response = trinsic:getVerification(verificationId)
      ok = response{"status_code"} == 200
      content = ok => response{"content"}.decode() | null
      content
    }
    listURL = function(netid,position){
      theECI = wrangler:channels("byu-hr-oit").head().get("id")
      theURL = <<#{meta:host}/c/#{theECI}/query/byu.hr.oit/index.html>>
      fragment = position => "#" + position
               | netid    => "#" + netid
               | ""
      theURL+fragment
    }
    getLoggedInECI = function(person_id){
      wrangler:children()
        .filter(function(c){
          c.get("name")==person_id
        }).head().get("eci")
    }
  }
  rule doxReferer {
    select when byu_hr_login needed
    pre {
      referer = event:attrs{["_headers","referer"]}.klog("referer")
    }
    send_directive("referer",{"referer":referer})
  }
  rule setCookie {
    select when byu_hr_login needed
      netid re#(.+)# setting(netid)
    pre {
      referer = event:attrs{["_headers","referer"]}
      expected_re = ("^"+domainRoot).replace(re#[.]#g,"[.]").as("RegExp")
    }
    if referer && referer.match(expected_re) then
      send_directive("_cookie",{"cookie": <<netid=#{netid}; Path=/>>})
    fired {
      raise byu_hr_login event "cookie_set" attributes event:attrs
    }
  }
  rule redirectToOITindex {
    select when byu_hr_login cookie_set
      netid re#(.+)# setting(netid)
    pre {
      eci = wrangler:channels("byu-hr-login").head().get("id")
      logoutpath = <</sky/event/#{eci}/none/byu_hr_login/logout_request>>
      loggedInECI = getLoggedInECI(netid)
      display_name = loggedInECI => ctx:query(loggedInECI, "byu.hr.core", "displayName") | ""
      wellKnown_Rx = loggedInECI => ctx:query(loggedInECI, "io.picolabs.subscription","wellKnown_Rx").get("id") | ""
      homeECI = loggedInECI => ctx:query(loggedInECI, "byu.hr.core", "adminECI") | ""
      homepath = "/c/"+homeECI+"/query/byu.hr.core/index.html?personExists=true"
      loggedInRIDs = loggedInECI => ctx:query(loggedInECI, "io.picolabs.wrangler","installedRIDs") | []
      maRID = "byu.hr.manage_apps"
      apps = loggedInRIDs >< maRID => ctx:query(loggedInECI, maRID, "apps").join(",") | ""
    }
    every {
      send_directive("_cookie",{"cookie": <<logoutpath=#{logoutpath}; Path=/>>})
      send_directive("_cookie",{"cookie": <<displayname=#{display_name}; Path=/>>})
      send_directive("_cookie",{"cookie": <<wellKnown_Rx=#{wellKnown_Rx}; Path=/>>})
      send_directive("_cookie",{"cookie": <<homepath=#{homepath}; Path=/>>})
      send_directive("_cookie",{"cookie": <<apps=#{apps}; Path=/>>})
      send_directive("_redirect",{"url":listURL(netid)})
    }
  }
  rule logout {
    select when byu_hr_login logout_request
    every {
      send_directive("_cookie",{"cookie": <<logoutpath=; Path=/; Max-Age:-1>>})
      send_directive("_cookie",{"cookie": <<netid=; Path=/; Max-Age:-1>>})
      send_directive("_cookie",{"cookie": <<displayname=; Path=/; Max-Age:-1>>})
      send_directive("_cookie",{"cookie": <<wellKnown_Rx=; Path=/; Max-Age:-1>>})
      send_directive("_cookie",{"cookie": <<homepath=; Path=/; Max-Age:-1>>})
      send_directive("_cookie",{"cookie": <<apps=; Path=/; Max-Age:-1>>})
      send_directive("_redirect",{"url":domainRoot})
    }
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    wrangler:createChannel(
      [meta:rid],
      {"allow":[{"domain":"byu_hr_login","name":"*"}],"deny":[]},
      {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
    )
  }
  rule createVerification {
    select when byu_hr_login need_verification
    every {
      trinsic:createVerificationFromPolicy(policyId) setting(response)
      send_directive("Proof request",
        {"verification":response{"content"}.decode()})
    }
    fired {
      ent:lastResponse := response
    }
  }
  rule checkVerification {
    select when byu_hr_login verification_check_request
      verificationId re#(.+)# setting(verificationId)
    pre {
      content = getVerification(verificationId)
      ok = content{"isValid"} && content{"state"} == "Accepted"
      attributes = ok => content{["proof","Y Credential","attributes"]} | null
      netid = attributes => attributes{"Net ID"} | null
    }
    if netid then send_directive("Verified Net ID",{"netid":netid})
  }
}
