ruleset byu.hr.login {
  meta {
    use module io.picolabs.wrangler alias wrangler
    use module id.trinsic.sdk alias trinsic
      with apiKey = meta:rulesetConfig{"api_key"} // a String from Trinsic
    shares verificationResponse, getVerification,
      listURL
  }
  global {
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
                           | "#" + netid
      theURL+fragment
    }
  }
  rule setCookie {
    select when byu_hr_login needed
      netid re#(.+)# setting(netid)
    pre {
      referer = event:attrs{["_headers","referer"]}
      prefix = meta:host + "/c/" + meta:eci + "/query/" + meta:rid + "/"
      pages = "(credential|password).html"
      expected_re = ("^" + prefix + pages).replace(re#[.]#g,"[.]").as("RegExp")
      alt_re = "^https://byname.byu.edu/".as("RegExp")
    }
    if referer && (referer.match(expected_re) || referer.match(alt_re)) then
      send_directive("_cookie",{"cookie": <<netid=#{netid}; Path=/c>>})
    fired {
      raise byu_hr_login event "cookie_set" attributes event:attrs
    }
  }
  rule redirectToOITindex {
    select when byu_hr_login cookie_set
      netid re#(.+)# setting(netid)
    send_directive("_redirect",{"url":listURL(netid)})
  }
  rule logout {
    select when byu_hr_login logout_request
    pre {
      domain_root = meta:host.extract(re#(http.*):\d+$#).head()
    }
    every {
      send_directive("_cookie",{"cookie": <<netid=; Path=/c; Max-Age:-1>>})
      send_directive("_redirect",{"url":domain_root})
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
