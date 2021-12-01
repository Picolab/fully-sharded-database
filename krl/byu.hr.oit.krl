ruleset byu.hr.oit {
  meta {
    name "HR for IT Offices"
    use module io.picolabs.wrangler alias wrangler
    use module html.byu alias html
    shares index, logout
  }
  global {
    make_index = function(){
      main_field_name = element_names.head()
      child_desig = function(c){
        child_eci = c.get("eci") // family channel ECI
        ctx:query(child_eci,"byu.hr.core","child_desig",{
          "name":c.get("name")})+"|"+child_eci
      }
      wrangler:children()
        .filter(function(c){
          eci = c.get("eci") // family channel ECI
          omit_child = match(c.get("name"),re#^\*#)
          omit_child => false | true
        })
        .map(child_desig)
        .sort()
    }
    clean_index = function(name){
      ent:existing_index
        .filter(function(ie){ie.split("|")[1] != name})
    }
    existing = function(netid){
      the_list = ent:existing_index || make_index()
      the_list
        .map(function(cd){
          parts = cd.split("|")
          full_name = parts.head()
          person_id = parts[1]
          is_self = netid == person_id
          child_eci = parts[5]
          the_eci = is_self => ctx:query(child_eci,"byu.hr.core","adminECI")
                             | parts[2]
          skey = parts[3]
          has_audio = parts[4].decode()
          record_audio_eci = is_self => ctx:query(child_eci,"byu.hr.core","record_audio_eci") | null
          record_audio_link = is_self => <<#{meta:host}/c/#{record_audio_eci}/query/byu.hr.record/audio.html>> | ""
          <<<div class="entity" id="#{person_id}"#{is_self => << title="this is you">> | ""}>
<a href="#{meta:host}/c/#{the_eci}/query/byu.hr.core/index.html">#{full_name}<span style="float:left#{has_audio => "" | ";visibility:hidden"}">🔈</span></a>
#{is_self => <<
<a href="#{record_audio_link}">&#x1F3A4;</a>
>> | ""}
>>
          + <<</div>
>>
        })
        .join("")
    }
    styles = <<<style type="text/css">
div.entity {
  margin-bottom:7px;
}
div.entity a {
  text-decoration: none;
  font-family: Arial, Helvetica, sans-serif;
  color: black;
}
div#chooser {
  max-width:40%;
  margin: 3em auto;
}
span#lookup {
  display:inline-block;
  width:10em;
  background-color:white;
  border:1px solid #D1CCBD;
  font-family: Arial, Helvetica, sans-serif;
  font-size:150%;
  text-transform:capitalize;
  margin-bottom: 5px;
  padding-left: 5px;
}
div#entitylist {
  height:24em;
  overflow:auto;
  font-size:150%;
  resize:vertical;
}
div#spacer {
  height:23em;
  overflow:hidden;
}
</style>
>>
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
    options = function(el){
      element_names.map(function(e){
      <<<option#{e==el => " selected" | ""}>#{e}</option>
>>}).join("")
    }
    logout = function(_headers){
      netid = html:cookies(_headers).get("netid")
      eci = wrangler:channels("byu-hr-login").head().get("id")
      url = <<#{meta:host}/sky/event/#{eci}/none/byu_hr_login/logout_request>>
      css = [
        "float:right",
        "margin-top:0",
      ]
      netid => <<<p id="whoami" style="#{css.join(";")}">
#{netid}
<button onclick="location='#{url}'">Logout</button>
</p>
>>
        | <<<script type="text/javascript">location='#{url}'</script>
>>
    }
    index = function(_headers){
      netid = html:cookies(_headers).get("netid")
      url = logout(_headers).extract(re#location='([^']*)'#).head()
      html:header("HR OIT",styles,url,_headers)
      + <<<div id="chooser">
>>
      + <<<div id="lookupdiv" title="start typing last name">
  <span style="transform:scale(-1, 1);display:inline-block">👀</span>
  <span id="lookup" contenteditable onkeyup="do_lookup(event)"></span>
</div>
>>
      + <<<div id="entitylist">
>>
      + existing(netid)
      + <<<div id="spacer"></div>
</div>
>>
      + <<</div>
>>
      + <<    <script type="text/javascript">
      var entitylist = document.getElementById("entitylist");
      function do_lookup(ev) {
        var e = ev || window.event;
        var keyCode = e.code || e.keyCode;
        if(keyCode==27 || keyCode==="Escape"){
          e.target.blur();
        }else if(keyCode==="Backspace" || keyCode.startsWith("Key")){
          var the_prefix = e.target.textContent.toUpperCase();
          anchors = entitylist.getElementsByTagName("a");
          for(var i=0; i<anchors.length; ++i){
            if(anchors[i].text.toUpperCase().startsWith(the_prefix)){
              anchors[i].scrollIntoView();
              window.scrollTo(0, 0);
              break;
            }
          }
        }
        return false;
      }
      window.onload = function(){
        window.scrollTo(0, 0);
      };
    </script>
>>
      + html:footer()
    }
    core_rids = [
      "html.byu",
      "io.picolabs.pds",
      "byu.hr.core",
      "byu.hr.record",
    ]
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    every {
      wrangler:createChannel(
        [meta:rid],
        {"allow":[{"domain":"byu_hr_oit","name":"*"}],"deny":[]},
        {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
      )
    }
  }
  rule checkForDuplicateNewPerson {
    select when byu_hr_oit new_person_available
      person_id re#(.+)# // required
      setting(person_id)
    pre {
      duplicate = wrangler:children()
        .any(function(c){c.get("name")==person_id})
    }
    if duplicate then send_directive("duplcate",{"person_id":person_id})
    fired {
      last
    }
  }
  rule createNewPerson {
    select when byu_hr_oit new_person_available
      person_id re#(.+)# // required
      setting(person_id)
    fired {
      raise wrangler event "new_child_request" attributes {
        "name": "*"+person_id,
        "import_data": event:attr("import_data")
      }
    }
  }
  rule installRulesetsInChild {
    select when wrangler new_child_created
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
    fired {
      raise byu_hr_oit event "child_has_rulesets"
        attributes event:attrs.put({"good_name":good_name}) on final
    }
  }
  rule renameChild {
    select when byu_hr_oit child_has_rulesets
    every {
      event:send({"eci":event:attr("eci"),"eid":"rename-child-engine-ui",
        "domain":"engine_ui","type":"box",
        "attrs":{"name":event:attr("good_name")}
      })
      event:send({"eci":event:attr("eci"),"eid":"rename-child-wrangler",
        "domain":"wrangler","type":"name_changed",
        "attrs":{"name":event:attr("good_name")}
      })
    }
  }
  rule populateChild {
    select when wrangler child_initialized
      import_data re#(.+)# setting(import_data)
    pre {
      type = import_data.match(re#^[{]#) => "JSON"
           | import_data.match(re#^"#)   => "TSV"
           |                                null
      eci = event:attrs.get("eci")
    }
    if type then choose type {
      JSON => event:send({"eci":eci,"eid":"import JSON",
                "domain":"byu_hr_core", "type":"json_import_available",
                "attrs":{"json":import_data}})
      TSV  => event:send({"eci":eci,"eid":"import TSV",
                "domain":"byu_hr_core", "type":"tsv_import_available",
                "attrs":{"content":import_data.decode()}})
    }
  }
  rule deleteChild {
    select when byu_hr_oit person_deletion_request
      person_id re#(.+)# // required
      setting(person_id)
    pre {
      eci = wrangler:children()
        .filter(function(c){
          c.get("name")==person_id
        }).head().get("eci")
    }
    if eci.klog("eci to delete") then noop()
    fired {
      raise wrangler event "child_deletion_request" attributes {"eci":eci}
    } else {
      ent:existing_index := clean_index(person_id)
    }
  }
  rule createIndexes {
    select when byu_hr_oit index_refresh
    pre {
      start_time = time:now()
    }
    fired {
      ent:existing_index := make_index()
    }
  }
  rule addRecordRuleset { // temporary; new persons will have it already
    select when byu_hr_oit need_record_ruleset
      netid re#(.+)# setting(netid)
    pre {
      eci = wrangler:children
        .filter(function(c){
          c{"name"} == netid
        }).head().get("eci")
      rid = "byu.hr.record"
    }
    if eci then
    event:send({"eci":eci,"eid":"install-ruleset",
      "domain":"wrangler", "type":"install_ruleset_request",
      "attrs":{"absoluteURL":meta:rulesetURI,"rid":rid}
    })
  }
}
