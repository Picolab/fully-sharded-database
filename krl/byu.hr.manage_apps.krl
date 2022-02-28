ruleset byu.hr.manage_apps {
  meta {
    use module html.byu alias html
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.pds alias pds
    shares manage, apps, app, ruleset
  }
  global {
    ruleset = function(rid){
      ctx:rulesets.filter(function(rs){rs{"rid"}==rid}).head()
    }
    apps = function(){
      ent:apps.keys()
    }
    app = function(key){
      ent:apps.get(key)
    }
    logout = function(_headers){
      ctx:query(
        wrangler:parent_eci(),
        "byu.hr.oit",
        "logout",
        {"_headers":_headers}
      )
    }
    built_ins = function(){
      {}
        .put("byu.hr.manage_apps",
          { "name":"manage apps", "status":"active", "rid":meta:rid})
        .put("byu.hr.record",
          { "name":"record audio", "status":"built-in", "rid":"byu.hr.record"})
    }
    display_app = function(app){
      <<<tr>
<td>#{app.get("name")}</td>
<td>#{app.get("status")}</td>
<td>#{app.get("rid")}</td>
</tr>
>>
    }
    display_apps = function(){
      <<<table>
<tr>
<th>Name</th>
<th>Status</th>
<th>Ruleset</th>
</tr>
#{ent:apps.values().map(display_app).join("")}
</table>
>>
    }
    styles = <<<style type="text/css">
table {
  border: 1px solid black;
  border-collapse: collapse;
}
td, th {
  border: 1px solid black;
  padding: 5px;
}
</style>
>>
    manage = function(_headers){
      url = logout(_headers).extract(re#location='([^']*)'#).head()
      html:header("manage apps",styles,url,null,_headers)
      + <<
<h1>Manage apps</h1>
>>
      + display_apps()
      + html:footer()
    }
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    every {
      wrangler:createChannel(
        ["manage_apps"],
        {"allow":[{"domain":"byu_hr_manage_apps","name":"*"}],"deny":[]},
        {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
      )
    }
    fired {
      raise byu_hr_manage_apps event "factory_reset"
    }
  }
  rule resetApps {
    select when byu_hr_manage_apps factory_reset
    fired {
      ent:apps := built_ins()
    }
  }
}
