ruleset byu.hr.core {
  meta {
    name "Personal Information - Public"
    description <<
      Core personal information of the organization's employees available for all organizational users to see.
    >>
    use module io.picolabs.pds alias pds
    use module html.byu alias html
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.subscription alias subs
    shares index, child_desig, record_audio_eci, adminECI, audioURL
      , displayName
  }
  global {
    ridAsTag = meta:rid.replace(re#[.]#g,"-")
    tags = [ridAsTag]
    tagsRO = [ridAsTag,"read-only"]
    event_types = [
      "tsv_import_available",
      "json_import_available",
      "new_field_value",
      "manage_relationships_needed",
    ]
    eventPolicy = {
      "allow": event_types.map(function(et){
        {"domain":"byu_hr_core"}.put("name",et)
      }),
      "deny": []
    }
    queryPolicy = {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
    eventPolicyRO = {
      "allow":[{"domain":"byu_hr_core","name":"new_relationship"}],
      "deny": []
    }
    queryPolicyRO = {
      "allow":[{"rid":meta:rid,"name":"index"},
               {"rid":meta:rid,"name":"audioURL"}],"deny":[]
    }
    __testing = {
      "events":__testing.get("events").filter(function(e){
        e.get("domain")=="byu_hr_core" && event_types >< e.get("name")
      }),
      "queries":__testing.get("queries").filter(function(q){
        q.get("name").match(re#^get#)
      })
    }
    element_names = [
      "Full Name (Last, First)",
      "First Name",
      "Last Name",
      "Preferred Name",
      "Department Name",
      "College/Division Name",
      "Work Address",
      "Work Email",
      "Supervisor Name",
      "Org Chart Supervisor",
      "F/T-P/T Status",
    ]
    element_descriptions = [
      "This is the employee's official name on record.",
      "This is the employee's official first name on record.",
      "This is the employee's official last name on record.",
      "This is the employee's preferred name on record.",
      "This is the descriptive department name  that is associated with the department ID.",
      "This is the descriptive college/division name  that is associated with the department ID.",
      "This is the campus address defined in the HR system.",
      "This is the official @byu.edu email address that is tied to the Net ID.",
      "This will populate with either the supervisor name or the reports to name from Job data",
      "This will populate from position management data for those employees who have a position assigned to them.",
      "This identifies full-time, 3/4 part-time, and 1/2 part-time status of the employee.",
    ]
    displayName = function(){
      pname = pds:getData("person","Preferred Name")
      fname = pds:getData("person","First Name")
      lname = pds:getData("person","Last Name")
      return (pname || fname) + " " + lname
    }
    getData = function(){
      [element_names,element_descriptions].pairwise(function(name,desc){
        name + " is " + pds:getData("person",name) + " (" + desc + ")"})
    }
    getTSV = function(){
      [element_names,element_descriptions].pairwise(function(name,desc){
        name + 9.chr() + pds:getData("person",name)
      }).join(10.chr())
    }
    getOneTSV = function(){
      wrangler:name()+9.chr()+
      [element_names,element_descriptions].pairwise(function(name,desc){
        pds:getData("person",name)
      }).join(9.chr())
    }
    getJSON = function(){
      element_names.map(function(name){
        {}.put(name,pds:getData("person",name))
      }).reduce(function(a,m){a.put(m)},{})
    }
    getECI = function(){
      wrangler:channels("byu-hr-core,read-only")
        .reverse() // most recently created channel
        .head()
        .get("id")
    }
    nl = (13.chr() + "?" + 10.chr()).as("RegExp")
    importTSV = function(content){
      content
        .split(nl)
        .reduce(function(a,l){
          i = l.split(9.chr())
          a.put(i.head(),i[1])
        },{})
    }
    styles = 
      <<    <style type="text/css">
      div#exports pre {
        white-space: pre-wrap;
        user-select: all;
      }
      div#exports {
        display:none;
      }
      input[type="checkbox"] {
        margin-top:16px;
      }
      input[type="checkbox"]:checked ~ div#exports {
        display:block;
      }
      a.button {
        display: inline-block;
        margin: 5px 0;
        border: 1px solid gray;
        text-decoration: none;
        border-radius: 15px;
        padding: 10px;
        color: black;
      }
    </style>
>>
    scripts = function(){
<<    <script type="text/javascript">
      var updURL = "#{meta:host}/c/#{meta:eci}/event/byu_hr_core/new_field_value?";
      function cache_it(ev){
        var e = ev || window.event;
        var thespan = e.target.textContent;
        var thename = e.target.previousElementSibling.textContent;
        sessionStorage.setItem(thename,thespan);
        window.getSelection().selectAllChildren(e.target);
      }
      function munge(ev) {
        var e = ev || window.event;
        var keyCode = e.code || e.keyCode;
        if(keyCode==27 || keyCode==="Escape"){
          var thename = e.target.previousElementSibling.textContent;
          e.target.textContent = sessionStorage.getItem(thename);
          window.getSelection().selectAllChildren(e.target);
        }else if(keyCode==13 || keyCode==="Enter"
            || keyCode==9 || keyCode==="Tab"){
          e.target.blur();
          return false;
        }
      }
      function save_it(ev){
        var e = ev || window.event;
        var thespan = e.target.textContent;
        var thename = e.target.previousElementSibling.textContent;
        var oldspan = sessionStorage.getItem(thename);
        if(oldspan && oldspan !== thespan){
          var httpReq = new XMLHttpRequest();
          httpReq.open("GET",updURL+"name="+thename+"&value="+thespan);
          httpReq.send();
        }
      }
    </script>
>>
    }
    scripts_ro = function(){
<<    <script type="text/javascript">
      function claim_pico(full_name,claimURL,redirectURL){
        if(confirm("You are claiming that your full name is "+full_name+".")){
          var httpReq = new XMLHttpRequest();
          httpReq.onload = function(){location = redirectURL;}
          httpReq.onerror = function(){alert(httpReq.responseText);}
          httpReq.open("GET",claimURL,true);
          httpReq.send();
          alert("This will take just a moment.");
        }
      }
    </script>
>>
    }
    table_row = function(string,read_only){
      cell_attrs = [
        "","contenteditable",
        <<onfocus="cache_it(event)">>,
        <<onkeydown="munge(event)">>,
        <<onblur="save_it(event)">>,
      ]
      cells = string.split(" is ")
      name = cells.head()
      value_desc = cells.tail().join(" is ").extract(re#(.*) \((This .*)\)$#)
      value = value_desc.head()
      desc = value_desc.tail().join("")
      onclick = read_only => ""
                           | << onclick="this.nextElementSibling.focus()">>
      <<<td title="#{desc}"#{onclick}>#{name}</td>
<td#{read_only => "" | cell_attrs.join(" ")}>#{value}</td>
>>
    }
    entry = function(string,read_only){
      <<<tr>
#{string.table_row(read_only)}</tr>
>>
    }
    exports = function(){
      <<<input type="checkbox"> show export formats
<div id="exports">
<p>JSON</p>
<pre>#{getJSON().encode()}</pre>
<p>TSV (string)</p>
<pre>#{getOneTSV()}</pre>
<p>TSV (file)</p>
<pre>#{getTSV()}</pre>
</div>
>>
    }
    relateRID = "byu.hr.relate"
    relateAppURL = meta:rulesetURI.replace(re#core.krl$#,"relate.krl")
    getSubsECI = function(_headers){
      hcs = html:cookies(_headers)
      hcs.get("apps").split(",") >< relateRID
         => hcs.get("wellKnown_Rx") | null
    }
    canManageApps = function(){
      wrangler:installedRIDs() >< "byu.hr.manage_apps"
    }
    manage_eci = function(){
      wrangler:channels("manage_apps")
        .reverse()
        .head()
        .get("id")
    }
    record_audio_eci = function(){
      wrangler:channels("record_audio")
        .head()
        .get("id")
    }
    audio_widgets = function(netid,eci){
      record_audio_link = netid == wrangler:name()
        => <<<p>
<a class="button" href="#{meta:host}/c/#{eci}/query/byu.hr.record/audio.html">&#x1F3A4; Manage your audio</a>
</p>
>> | "<br>"
      audio = pds:getData("person","audio")
      play_audio_tag = audio => <<<audio controls src="#{audio}"></audio>
>> | ""
      record_audio_link + 10.chr() + play_audio_tag + "<br>" + 10.chr()
    }
    linkToList = function(netid,position){
      list_subs = subs:established("Tx_role","participant list")
        .head() // default to earliest created
      list_eci = list_subs => list_subs{"Tx"} | wrangler:parent_eci()
      ctx:query(
        list_eci,
        "byu.hr.login",
        "listURL",
        {"netid":netid,"position":position}
      )
    }
    relateURL = function(){
      relateECI = wrangler:channels("relationships").head().get("id")
      <<#{meta:host}/c/#{relateECI}/query/#{relateRID}/relate.html>>
    }
    maRID = "byu.hr.manage_apps"
    index = function(_headers,personExists){
      ack = function(){
        installEVENT = "byu_hr_core/manage_relationships_needed"
        installURL = <<#{meta:host}/sky/event/#{meta:eci}/none/#{installEVENT}>>
        hasRelateRS = wrangler:installedRIDs() >< relateRID
        linkURL = hasRelateRS => relateURL() | installURL
        linkText = hasRelateRS => "Manage your relationships"
                                | "Install app to manage your relationships" 
        subs:inbound().map(function(s){
          eci = s.get("Tx")
          thisPico = ctx:channels.any(function(c){c{"id"}==eci})
          thisPico => "" | <<<p>
You have a request
from #{wrangler:picoQuery(eci,meta:rid,"displayName")}
to acknowledge a relationship as
#{s.get("Rx_role")} to
#{s.get("Tx_role")}, respectively.
</p>
>>
        }).join("")
        + <<<p>
<a class="button" href="#{linkURL}">#{linkText}</a>
</p>
>>
      }
      full_name = pds:getData("person",element_names.head())
      read_only = wrangler:channels()
        .filter(function(c){c.get("id")==meta:eci})
        .head()
        .get("tags") >< "read-only"
      netid = html:cookies(_headers).get("netid")
      unlisted = personExists == "false"
      this_person = wrangler:name()
      wellKnown_Rx = this_person == netid => null | getSubsECI(_headers)
      audio_eci = record_audio_eci()
      listURL = linkToList(netid,this_person)
      baseECI = listURL.extract(re#/c/([^/]+)/query/#).head()
      claimECI = wrangler:channels(["system","child"]).head().get("id")
      claimURL = meta:host+"/sky/event/"+baseECI+"/claim/byu_hr_oit/pico_claimed?eci="+claimECI+"&good_name="+netid
      redirectURL = listURL.replace((this_person+"$").as("RegExp"),netid)
      head_stuff = styles + (read_only => scripts_ro() | scripts())
      html:header("person",head_stuff,null,null,_headers)
      + <<<a class="button" href="#{listURL}">See list of names</a>
<table>
>>
      + getData().map(function(s){s.entry(read_only)}).join("")
+ "".klog("after getData")
      + <<</table>
>>
      + (audio_eci => audio_widgets(netid,audio_eci) | "")
+ "".klog("after audio_widgets")
      + (netid == this_person && not read_only => <<<p>
You may edit your information:
click, change, and press Enter key (or Esc to undo a change).
</p>
>> | "")
+ "".klog("after you may edit")
      + (netid == this_person && canManageApps() => <<<p>
<a class="button" href="#{meta:host}/c/#{manage_eci()}/query/byu.hr.manage_apps/manage.html">Manage your apps</a>
</p>
>> | "")
+ "".klog("after manage apps")
      + ((this_person.match(re#^n\d{5}$#) && unlisted) => <<<p>
<button onclick="claim_pico('#{full_name}','#{claimURL}','#{redirectURL}')">This is me!</button>
</p>
>> | "")
+ "".klog("after this is me")
      + ((netid != this_person && wellKnown_Rx) => <<<div>
<form action="#{meta:host}/sky/event/#{meta:eci}/none/byu_hr_core/new_relationship">
<input type="hidden" name="wellKnown_Tx" value="#{subs:wellKnown_Rx().get("id")}">
<input type="hidden" name="wellKnown_Rx" value="#{wellKnown_Rx}">
Propose a relationship with #{displayName()}:<br>
Your role: <input name="Rx_role"> (e.x. team member)<br>
Their role: <input name="Tx_role"> (e.x. virtual team lead)<br>
<input type="hidden" name="name" value="#{netid}-#{this_person}">
<input type="hidden" name="channel_type" value="relationship">
<button type="submit">Submit</button>
</form>
</div>
>> | "")
+ "".klog("after form")
      + (netid == this_person && subs:inbound().length() => ack() | "")
+ "".klog("after acknowledge")
      + exports()
+ "".klog("after exports")
      + html:footer()
    }
    adminECI = function(){
      wrangler:channels("byu-hr-core")
        .reverse() // most recently created channel
        .head()
        .get("id")
    }
    skey_names = [
      "Last Name",
      "Work Email",
      "F/T-P/T Status",
    ]
    getKey = function(){
      stuff = skey_names.map(function(n){
        pds:getData("person",n)
      }).join(":")
      math:hash("sha256",stuff)
        .substr(0,9)
    }
    child_desig = function(name){
      full_name = pds:getData("person",element_names.head())
      skey = getKey()
      the_eci = getECI() // read-only ECI
      has_audio = pds:getData("person","audio").encode()
      return
      [full_name,name,the_eci,skey,has_audio].join("|")
    }
    audioURL = function(){
      pds:getData("person","audio") || ""
    }
  }
  rule importTSV {
    select when byu_hr_core tsv_import_available
      content re#(.+)# setting(content)
    foreach importTSV(event:attr("content")) setting(value,name)
    if name.typeof("String") && value then noop()
    fired {
      raise pds event "new_data_available" attributes {
        "domain":"person","key":name,"value":value
      }
    }
  }
  rule importJSON {
    select when byu_hr_core json_import_available
    pre {
      json = event:attr("json").decode()
    }
    if json.typeof(json) == "Map" then noop()
    fired {
      raise byu_hr_core event "internal_import"
        attributes {"json":json}
    }
  }
  rule do_import {
    select when byu_hr_core internal_import
    foreach event:attr("json") setting(value,name)
    if name.typeof("String") && value then noop()
    fired {
      raise pds event "new_data_available" attributes {
        "domain":"person","key":name,"value":value
      }
    }
  }
  rule updateField {
    select when byu_hr_core new_field_value
      where element_names >< event:attr("name")
    pre {
      name = event:attr("name")
      valueString = event:attr("value").html:defendHTML()
      value = valueString == "null" => null | valueString
      full_name_changed = name == element_names.head()
    }
    fired {
      raise pds event "new_data_available" attributes {
        "domain":"person",
        "key":name,
        "value":value
      }
      raise byu_hr_core event "child_designation_changed"
        if full_name_changed || skey_names >< name
    }
  }
  rule childDesigChanged {
    select when byu_hr_core child_designation_changed
    pre {
      netid = wrangler:name()
      list_subs = subs:established("Tx_role","participant list")
      getkey = function(key){function(s){s{key}}}
      list_ecis = list_subs => list_subs.map(getkey("Tx"))
                            | [wrangler:parent_eci()]
    }
    if list_ecis.length() then noop()
    fired {
      raise byu_hr_core event "cdc_notification_needed" attributes {
        "netid":netid, "list_ecis":list_ecis,
      }
    }
  }
  rule notifyChildDesigChanged {
    select when byu_hr_core cdc_notification_needed
      netid re#^(.+)$# setting(netid)
    foreach event:attr("list_ecis") setting(notify_eci)
    event:send({"eci":notify_eci,"eid":"child_desig_changed",
      "domain":"byu_hr_oit", "type":"new_child_designation",
      "attrs":{"netid":netid,"child_desig":child_desig(netid)}
    })
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    every {
      wrangler:createChannel(tags,eventPolicy,queryPolicy)
      wrangler:createChannel(tagsRO,eventPolicyRO,queryPolicyRO)
    }
    fired {
      raise byu_hr_core event "channel_created"
      raise byu_hr_core event "readonly_channel_created"
    }
  }
  rule keepChannelsClean {
    select when byu_hr_core channel_created
    foreach wrangler:channels(tags).reverse().tail() setting(chan)
    wrangler:deleteChannel(chan.get("id"))
  }
  rule keepReadOnlyChannelsClean {
    select when byu_hr_core readonly_channel_created
    foreach wrangler:channels(tagsRO).reverse().tail() setting(chan)
    wrangler:deleteChannel(chan.get("id"))
  }
  rule installManageAppsRuleset {
    select when byu_hr_core manage_relationships_needed
    fired {
      raise wrangler event "install_ruleset_request"
        attributes event:attrs.put({
          "absoluteURL":meta:rulesetURI,"rid":maRID,"tx":meta:txnId})
    }
  }
  rule installRelateRuleset {
    select when wrangler ruleset_installed where event:attr("rids") >< maRID
      && event:attr("tx") == meta:txnId
    fired {
      raise byu_hr_manage_apps event "new_app" attributes event:attrs.put({
        "url":relateAppURL})
    }
  }
  rule proposeNewRelationship {
    select when byu_hr_core new_relationship
      Rx_role re#(.+)# Tx_role re#(.+)# setting(Rx_role,Tx_role)
    pre {
      referer = event:attr("_headers").get("referer")
    }
    every {
      event:send({"eci":event:attrs{"wellKnown_Rx"},
        "domain":"wrangler","type":"subscription",
        "attrs": event:attrs
          .put("Rx_role",Rx_role.html:defendHTML())
          .put("Tx_role",Tx_role.html:defendHTML())
      })
      send_directive("_redirect",{"url":referer})
    }
  }
}
