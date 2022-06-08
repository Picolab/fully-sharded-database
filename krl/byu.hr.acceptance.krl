ruleset byu.hr.acceptance {
  meta {
    use module io.picolabs.subscription alias subs
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    pre {
      s = subs:inbound()
        .filter(function(i){i{"Rx_role"}=="participant" && i{"Tx_role"}=="participant list"}).head()
    }
    if s then noop()
    fired {
      raise wrangler event "pending_subscription_approval" attributes s
      raise wrangler event "uninstall_ruleset_request" attributes {"rid": meta:rid }
    }
  }
}
