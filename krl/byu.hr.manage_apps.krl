ruleset byu.hr.manage_apps {
  meta {
    name "apps"
    use module html.byu alias html
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.pds alias pds
    shares manage, apps, app
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
          { "name":"audio.html", "status":"built-in", "rid":"byu.hr.record"})
    }
    linkToAppHome = function(app){
      rid = app.get("rid")
      rsMeta = wrangler:rulesetMeta(rid)
      button_label = rsMeta.get("name")
      home = app.get("name")
      tags = rid == "byu.hr.record" => "record_audio" | button_label
      eci = wrangler:channels(tags).head().get("id") || null
      rid == meta:rid || eci.isnull() => home |
      <<<a href="#{meta:host}/c/#{eci}/query/#{rid}/#{home}">#{home}</a> >>
    }
    display_app = function(app){
      rid = app.get("rid")
      url = ruleset(rid).get("url")
      link_to_delete = "del "+rid
      <<<tr>
<td>#{app.get("status")}</td>
<td>#{app.get("rid")}</td>
<td>#{linkToAppHome(app)}</td>
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
<form method="POST" action="#{meta:host}/sky/event/#{meta:eci}/none/byu_hr_manage_apps/new_app">
<input type="text" name="app_url" placeholder="app URL">
<button type="submit">Add</button>
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
  rule installApp {
    select when byu_hr_manage_apps new_app
      url re#(.+)# setting(url)
    pre {
      url = event:attr("_headers").get("referer")
    }
    if url then send_directive("_redirect",{"url":url})
    fired {
      raise wrangler event "install_ruleset_request"
        attributes {"url":url,"tx":meta:txnId}
    }
  }
  rule makeInstalledRulesetAnApp {
    select when wrangler ruleset_installed where event:attr("tx") == meta:txnId
    foreach event:attr("rids") setting(rid)
    pre {
      rsMeta = wrangler:rulesetMeta(rid)
      home = rsMeta.get("shares").head() + ".html"
      spec = {"name":home,"status":"installed","rid":rid}
    }
    fired {
      ent:apps{rid} := spec
    }
  }
}
