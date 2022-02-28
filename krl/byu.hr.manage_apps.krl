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
          { "name":"manage.html", "status":"active", "rid":meta:rid})
        .put("byu.hr.record",
          { "name":"record.html", "status":"built-in", "rid":"byu.hr.record"})
    }
    display_app = function(app){
      rid = app.get("rid")
      url = ruleset(rid).get("url")
      link_to_delete = "del "+rid
      <<<tr>
<td>#{app.get("status")}</td>
<td>#{app.get("rid")}</td>
<td>#{app.get("name")}</td>
<td>#{url}</td>
<td>#{built_ins().keys() >< rid => "N/A" | link_to_delete}</td>
</tr>
>>
    }
    display_apps = function(){
      <<<table>
<tr>
<th>Status</th>
<th>Ruleset ID</th>
<th>Home page</th>
<th>Ruleset URI</th>
<th>Delete</th>
</tr>
#{ent:apps.values().map(display_app).join("")}
<tr>
<td colspan="3">Add an app by URL:</td>
<td colspan="2">
<form method="POST">
<input type="text" name="app_url" placeholder="app URL">
<button type="submit" onclick="alert(this.form.app_url.value);return false">Add</button>
</form>
</td>
</tr>
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
table input {
  width: 90%;
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
