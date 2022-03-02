ruleset byu.hr.relate {
  meta {
    name "relationships"
    use module io.picolabs.subscription alias subs
    use module io.picolabs.wrangler alias wrangler
    use module html.byu alias html
    shares relate
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
    render = function(list,canDelete=false,canAccept=false){
      list.encode()
      + canDelete
      + canAccept
    }
    relate = function(_headers){
      url = logout(_headers).extract(re#location='([^']*)'#).head()
      html:header("manage relationships","",url,null,_headers)
      + <<<h1>Manage relationships</h1>
>>
      + <<<h2>Relationships that are fully established</h2>
>>
      + render(subs:established(),canDelete=true)
      + <<<h2>Relationships that you have proposed</h2>
>>
      + render(subs:outbound(),canDelete=true)
      + <<<h2>Relationships that others have proposed</h2>
>>
      + render(subs:inbound(),canAccept=true)
      + html:footer()
    }
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    every {
      wrangler:createChannel(
        ["relationships"],
        {"allow":[{"domain":"byu_hr_relate","name":"*"}],"deny":[]},
        {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
      )
    }
    fired {
      raise byu_hr_relate event "factory_reset"
    }
  }
  rule redirectBack {
    select when wrangler outbound_pending_subscription_added
    pre {
      url = event:attr("_headers").get("referer")
      id = event:attr("Id")
      name = event:attr("channel_name")
    }
    if url then send_directive("_redirect",{"url":url+"&subs_id="+id})
  }
}
