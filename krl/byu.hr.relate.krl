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
huh = eci.klog("eci for displayName")
          thisPico = ctx:channels.any(function(c){c{"id"}==eci})
.klog("thisPico")
return_value =
          eci.isnull() => (Rx.isnull() =>"unknown" | findNetid()) |
          thisPico     => "you" |
                          wrangler:picoQuery(eci,"byu.hr.core","displayName")
return return_value.klog("return_value")
        }
        dmap = {
          "outb":{"eid":"cancel-outbound",
                  "type":"outbound_cancellation",
                  "text":"delete",
                  "msg":"that you have proposed"},
          "estb":{"eid":"delete-subscription",
                  "type":"subscription_cancellation",
                  "text":"delete",
                  "msg":"that you have established"},
          "inbd":{"eid":"reject-inbound",
                  "type":"inbound_rejection",
                  "text":"decline",
                  "msg":"that was proposed by another participant"},
        }
        del_link = <<<a href="#{
          meta:host}/sky/event/#{
          Rx}/#{
          dmap{[type,"eid"]}}/wrangler/#{
          dmap{[type,"type"]}}?Id=#{
          rel.get("Id")}" onclick="return confirm('If you proceed you will #{
          dmap{[type,"text"]}} this relationship #{
          dmap{[type,"msg"]}}. This cannot be undone.')">#{
          dmap{[type,"text"]}}</a> >>
        <<<li><span style="display:none">#{rel.encode()}</span>
#{displayName(Rx).capitalize()} as #{rel.get("Rx_role")} and
#{displayName(rel.get("Tx"))} as #{rel.get("Tx_role")}
#{canAccept => <<<a href="#{meta:host}/sky/event/#{Rx}/accept-inbound/wrangler/pending_subscription_approval?Id=#{rel.get("Id")}">accept</a> >> | ""}
#{canDelete => del_link | ""}
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
      html:header("manage relationships","",null,null,_headers)
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
      raise byu_hr_relate event "channel_created" attributes event:attrs
    }
  }
  rule keepChannelsClean {
    select when byu_hr_relate channel_created
    foreach wrangler:channels(["relationships"]).reverse().tail() setting(chan)
    wrangler:deleteChannel(chan.get("id"))
  }
  rule redirectBack {
    select when wrangler subscription_removed
             or wrangler outbound_subscription_cancelled
             or wrangler subscription_added
             or wrangler inbound_subscription_cancelled
    pre {
      referer = event:attr("_headers").get("referer")
    }
    if referer then send_directive("_redirect",{"url":referer})
  }
}
