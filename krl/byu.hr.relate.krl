ruleset byu.hr.relate {
  meta {
    name "relationships"
    use module io.picolabs.subscription alias subs
    use module io.picolabs.wrangler alias wrangler
    use module html.byu alias html
    shares relate
  }
  global {
    render = function(list,type,canDelete=true,canAccept=false){
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
          type == "inbd" => <<<a href="#{meta:host}/sky/event/#{Rx}/reject-inbound/wrangler/inbound_rejection?Id=#{rel.get("Id")}">deny</a> >> |
                            <<<a href="" onclick="alert('not yet available');return false">delete</a> >>
        <<<li><span style="display:none">#{rel.encode()}</span>
#{displayName(Rx).capitalize()} as #{rel.get("Rx_role")} and
#{displayName(rel.get("Tx"))} as #{rel.get("Tx_role")}
#{canAccept => <<<a href="#{meta:host}/sky/event/#{Rx}/accept-inbound/wrangler/pending_subscription_approval?Id=#{rel.get("Id")}">accept</a> >> | ""}
#{canDelete => del_link.klog("del_link") | ""}
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
      url = meta:host.extract(re#(.+):\d+#).head()
      html:header("manage relationships","",url,null,_headers)
      + <<<h1>Manage relationships</h1>
>>
      + <<<h2>Relationships that are fully established</h2>
>>
      + render(subs:established(),"estb")
      + <<<h2>Relationships that you have proposed</h2>
>>
      + render(subs:outbound(),"outb")
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
             or wrangler subscription_removed
             or wrangler outbound_subscription_cancelled
             or wrangler subscription_added
             or wrangler inbound_subscription_cancelled
    pre {
      referer = event:attr("_headers").get("referer")
      added_arg = "subs_id="+event:attr("Id")
      arg_intro = referer.match(re#[?]#) => "&" | "?"
      url = referer + arg_intro + added_arg
    }
    if url then send_directive("_redirect",{"url":url})
  }
}
