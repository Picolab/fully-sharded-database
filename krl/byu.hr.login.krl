ruleset byu.hr.login {
  meta {
    use module html
    use module io.picolabs.wrangler alias wrangler
    use module id.trinsic.sdk alias trinsic
      with apiKey = meta:rulesetConfig{"api_key"} // a String from Trinsic
    shares index, password, credential,
      verificationResponse, getVerification,
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
    admins = meta:rulesetConfig{"admins"} // an Array of strings (Net IDs)
    index = function(netid){
      styles = <<    <style type="text/css">
      div#loginchoice {
       max-width:200px;
       text-align:center;
       border: 2px solid grey;
       border-radius: 5px;
       padding: 15px 5px;
       margin-left: 20px;
      }
      div#loginchoice button {
        cursor:pointer;
      }
      div#loginchoice p {
        color: grey;
      }
    </style>
>>
      html:header("HR OIT Login",styles)
      + <<<h1>HR OIT: Personnel -- Login</h1>
<p>Please demonstrate that you a member of the BYU community.</p>
<p>To obtain a credential, visit <a href="https://ycred.byu.edu" target="_blank">YCred.byu.edu</a>.</p>
<div id="loginchoice">
<button onclick="location='credential.html'">Login with credential</button>
<p>OR</p>
<button onclick="location='password.html'" disabled>Login with password</button>
</div>
>>
      + html:footer()
    }
    password = function(){
      loginURL = <<#{meta:host}/sky/event/#{meta:eci}/none/byu_hr_login/needed>>
      html:header("HR OIT Login")
      + <<<h1>HR OIT: Personnel -- Login</h1>
<h2>Login with password</h2>
<div id="d1">
<form method="get" action="#{loginURL}">
Your NetID is
<input name="netid" autofocus>
<button type="submit" disabled>Go</button>
</form>
</div>
>>
      + html:footer()
    }
    credential = function(){
      loginURL = <<#{meta:host}/sky/event/#{meta:eci}/none/byu_hr_login/needed>>
      dmn = meta:rid.replace(re#[.]#g,"_")
      typ = "verification_check_request"
      poll_state = <<#{meta:host}/sky/event/#{meta:eci}/none/#{dmn}/#{typ}>>
      typ2 = "need_verification"
      get_verif = <<#{meta:host}/sky/event/#{meta:eci}/none/#{dmn}/#{typ2}>>
      scripts = <<<script src="https://manifold.picolabs.io:9090/js/jquery-3.1.0.min.js"></script>
<!-- thanks to Jerome Etienne http://jeromeetienne.github.io/jquery-qrcode/ -->
<script type="text/javascript" src="https://manifold.picolabs.io:9090/js/jquery.qrcode.js"></script>
<script type="text/javascript" src="https://manifold.picolabs.io:9090/js/qrcode.js"></script>
<script type="text/javascript">
$(function(){
  $.getJSON("#{get_verif}", function(d){
    if (d && d.directives && d.directives.length == 1
        && d.directives[0].name == "Proof request"
        && d.directives[0].options
        && d.directives[0].options.verification) {
      var verif = d.directives[0].options.verification
      var verificationId = verif.verificationId
      var verifReqUrl = verif.verificationRequestUrl
      $("div#qrcode").qrcode({ text: verifReqUrl, foreground: "#000000" });
      $("span#generating").css({"visibility":"hidden"});
      //wait for user to present
      var timer
      var poll_setup = function(v1,v2,v3){
        if (timer) clearTimeout(timer)
        var f1 = v1
        var f2 = v2
        var secSpan = document.getElementById("sec")
        var verified = function(d){
          if (d && d.directives && d.directives.length == 1
              && d.directives[0].name == "Verified Net ID"
              && d.directives[0].options
              && d.directives[0].options.netid) {
            return d.directives[0].options.netid
          } else {
            return false
          }
        }
        var poll = function(sec){
          console.log(sec)
          secSpan.textContent = ""+sec
          timer = setTimeout(function(){
            $.getJSON("#{poll_state}?verificationId="+verificationId, function(d){
              netid = verified(d)
              if(netid) location = '#{loginURL}'+'?netid='+netid
              f1 = f2
              f2 = sec
              var fn = f1 + f2
              console.log("document.hidden "+document.hidden)
              if (!document.hidden && fn<86400) poll(fn)
            })
          },sec*1000)
        }
        poll(v3)
      }
      document.addEventListener('visibilitychange', function() {if (!document.hidden) poll_setup(0,1,1)}, false)
      document.addEventListener('mouseover', function() {poll_setup(0,1,1)}, false)
      poll_setup(2,3,5)
    }
  })
});
</script>
>>
      html:header("HR OIT Login",scripts)
      + <<<h1>HR OIT: Personnel -- Login</h1>
<h2>Login with credential</h2>
<div id="d2">
<span id="generating">Generating code...</span>
<div id="qrcode">
</div>
<br clear="all">
Scan with digital wallet to login
(checking in <span id="sec">a few</span> seconds)
</div>
>>
      + html:footer()
    }
    authz = function(netid){ //defaction(netid) left-curly-brace
//    request = {"request":{"subject":netid,"client":"HR OIT"}}
//    response = http:post("",json=request)
      return admins >< netid  => "ADMIN" | "VIEW"
    }
    listURL = function(netid,position){
      adminECI = wrangler:channels("byu-hr-oit").head().get("id")
      adminURL = <<#{meta:host}/c/#{adminECI}/query/byu.hr.oit/index.html>>
      viewECI = wrangler:channels("byu-hr-oit,read-only").head().get("id")
      viewURL =  <<#{meta:host}/c/#{viewECI}/query/byu.hr.oit/index.html>>
      answer = authz(netid)
      fragment = position => "#" + position
                           | "#" + netid
      answer == "ADMIN" => adminURL+fragment | viewURL+fragment
    }
  }
  rule setCookie {
    select when byu_hr_login needed
      netid re#(.+)# setting(netid)
    pre {
      referer = event:attrs{["_headers","referer"]}
      prefix = meta:host + "/c/" + meta:eci + "/query/" + meta:rid + "/"
      pages = "(credential|password).html"
      expected_re = (prefix + pages).replace(re#[.]#g,"[.]").as("RegExp")
    }
    if referer && referer.match(expected_re) then 
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
      loginPageURL = <<#{meta:host}/c/#{ent:eci}/query/#{meta:rid}/index.html>>
    }
    every {
      send_directive("_cookie",{"cookie": <<netid=; Path=/c; Max-Age:-1>>})
      send_directive("_redirect",{"url":loginPageURL})
    }
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    wrangler:createChannel(
      [meta:rid],
      {"allow":[{"domain":"byu_hr_login","name":"*"}],"deny":[]},
      {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
    ) setting(channel)
    fired {
      ent:eci := channel.get("id")
    }
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
