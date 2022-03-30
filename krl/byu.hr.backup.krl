ruleset byu.hr.backup {
  meta {
    use module io.picolabs.wrangler alias wrangler
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
}
