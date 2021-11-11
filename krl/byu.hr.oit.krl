ruleset byu.hr.oit {
  meta {
    name "HR for IT Offices"
    use module io.picolabs.wrangler alias wrangler
    use module html.byu alias html
    shares index, logout, getTSV
  }
  global {
    make_index = function(read_only){
      main_field_name = element_names.head()
      child_desig = function(c){
        eci = c.get("eci") // family channel ECI
        ctx:query(eci,"byu.hr.core","child_desig",{
          "name":c.get("name"),"read_only":read_only
        })+"|"+eci
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
    clean_index = function(read_only,name){
      (read_only => ent:existing_index_read_only | ent:existing_index)
        .filter(function(ie){ie.split("|")[1] != name})
    }
    existing = function(read_only,el,re){
      eiro = ent:existing_index_read_only
      ei = ent:existing_index
      all = read_only => (eiro => eiro | make_index(read_only))
                       | (ei => ei | make_index(read_only))
      doFilter = function(cd){
        eci = cd.split("|")[5] // the family channel
        ctx:query(eci,"byu.hr.core","getFilter",{"element":el,"re":re})
      }
      the_list = (not el || not re) => all | all.filter(doFilter)
      the_list.display_list(read_only)
    }
    display_list = function(the_list,read_only){
      the_list
        .map(function(cd){
          parts = cd.split("|")
          full_name = parts.head()
          person_id = parts[1]
          the_eci = parts[2]
          skey = parts[3]
          has_audio = parts[4].decode()
          <<<div class="entity" id="#{person_id}" style="margin-bottom:7px">
<a href="#{meta:host}/c/#{the_eci}/query/byu.hr.core/index.html"#{read_only => "" | << onclick="return display(this)">>}>#{full_name}<span style="float:left#{has_audio => "" | ";visibility:hidden"}">🔈</span></a>
>> + (read_only => "" | <<<a href="#{meta:host}/c/#{meta:eci}/event/byu_hr_oit/person_deletion_request?person_id=#{person_id}" onclick="return delPerson(this)" class="delperson">delete</a>
>>)
          + <<</div>
>>
        })
        .join("")
    }
    styles = <<<style type="text/css">
a {
  text-decoration:none;
  color:black;
}
a.delperson {
  display:block;
  float:right;
  padding-right:15px;
}
div#chooser {
  max-width:40%;
  margin: 0 auto;
}
#person {
  float:right;
  width:60%;
  height:100%;
  padding-left:5px;
  min-height:90vh;
  border:none;
  border-left: dashed grey 1px;
}
.entity:hover a:first-child {
  background-color:LightGray;
}
</style>
>>
    scripts = <<<script type="text/javascript">
var display = function(theLink){
  var theDiv = document.getElementById("person");
  theDiv.src = theLink.href;
  return false;
}
var doCreate = function(theForm){
  var params = {};
  params.person_id = theForm.person_id.value;
  params.import_data = theForm.import_data.value;
  var xhr = new XMLHttpRequest();
  xhr.onload = function(){setTimeout("location.reload()",100);}
  xhr.onerror = function(){alert(xhr.responseText);}
  xhr.open(theForm.method,theForm.action,true);
  xhr.setRequestHeader('Content-type','application/json')
  xhr.send(JSON.stringify(params));
  return false;
}
var delPerson = function(theLink){
  var theHref = theLink.href;
  var parts = theHref.split(/person_id=/);
  if(parts.length>1 && confirm("Delete "+parts[1]+"?")){
    var xhr = new XMLHttpRequest();
    xhr.onload = function(){setTimeout("location.reload()",100);}
    xhr.onerror = function(){alert(xhr.responseText);}
    xhr.open("post",theHref,true);
    xhr.send();
  }
  return false;
}
</script>
>>
    new_person_form = function(){
      <<<h2>New Person</h2>
<form method="post" action="#{meta:host}/c/#{meta:eci}/event/byu_hr_oit/new_person_available" onsubmit="return doCreate(this)">
<input name="person_id" required placeholder="Net ID"><br>
<textarea name="import_data" placeholder="Import data if any"></textarea><br>
<button type="submit" disabled title="broken">Create</button>
</form>
>>
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
    filterPersons = function(el,re){
      reValue = re => <<value="#{re}">>
                    | <<placeholder="Reg Exp">>
      jsClear = [
        "form[0].selectedIndex=0",
        "form[1].value=''",
        "return true"
      ].join(";")
      clearOption =
        re || el => <<<button type="submit" onclick="#{jsClear}">X</button>
>> | ""
      <<<div>
<form id="filter" method="get">
Filter: <select name="element">
<option value="">none</option>
#{options(el)}</select>
<input type="text" name="re" #{reValue}>
<button type="submit">apply</button>
#{clearOption}</form>
</div>
<script type="text/javascript">
window.addEventListener("pageshow",()=>{
  document.getElementById("filter").reset()
})
</script>
>>
    }
    download_link = function(){
      <<<br>
<a href="#{meta:host}/sky/cloud/#{meta:eci}/#{meta:rid}/getTSV.txt" download="all.tsv">Download TSV</a>
>>
    }
    getTSV = function(){
      wrangler:children()
        .filter(function(c){
          not match(c.get("name"),re#^\*#)
        })
        .map( function(c){
          ctx:query(c.get("eci"),"byu.hr.core","getOneTSV")
        })
        .join(10.chr())
    }
    index = function(element,re,_headers){
      time_start = time:now()
      read_only = wrangler:channels()
        .filter(function(c){c.get("id")==meta:eci})
        .head()
        .get("tags") >< "read-only"
      url = logout(_headers).extract(re#location='([^']*)'#).head()
      html:header("HR OIT",(read_only => "" | styles+scripts),url,_headers)
      + <<<h1>HR OIT</h1>
>>
      + (read_only => "" | <<<iframe id="person"></iframe>
>>)
      + <<<div id="chooser" style="max-width:40%;margin: 0 auto">
<h2>Existing Persons</h2>
>>
      + filterPersons(element,re)
      + <<<p>Count: <span id="count"></span></p>
>>
      + <<<span style="transform:scale(-1, 1);display:inline-block">👀</span><span id="lookup" contenteditable onkeyup="do_lookup(event)" style="display:inline-block;width:10em;background-color:white;border:1px solid #D1CCBD"></span>
>>
      + <<<div id="entitylist" style="height:24em;overflow:auto;font-size:120%">
>>
      + existing(read_only,element,re)
      + <<<div id="spacer" style="height:23em;overflow:hidden"></div>
</div>
<script type="text/javascript">
document.getElementById("count").textContent = document.getElementById("entitylist").getElementsByTagName("a").length#{read_only => "" | "/2"}
</script>
>>
      + (read_only => "" | download_link())
      + (read_only => "" | new_person_form())
      + <<</div>
<pre>
Final time: #{time:now()}
Start time: #{time_start}
Elapsed seconds: #{elapsed_seconds(time_start,time:now())}
</pre>
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
    elapsed_seconds = function(start,final){
      hours_minutes_and_seconds = re#^[^T]*T(\d\d):(\d\d):(\d\d.\d\d\d)Z#
      start_parts = start.extract(hours_minutes_and_seconds)
      start_hour = start_parts[0].as("Number")
      start_min = start_parts[1].as("Number")
      start_sec = start_parts[2].as("Number")
      final_parts = final.extract(hours_minutes_and_seconds)
      final_hour = final_parts[0].as("Number")
      final_min = final_parts[1].as("Number")
      final_sec = final_parts[2].as("Number")
      min_borrowed = final_sec < start_sec => 1 | 0
      sec_diff = final_sec - start_sec + 60 * min_borrowed
      min_diff = final_min - start_min + (start_hour==final_hour => 0 | 60)
        - min_borrowed
      math:round(sec_diff + 60 * min_diff,3)
    }
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    every {
      wrangler:createChannel(
        [meta:rid],
        {"allow":[{"domain":"byu_hr_oit","name":"*"}],"deny":[]},
        {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
      )
      wrangler:createChannel(
        [meta:rid,"read-only"],
        {"allow":[],"deny":[{"domain":"*","name":"*"}]},
        {"allow":[{"rid":meta:rid,"name":"index"}],"deny":[]}
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
      ent:existing_index := clean_index(false,person_id)
      ent:existing_index_read_only := clean_index(true,person_id)
    }
  }
  rule createIndexes {
    select when byu_hr_oit index_refresh
    pre {
      start_time = time:now()
    }
    fired {
      ent:existing_index := make_index()
      ent:existing_index_read_only := make_index(true)
      raise byu_hr_oit event "timed_evaluation_complete"
        attributes {"start_time":start_time}
    }
  }
  rule reportElapsedTime {
    select when byu_hr_oit timed_evaluation_complete
      start_time re#(.+)#
      setting(start_time)
    send_directive("timer",{
      "start_time":start_time,
      "final_time":time:now(),
      "elapsed_time":elapsed_seconds(start_time,time:now())
    })
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
