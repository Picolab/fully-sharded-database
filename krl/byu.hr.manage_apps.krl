ruleset byu.hr.manage_apps {
  meta {
    use module html.byu alias html
    use module io.picolabs.wrangler alias wrangler
    shares manage
  }
  global {
    logout = function(_headers){
      ctx:query(
        wrangler:parent_eci(),
        "byu.hr.oit",
        "logout",
        {"_headers":_headers}
      )
    }
    built_ins = function(){
      { "byu.hr.record":
        { "name":"audio",
          "status":"built-in",
          "rid":"byu.hr.record",
        }
      }
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
<tr>Ruleset</th>
</tr>
#{ent:apps.map(display_app)}.join("")}
</table>
>>
    }
    manage = function(_headers){
      url = logout(_headers).extract(re#location='([^']*)'#).head()
      html:header("manage apps","",url,_headers)
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
      ent:apps := built_ins()
    }
  }
}
