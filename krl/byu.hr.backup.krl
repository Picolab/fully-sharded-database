ruleset byu.hr.backup {
  meta {
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.subscription alias subs
    shares preparation, names
  }
  global {
    tags = [meta:rid.replace(re#[.]#g,"-")]
    eventPolicy = {
      "allow":[{"domain":meta:rid.replace(re#[.]#g,"_"),"name":"*"}],
      "deny":[]
    }
    queryPolicy = {
      "allow":[{"rid":meta:rid,"name":"*"}],
      "deny":[]
    }
    isSurrogate = function(n){
      n.match(re#^n\d{5}$#)
    }
    preparation = function(){
      wrangler:children().length()
    }
    names = function(){
      wrangler:children()
        .map(function(c){c{"name"}})
        .filter(function(n){not n.isSurrogate()})
    }
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    wrangler:createChannel(tags,eventPolicy,queryPolicy)
    fired {
      raise byu_hr_backup event "channel_created" attributes {
        "old_channels":wrangler:channels(tags).reverse().tail()
      }
    }
  }
  rule cleanupChannels {
    select when byu_hr_backup channel_created
    foreach event:attr("old_channels") setting(chan)
    wrangler:deleteChannel(chan.get("id"))
  }
  rule proposeSubscriptions {
    select when byu_hr_backup subscriptions_needed
    foreach
      wrangler:children().filter(function(c){not c{"name"}.isSurrogate()})
      setting(participant)
    send_directive("participant",participant)
    fired {
      raise wrangler event "subscription" attributes {
        "wellKnown_Tx": participant{"eci"},
        "Rx_role": "participant list",
        "Tx_role": "participant",
        "name": participant{"name"},
        "channel_type": "participant",
      }
    }
  }
}
