ruleset byu.hr.manage_apps {
  meta {
    use module html.byu alias html
    use module io.picolabs.wrangler alias wrangler
    shares manage
  }
  global {
    logout = function(_headers){
      ctx:query(
        wrangler:parent_eci(),
        "byu.hr.oit",
        "logout",
        {"_headers":_headers}
      )
    }
    manage = function(_headers){
      url = logout(_headers).extract(re#location='([^']*)'#).head()
      html:header("manage apps","",url,_headers)
      + <<
<h1>Manage apps</h1>
>>
      + html:footer()
    }
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    every {
      wrangler:createChannel(
        ["manage_apps"],
        {"allow":[{"domain":"byu_hr_manage_apps","name":"*"}],"deny":[]},
        {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
      )
    }
  }
}
