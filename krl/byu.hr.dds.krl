ruleset byu.hr.dds {
  meta {
    name "HR Domain Data Store"
    use module io.picolabs.wrangler alias wrangler
    use module html
    shares index, logout, getTSV
  }
  global {
    make_index = function(read_only){
      main_field_name = element_names.head()
      child_desig = function(c){
        name = c.get("name")
        eci = c.get("eci") // family channel ECI
        json = ctx:query(eci,"byu.hr.core","getJSON")
        the_eci = ctx:query(eci,"byu.hr.core",
          read_only => "getECI" // read-only ECI
                     | "adminECI" // admin ECI
        )
        return
        [json.get(main_field_name),name,the_eci,eci].join("|")
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
    existing = function(read_only,el,re){
      eiro = ent:existing_index_read_only
      ei = ent:existing_index
      all = read_only => (eiro => eiro | make_index(read_only))
                       | (ei => ei | make_index(read_only))
      doFilter = function(cd){
        eci = cd.split("|")[3] // the family channel
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
          <<<div class="entity">
<a href="#{meta:host}/c/#{the_eci}/query/byu.hr.core/index.html"#{read_only => "" | << onclick="return display(this)">>}>#{full_name+" -- "+person_id}</a>
>> + (read_only => "" | <<<a href="#{meta:host}/c/#{meta:eci}/event/byu_hr_dds/person_deletion_request?person_id=#{person_id}" onclick="return delPerson(this)" class="delperson">delete</a>
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
  max-width:40%
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
<form method="post" action="#{meta:host}/c/#{meta:eci}/event/byu_hr_dds/new_person_available" onsubmit="return doCreate(this)">
<input name="person_id" required placeholder="Person ID"><br>
<textarea name="import_data" placeholder="Import data if any"></textarea><br>
<button type="submit">Create</button>
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
      "Employee Classification Description",
      "Employee Pay Classification",
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
        | <<<script type="text/javascript">location = "#{url}"</script>
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
      html:header("HR DDS - Public",(read_only => "" | styles+scripts))
      + logout(_headers)
      + <<<h1>HR DDS: Personal Information - Public</h1>
>>
      + (read_only => "" | <<<iframe id="person"></iframe>
>>)
      + <<<div id="chooser">
<h2>Existing Persons</h2>
>>
      + filterPersons(element,re)
      + <<<p>Count: <span id="count"></span></p>
>>
      + <<<div id="entitylist" style="margin-top:1em;height:24em;overflow:auto">
>>
      + existing(read_only,element,re)
      + <<</div>
<script type="text/javascript">
document.getElementById("count").textContent = document.getElementById("entitylist").getElementsByTagName("div").length
</script>
>>
      + (read_only => "" | download_link())
      + (read_only => "" | new_person_form())
      + <<</div>
<pre>
Final time: #{time:now()}
Start time: #{time_start}
Elapsed seconds: #{elapsed_seconds(time_start,time:now()).math:round(3)}
</pre>
>>
      + html:footer()
    }
    core_rids = [
      "html",
      "io.picolabs.pds",
      "byu.hr.core",
    ]
    elapsed_seconds = function(start,end){
      minutes_and_seconds = re#^[^:]*:(\d\d):(\d\d.\d\d\d)Z#
      start_parts = start.extract(minutes_and_seconds)
      end_parts = end.extract(minutes_and_seconds)
      difference = end_parts[1].as("Number") - start_parts[1].as("Number")
      start_parts[0] == end_parts[0] => difference
        | difference + 60
    }
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    every {
      wrangler:createChannel(
        [meta:rid],
        {"allow":[{"domain":"byu_hr_dds","name":"*"}],"deny":[]},
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
    select when byu_hr_dds new_person_available
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
    select when byu_hr_dds new_person_available
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
      raise byu_hr_dds event "child_has_rulesets"
        attributes event:attrs.put({"good_name":good_name}) on final
    }
  }
  rule renameChild {
    select when byu_hr_dds child_has_rulesets
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
    select when byu_hr_dds person_deletion_request
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
    }
  }
  rule createIndexes {
    select when byu_hr_dds index_refresh
    fired {
      ent:existing_index := make_index()
      ent:existing_index_read_only := make_index(true)
    }
  }
}