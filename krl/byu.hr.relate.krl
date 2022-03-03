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
    render = function(list,type,canDelete=false,canAccept=false){
      renderRel = function(rel){
        Rx = rel.get("Rx")
        myNetid = wrangler:name()
        findNetid = function(){
          wrangler:channels()
            .filter(function(c){c.get("id")==Rx})
            .head()
            .get("tags")
            .filter(function(t){t!="relationship"})
            .head()
            .split("-")
            .filter(function(n){n!=myNetid})
            .head()
        }
        displayName = function(eci){
          thisPico = ctx:channels.any(function(c){c{"id"}==eci})
          eci.isnull() => (Rx.isnull() =>"unknown" | findNetid()) |
          thisPico     => "you" |
                          wrangler:picoQuery(eci,"byu.hr.core","displayName")
        }
        del_link =
          type == "outb" => <<<a href="#{meta:host}/sky/event/#{Rx}/cancel-outbound/wrangler/outbound_cancellation?Id=#{rel.get("Id")}">delete</a> >> |
          type == "estb" => <<<a href="#{meta:host}/sky/event/#{Rx}/delete-subscription/wrangler/subscription_cancellation?Id=#{rel.get("Id")}">delete</a> >> |
                            <<<a href="" onclick="alert('not yet available');return false">delete</a> >>
        <<<li><span style="display:none">#{rel.encode()}</span>
#{displayName(Rx).capitalize()} as #{rel.get("Rx_role")} and
#{displayName(rel.get("Tx"))} as #{rel.get("Tx_role")}
#{canDelete => del_link.klog("del_link") | ""}
#{canAccept => <<<a href="" onclick="alert('not yet available');return false">accept</a> >> | ""}
</li>
>>
      }
      <<<ul>
>>
      + (list.length() => list.map(renderRel).join("") | "none")
      + <<</ul>
>>
    }
    relate = function(_headers){
      url = logout(_headers).extract(re#location='([^']*)'#).head()
      html:header("manage relationships","",url,null,_headers)
      + <<<h1>Manage relationships</h1>
>>
      + <<<h2>Relationships that are fully established</h2>
>>
      + render(subs:established(),"estb",canDelete=true)
      + <<<h2>Relationships that you have proposed</h2>
>>
      + render(subs:outbound(),"outb",canDelete=true)
      + <<<h2>Relationships that others have proposed</h2>
>>
      + render(subs:inbound(),"inbd",canAccept=true)
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
             or wrangler outbound_subscription_cancelled
    pre {
      referer = event:attr("_headers").get("referer")
      added_arg = "subs_id="+event:attr("Id")
      arg_intro = referer.match(re#[?]#) => "&" | "?"
      url = referer + arg_intro + added_arg
    }
    if url then send_directive("_redirect",{"url":url})
  }
}
