ruleset io.picolabs.pds {
  meta {
    name "Pico Data Store"
    description <<
      Inter-ruleset storage of state
      since one ruleset cannot access the state of another
    >>
    use module io.picolabs.wrangler alias wrangler
    provides getData
    shares getData
  }
  global {
    getData = function(domain,key){
      key => ent:pds{[domain,key]} | ent:pds{domain}
    }
    tags = ["pds","__testing"]
    eventPolicy = {"allow":[{"domain":"pds","name":"*"}],"deny":[]}
    queryPolicy = {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
    __testing = __testing
      .put("events",__testing.get("events").filter(function(e){
        e.get("domain")=="pds"}))
  }
  rule setData {
    select when pds new_data_available
      domain re#(.+)#
      key re#(.+)#
      value re#(.*)#
      setting(domain,key,value)
    fired {
      ent:pds{[domain,key]} := value
      clear ent:pds{[domain,key]} if value.isnull()
      raise pds event "data_added" attributes event:attrs
    }
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    if ent:pds.isnull() then
      wrangler:createChannel(tags,eventPolicy,queryPolicy)
    fired {
      ent:pds := {}
    }
  }
}
