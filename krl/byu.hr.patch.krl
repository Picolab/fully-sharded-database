ruleset byu.hr.patch {
  meta {
    name "Patches for child picos"
    use module io.picolabs.wrangler alias wrangler
  }
  global {
    core_rids = [
//      "html.byu",
//      "byu.hr.core",
//      "byu.hr.record",
        "byu.hr.acceptance",
    ]
  }
  rule doPatch {
    select when patch rulesets_needed
    foreach wrangler:children() setting(c)
    fired {
      raise patch event "install_rulesets" attributes c
    }
  }
  rule installRulesets {
    select when patch install_rulesets
    foreach core_rids setting(rid)
    pre {
      eci = event:attr("eci")
      name = event:attr("name")
      good_name = name.split("").tail().join("")
    }
    event:send({"eci":eci,"eid":"install-ruleset",
      "domain":"wrangler", "type":"install_ruleset_request",
      "attrs":{"absoluteURL":meta:rulesetURI,"rid":rid}
    })
  }
}
