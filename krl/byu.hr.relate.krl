ruleset byu.hr.relate {
  meta {
    name "relationships"
    use module io.picolabs.subscription alias subs
    use module io.picolabs.wrangler alias wrangler
    use module html.byu alias html
    shares relate, otherNameCache
    provides otherName
  }
  global {
    otherNameCache = function(){
      ent:otherNameCache
    }
    otherName = function(id){
      ent:otherNameCache{id}
    }
    coreRID = "byu.hr.core"
    wranglerRID = "io.picolabs.wrangler"
    render = function(list,type,canDelete=true,canAccept=false){
      renderRel = function(rel){
        Rx = rel.get("Rx")
        myNetid = wrangler:name()
        hideBookkeepingRel = rel.get("Rx_role") == "participant"
          && rel.get("Tx_role") == "participant list"
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
        otherDisplayName = function(eci){
          oRIDs = wrangler:picoQuery(eci,wranglerRID,"installedRIDs")
          isParticipant = oRIDs >< coreRID
          isParticipant => wrangler:picoQuery(eci,coreRID,"displayName")
                         | wrangler:picoQuery(eci,wranglerRID,"name")
        }
        displayName = function(eci){
          thisPico = ctx:channels.any(function(c){c{"id"}==eci})
          eci.isnull() => (Rx.isnull() =>"unknown" | findNetid()) |
          thisPico     => "you" | otherDisplayName(eci)
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
        hideBookkeepingRel => "" |
        <<<li><span style="display:none">#{rel.encode()}</span>
#{displayName(Rx).capitalize()} as #{rel.get("Rx_role")} and
#{displayName(rel.get("Tx"))} as #{rel.get("Tx_role")}
#{canAccept => <<<a href="#{meta:host}/sky/event/#{Rx}/accept-inbound/wrangler/pending_subscription_approval?Id=#{rel.get("Id")}">accept</a> >> | ""}
#{canDelete => del_link | ""}
</li>
>>
      }
      the_li = list.map(renderRel).join("")
      <<<ul>
>>
      + (the_li => the_li | "none")
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
/*
 * Notable events
 */
  rule initCache {
    select when byu_hr_relate cache_flush
    fired {
      ent:otherNameCache := {}
    }
  }
  rule cacheOtherName {
    select when byu_hr_relate cache_flush
    foreach subs:established() setting(rel)
    pre {
      otherDisplayName = function(eci){
        oRIDs = wrangler:picoQuery(eci,wranglerRID,"installedRIDs")
        isParticipant = oRIDs >< coreRID
        isParticipant => wrangler:picoQuery(eci,coreRID,"displayName")
                       | wrangler:picoQuery(eci,wranglerRID,"name")
      }
      eci = rel{"Tx"}
      thisPico = ctx:channels.any(function(c){c{"id"}==eci})
      name = thisPico => "you" | otherDisplayName(eci)
    }
    if rel{"Rx_role"} != "participant" then noop()
    fired {
      ent:otherNameCache{rel{"Id"}} := name
    }
  }
  rule theyDenyMyProposal {
    select when wrangler outbound_subscription_cancelled
    fired {
      raise byname_notification event "status" attributes {
        "application":meta:rid,
        "subject":"your proposal was declined",
        "description":event:attrs.delete("_headers").encode(),
      }
    }
  }
  rule theyAcceptMyProposal {
    select when wrangler outbound_pending_subscription_approved
    fired {
      raise byname_notification event "status" attributes {
        "application":meta:rid,
        "subject":"your proposal was accepted",
        "description":event:attrs.delete("_headers").encode(),
      }
    }
  }
  rule theyDeleteEstablished {
    select when wrangler subscription_removed
    fired {
      raise byname_notification event "status" attributes {
        "application":meta:rid,
        "subject":"a relationship was deleted",
        "description":event:attrs.delete("_headers").encode(),
      }
    }
  }
  rule theyPropose {
    select when wrangler inbound_pending_subscription_added
    fired {
      raise byname_notification event "status" attributes {
        "application":meta:rid,
        "subject":"you have received a relationship proposal",
        "description":event:attrs.delete("_headers").encode(),
      }
    }
  }
  rule theyDeleteProposal {
    select when wrangler inbound_subscription_cancelled
    fired {
      raise byname_notification event "status" attributes {
        "application":meta:rid,
        "subject":"a proposed relationship was cancelled",
        "description":event:attrs.delete("_headers").encode(),
      }
    }
  }
}
