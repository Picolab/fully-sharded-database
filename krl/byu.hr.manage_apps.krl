ruleset byu.hr.manage_apps {
  meta {
    name "apps"
    use module html.byu alias html
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.pds alias pds
    shares manage, apps, app
  }
  global {
    event_domain = meta:rid.replace(re#[.-]#g,"_")
    ruleset = function(rid){
      ctx:rulesets.filter(function(rs){rs{"rid"}==rid}).head()
    }
    apps = function(){
      ent:apps.keys()
    }
    app = function(key){
      ent:apps.get(key)
    }
    built_ins = function(){
      {}
        .put(meta:rid,
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
      rsname = app.get("rsname")
      rid = app.get("rid")
      url = ruleset(rid).get("url")
      link_to_delete = <<<a href="#{meta:host}/sky/event/#{meta:eci}/none/#{event_domain}/app_unwanted?rid=#{rid}" onclick="return confirm('This cannot be undone, and #{rsname} may be lost if you proceed.')">del</a> >>
      <<<tr>
<td>#{app.get("status")}</td>
<td>#{rid}</td>
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
<form method="POST" action="#{meta:host}/sky/event/#{meta:eci}/none/#{event_domain}/new_app">
<input class="wide90" type="text" name="url" placeholder="app URL">
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
input.wide90 {
  width: 90%;
}
</style>
>>
    manage = function(_headers){
      event_spec = <<#{event_domain}/module_needed>>
      installURL = <<#{meta:host}/sky/event/#{meta:eci}/none/#{event_spec}>>
      html:header("manage apps",styles,null,null,_headers)
      + <<
<h1>Manage apps</h1>
>>
      + display_apps()
      + <<
<h2>Technical</h2>
<p>If your app needs a module, install it here first:</p>
<form action="#{installURL}">
<input class="wide90" name="url" placeholder="module URL">
<br>
<input class="wide90" name="config" placeholder="{}">
<br>
<button type="submit">Install</button>
</form>
>>
      + html:footer()
    }
    app_rids = function(_headers){
      html:cookies(_headers){"apps"}.split(",")
    }
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    every {
      wrangler:createChannel(
        ["manage_apps"],
        {"allow":[{"domain":event_domain,"name":"*"}],"deny":[]},
        {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
      )
    }
    fired {
      raise byu_hr_manage_apps event "factory_reset"
      raise byu_hr_manage_apps event "channel_created"
    }
  }
  rule resetApps {
    select when byu_hr_manage_apps factory_reset
    if ent:apps.isnull() then noop()
    fired {
      ent:apps := built_ins()
    }
  }
  rule keepChannelsClean {
    select when byu_hr_manage_apps channel_created
    foreach wrangler:channels(["manage_apps"]).reverse().tail() setting(chan)
    wrangler:deleteChannel(chan.get("id"))
  }
  rule getModuleInstalled {
    select when byu_hr_manage_apps module_needed
      url re#(.+)#
      config re#(.*)#
      setting(url,config)
    fired {
      raise wrangler event "install_ruleset_request" attributes
        event:attrs.put("config",config.decode())
    }
  }
  rule installApp {
    select when byu_hr_manage_apps new_app
      url re#(.+)# setting(url)
    fired {
      raise wrangler event "install_ruleset_request"
        attributes event:attrs.put({"url":url,"tx":meta:txnId})
    }
  }
  rule makeInstalledRulesetAnApp {
    select when wrangler ruleset_installed where event:attr("tx") == meta:txnId
    foreach event:attr("rids") setting(rid)
    pre {
      omit_main = function(s){s != "main_url"}
      rsMeta = wrangler:rulesetMeta(rid)
      shared = rsMeta.get("shares").filter(omit_main)
      home = shared.head() + ".html"
      rsname = rsMeta.get("name")
      spec = {"name":home,"status":"installed","rid":rid,"rsname":rsname}
      new_apps = app_rids(event:attr("_headers"))
        .union([rid])
        .join(",")
    }
    if rid != meta:rid
      then send_directive("_cookie",{"cookie": <<apps=#{new_apps}; Path=/>>})
    fired {
      ent:apps{rid} := spec
      raise byu_hr_manage_apps event "app_installed" attributes event:attrs
    }
  }
  rule redirectBack {
    select when byu_hr_manage_apps app_installed
             or byu_hr_manage_apps app_deleted
    pre {
      referer = event:attr("_headers").get("referer")
    }
    if referer then send_directive("_redirect",{"url":referer})
  }
  rule deleteApp {
    select when byu_hr_manage_apps app_unwanted
      rid re#(.+)#
    fired {
      // delay one evaluation cycle
      raise explicit event "app_unwanted" attributes event:attrs
    }
  }
  rule actuallyDeleteApp {
    select when explicit app_unwanted
      rid re#(.+)# setting(rid)
    pre {
      permanent = built_ins().keys() >< rid
    }
    if not permanent then noop()
    fired {
      raise wrangler event "uninstall_ruleset_request" attributes event:attrs.put("tx",meta:txnId)
    }
  }
  rule updateApps {
    select when wrangler:ruleset_uninstalled where event:attr("tx") == meta:txnId
    pre {
      rid = event:attr("rid")
      new_apps = app_rids(event:attr("_headers"))
        .difference([rid])
        .join(",")
    }
    if rid
      then send_directive("_cookie",{"cookie": <<apps=#{new_apps}; Path=/>>})
    fired {
      clear ent:apps{rid}
      raise byu_hr_manage_apps event "app_deleted" attributes event:attrs
    }
  }
}
