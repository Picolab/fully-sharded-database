ruleset byu.hr.backup {
  meta {
    use module io.picolabs.wrangler alias wrangler
  }
  global {
    tags = [meta:rid.replace(re#[.]#,"-")]
    eventPolicy = {
      "allow":[{"domain":meta:rid.replace(re#[.]#,"_"),"name":"*"}],
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
      raise byu_hr_backup event "channel_created"
    }
  }
  rule cleanupChannels {
    select when byu_hr_backup channel_created
    foreach wrangler:channels(tags).reverse().tail() setting(chan)
    wrangler:deleteChannel(chan.get("id"))
  }
}
