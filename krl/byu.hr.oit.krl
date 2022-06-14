ruleset byu.hr.oit {
  meta {
    name "list of persons"
    use module io.picolabs.wrangler alias wrangler
    use module html.byu alias html
    use module io.picolabs.subscription alias subs
    shares index, personExists
    provides subs_as_children
  }
  global {
    subs_as_children = function(){
      all_channels = wrangler:channels()
      participant_name = function(eci){
        all_channels
          .filter(function(c){c{"id"}==eci})
          .head()
          .get("tags")
          .filter(function(t){t != "participant"})
          .head()
      }
      subs:established("Rx_role","participant list")
        .filter(function(s){s{"Tx_role"}=="participant"})
        .map(function(s){
            {"eci":s{"Tx"}, "name":s{"Rx"}.participant_name()}
          })
    }
    getLoggedInECI = function(person_id){
      subs_as_children()
        .filter(function(c){
          c.get("name")==person_id
        }).head().get("eci")
    }
    personExists = function(netid,list){
      desig_re = ("^[^|]+[|]"+netid+"[|]").as("RegExp")
      list.isnull() => subs_as_children().any(function(c){c{"name"}==netid})
                     | list.any(function(d){d.match(desig_re)})
    }
    make_index = function(){
      main_field_name = element_names.head()
      child_desig = function(c){
        child_eci = c.get("eci") // family channel ECI
        ctx:query(child_eci,"byu.hr.core","child_desig",{
          "name":c.get("name")})+"|"+child_eci
      }
      subs_as_children()
        .filter(function(c){
          eci = c.get("eci") // family channel ECI
          omit_child = match(c.get("name"),re#^\*#)
          omit_child => false | true
        })
        .map(child_desig)
        .sort()
    }
    existing = function(netid){
      the_list = ent:existing_index || make_index()
      pe = personExists(netid,the_list)
      the_list
        .map(function(cd){
          parts = cd.split("|")
          full_name = parts.head()
          person_id = parts[1]
          is_self = netid == person_id
          child_eci = parts[5]
          the_eci = is_self => ctx:query(child_eci,"byu.hr.core","adminECI")
                             | parts[2]
          has_audio = parts[4].decode()
          record_audio_eci = is_self => ctx:query(child_eci,"byu.hr.core","record_audio_eci") | null
          record_audio_link = is_self => <<#{meta:host}/c/#{record_audio_eci}/query/byu.hr.record/audio.html>> | ""
          <<<div class="entity" id="#{person_id}">
<a href="#{meta:host}/c/#{the_eci}/query/byu.hr.core/index.html?personExists=#{pe}"#{is_self => << title="this is you">> | ""}>#{full_name}</a>
<span style="float:left#{has_audio => "" | ";visibility:hidden"}" onclick="playAudio('#{the_eci}')" title="click to hear name">🔈</span>
#{is_self => <<<a class="microphone" href="#{record_audio_link}" title="manage your audio">&#x1F3A4;</a>
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
div.entity:hover {
  background-color: #EFECE7;
}
div.entity span:hover, div.entity a.microphone:hover {
  background-color: #A0D1EA;
  border-radius: 50%;
  cursor: pointer;
}
div#chooser {
  max-width:40%;
  margin: 3em auto;
}
#lookupdiv .eyeball {
  transform:scale(-1, 1);
  display:inline-block;
  cursor: pointer;
}
#lookupdiv .eyeball:hover {
  transform:scale(-1,-1);
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
#pullleft {
  position: fixed;
  top: 40vh;
  left: 0;
}
#pullleft div {
  display: none;
}
#pullleft p, #pullleft form {
  margin: 10px;
}
#pullleft input[type="checkbox"] + label {
  cursor: pointer;
}
#pullleft input[type="checkbox"]:checked + label + div {
  display:block;
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
    pullleft = function(netid){
      pe = personExists(netid,ent:existing_index)
      option_about = <<<input type="checkbox" id="checkbox_a">
<label for="checkbox_a">About</label>
<div>
<p>
"calling me <strong>by name</strong>"
</p>
<p>
Joseph Smith—History 1:17
</p>
</div>
>>
      option_opt_in = pe => "" | <<<input type="checkbox" id="checkbox_oi">
<label for="checkbox_oi">Opt In</label>
<div>
<form method="POST" onsubmit="return doOptIn(this)">
<input type="hidden" name="person_id" value="#{netid}">
<input name="last" placeholder="Lastname"><br>
<input name="first" placeholder="Firstname"><br>
<input type="submit" value="Submit">
</form>
</div>
>>
      option_opt_out = pe => <<<input type="checkbox" id="checkbox_oo">
<label for="checkbox_oo">Opt Out</label>
<div>
<p>
Right to be forgotten
</p>
<form method="POST" onsubmit="return doOptOut(this)">
<input type="hidden" name="person_id" value="#{netid}">
<input type="submit" value="Opt Out">
</form>
</div>
>> | ""
      <<<div id="pullleft">
#{option_about}<br>
#{option_opt_in}#{option_opt_out}
</div>
>>
    }
    index = function(_headers){
      netid = html:cookies(_headers).get("netid")
      html:header("BY NAME",styles,null,null,_headers)
      + <<<div id="chooser">
>>
      + <<<div id="lookupdiv" title="click and start typing last name" onclick="document.getElementById('lookup').focus()">
  <span class="eyeball">👀</span>
  <span id="lookup" contenteditable onkeyup="do_lookup(event)" onkeydown="return event.keyCode!=13" onfocus="this.textContent='';document.getElementById('entitylist').scrollTop=0"></span>
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
      + pullleft(netid)
      + <<    <script type="text/javascript">
      function find_a(){
        var prefx = document.getElementById("lookup").textContent.toUpperCase();
        var entitylist = document.getElementById("entitylist");
        anchors = entitylist.getElementsByTagName("a");
        for(var i=0; i<anchors.length; ++i){
          if(anchors[i].text.toUpperCase().startsWith(prefx)){
            return anchors[i];
          }
        }
        return null;
      }
      function do_lookup(ev) {
        var e = ev || window.event;
        var keyCode = e.code || e.keyCode;
        if(keyCode==27 || keyCode==="Escape"){
          e.target.textContent = "";
          e.target.blur();
        }else if(keyCode==13 || keyCode==="Enter"){
          var the_a = find_a();
          if(the_a){
            the_a.click();
          }
        }else if(keyCode==="Backspace" || keyCode.startsWith("Key")){
          var the_a = find_a();
          if(the_a){
            the_a.scrollIntoView();
            window.scrollTo(0, 0);
          }
        }
        return false;
      }
      window.scrollTo(0, 0);
      if(location.hash){
        document.getElementById(location.hash.substr(1)).scrollIntoView();
      }
      function doOptIn(the_form){
        var url = '#{meta:host+"/sky/event/"+meta:eci+"/opt_in/byu_hr_oit/opt_in"}';
        var last = the_form.last.value;
        var first = the_form.first.value;
        var full_name = last + ", " + first;
        var person_id = the_form.person_id.value;
        if(confirm("You are opting in as "+full_name+".")){
          var form_data = "person_id="+person_id
            + "&last="+encodeURIComponent(last)
            + "&first="+encodeURIComponent(first);
          var redirectURL = '#{meta:host+"/c/"+meta:eci+"/query/byu.hr.oit/index.html#"}'+person_id;
          var httpReq = new XMLHttpRequest();
          httpReq.onload = function(){location.replace(redirectURL);location.reload();}
          httpReq.onerror = function(){alert(httpReq.responseText);}
          httpReq.open("POST",url,true);
          httpReq.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
          httpReq.send(form_data);
          alert("This will take just a moment.");
        }
        return false;
      }
      function doOptOut(the_form){
        var url = '#{meta:host+"/sky/event/"+meta:eci+"/opt_out/byu_hr_oit/person_deletion_request"}';
        var netid = the_form.person_id.value;
        if(confirm("You (NetID "+netid+") wish to opt out. This cannot be undone.")){
          var form_data = "person_id="+netid;
          var redirectURL = '#{meta:host+"/c/"+meta:eci+"/query/byu.hr.oit/index.html"}';
          var httpReq = new XMLHttpRequest();
          httpReq.onload = function(){location = redirectURL;}
          httpReq.onerror = function(){alert(httpReq.responseText);}
          httpReq.open("POST",url,true);
          httpReq.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
          httpReq.send(form_data);
          alert("This will take just a moment.");
        }
        return false;
      }
      function playAudio(eci){
        var url = '#{meta:host}/c/'+eci+'/query/byu.hr.core/audioURL.txt';
        var xhr = new XMLHttpRequest;
        xhr.onload = function(){
          var data = xhr.response;
          if(data && data.length){
            a=new Audio(data);
            a.addEventListener('canplaythrough', event => {a.play();});
          }
        }
        xhr.onerror = function(){alert(xhr.responseText);};
        xhr.open("GET",url,true);
        xhr.send();
      }
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
      duplicate = personExists(person_id,ent:existing_index)
    }
    if duplicate then send_directive("duplicate",{"person_id":person_id})
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
    pre {
      child_eci = event:attr("eci")
      name = event:attr("good_name")
      duplicate = personExists(name,ent:existing_index)
    }
    if not duplicate then every {
      event:send({"eci":child_eci,"eid":"rename-child-engine-ui",
        "domain":"engine_ui","type":"box",
        "attrs":{"name":name}
      })
      event:send({"eci":child_eci,"eid":"rename-child-wrangler",
        "domain":"wrangler","type":"name_changed",
        "attrs":{"name":name}
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
    fired {
      raise byu_hr_oit event "child_populated" attributes event:attrs
    }
  }
  rule subscribeToChildAsParticipant {
    select when wrangler child_initialized
    fired {
      raise wrangler event "subscription" attributes {
        "wellKnown_Tx": event:attrs{"eci"},
        "Rx_role": "participant list",
        "Tx_role": "participant",
        "name": event:attrs{"name"}.replace(re#^\*#,""),
        "channel_type": "participant",
      }
    }
  }
  rule deleteChild {
    select when byu_hr_oit person_deletion_request
      person_id re#(.+)# // required
      setting(person_id)
    pre {
      referer = event:attrs{["_headers","referer"]}
      isExpected = function(refr){
        refr == meta:host+"/c/"+meta:eci+"/query/"+meta:rid+"/index.html"
      }
      eci = getLoggedInECI(person_id)
    }
    if referer.isExpected() &&  eci.klog("eci to delete") then
    every {
      send_directive("_cookie",{"cookie": <<displayname=; Path=/; Max-Age:-1>>})
      event:send({"eci":eci,"domain":"wrangler","type":"rulesets_need_to_cleanup"})
      event:send({"eci":eci,"domain":"wrangler","type":"ready_for_deletion"})
    }
  }
  rule createIndexes {
    select when byu_hr_oit index_refresh_needed
             or wrangler subscription_added
             or wrangler child_deleted
    pre {
      start_time = time:now()
    }
    fired {
      ent:existing_index := make_index()
      raise byu_hr_oit event "index_refreshed"
        attributes {"start_time":start_time}
    }
  }
  rule reportElapsedTime {
    select when byu_hr_oit index_refreshed
    send_directive("index_refreshed",{
      "start_time":event:attrs{"start_time"},
      "end_time":time:now()
    })
  }
  rule childDesigChanged {
    select when byu_hr_oit new_child_designation
      netid re#(.+)#
      child_desig re#(.+)#
      setting(netid,new_child_desig)
    pre {
      desig_re = ("^[^|]+[|]"+netid+"[|]").as("RegExp")
      sanity = new_child_desig.match(desig_re).klog("sanity")
      new_existing_index = ent:existing_index.map(function(cd){
        cd.match(desig_re) => new_child_desig+"|"+cd.split("|")[5] | cd})
    }
    if sanity then noop()
    fired {
      ent:existing_index := new_existing_index
    }
  }
  rule addPersonOptingIn {
    select when byu_hr_oit opt_in
      person_id re#(.+)#
      last re#(.+)#
      first re#(.+)#
      setting(person_id,last,first)
    pre {
      cleaned_last = last.html:defendHTML()
      cleaned_first = first.html:defendHTML()
      import_data = {}
        .put(element_names[0],cleaned_last+", "+cleaned_first)
        .put(element_names[1],cleaned_first)
        .put(element_names[2],cleaned_last)
        .encode()
      display_name = cleaned_first + " " + cleaned_last
    }
    send_directive("_cookie",{"cookie":<<displayname=#{display_name}; Path=/>>})
    fired {
      raise byu_hr_oit event "new_person_available" attributes {
        "person_id": person_id,
        "import_data": import_data
      }
    }
  }
}
