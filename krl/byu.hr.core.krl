ruleset byu.hr.core {
  meta {
    name "Personal Information - Public"
    description <<
      Core personal information of the organization's employees available for all organizational users to see.
    >>
    use module io.picolabs.pds alias pds
    use module html
    use module io.picolabs.wrangler alias wrangler
    shares getData, getTSV, getJSON, index, getFilter, getOneTSV, child_desig
  }
  global {
    event_types = [
      "tsv_import_available",
      "json_import_available",
      "new_field_value",
    ]
    eventPolicy = {
      "allow": event_types.map(function(et){
        {"domain":"byu_hr_core"}.put("name",et)
      }),
      "deny": []
    }
    queryPolicy = {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
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
    </style>
>>
    scripts = function() {
      <<    <script type="text/javascript">
      var updURL = "#{meta:host}/c/#{meta:eci}/event/byu_hr_core/new_field_value?";
      function selAll(cell){
        window.getSelection().selectAllChildren(cell);
      }
      function munge(ev) {
        var e = ev || window.event;
        var keyCode = e.code || e.keyCode;
        if(keyCode==27 || keyCode==="Escape"){
          document.execCommand("undo");
          e.target.blur();
        }else if(keyCode==13 || keyCode==="Enter"
            || keyCode==9 || keyCode==="Tab"){
          var thespan = e.target.textContent;
          // persist
          var thename = e.target.previousElementSibling.textContent;
          var httpReq = new XMLHttpRequest();
          httpReq.open("GET",updURL+"name="+thename+"&value="+thespan);
          httpReq.send();
          e.target.blur();
          return false;
        }
      }
    </script>
>>
    }
    table_row = function(string,read_only){
      cell_attrs =
        << contenteditable onkeydown="munge(event)" onfocus="selAll(this)">>
      cells = string.split(" is ")
      name = cells.head()
      value_desc = cells.tail().join(" is ").extract(re#(.*) \((This .*)\)$#)
      value = value_desc.head()
      desc = value_desc.tail().join("")
      <<<td title="#{desc}">#{name}</td>
<td#{read_only => "" | cell_attrs}>#{value}</td>
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
    logout = function(_headers){
      ctx:query(
        wrangler:parent_eci(),
        "byu.hr.oit",
        "logout",
        {"_headers":_headers}
      )
      + <<<script type="text/javascript">
if(window.frameElement){
  document.getElementById("whoami").style.visibility="hidden";
}
</script>
>>
    }
    index = function(_headers){
      read_only = wrangler:channels()
        .filter(function(c){c.get("id")==meta:eci})
        .head()
        .get("tags") >< "read-only"
      audio_eci = wrangler:channels("record_audio")
        .head()
        .get("id")
      netid = html:cookies(_headers).get("netid")
      html:header("person",(read_only => styles | scripts()))
      + logout(_headers)
      + <<<table>
>>
      + getData().map(function(s){s.entry(read_only)}).join("")
      + <<</table>
>>
      + (audio_eci => <<<pre>
audio_eci = #{audio_eci}
netid = #{netid}
login = #{wrangler:name()}
</pre>
>> | "")
      + (read_only => exports() | "")
      + html:footer()
    }
    adminECI = function(){
      wrangler:channels("byu-hr-core").head().get("id")
    }
    getFilter = function(element,re){
      element && re => pds:getData("person",element).match(re)
                     | true
    }
    getKey = function(){
      stuff_names = [
        "Last Name",
        "Work Email",
        "F/T-P/T Status",
      ]
      stuff = stuff_names.map(function(n){
        pds:getData("person",n)
      }).join(":")
      math:hash("sha256",stuff)
        .substr(0,9)
    }
    child_desig = function(name,read_only){
      full_name = pds:getData("person",element_names.head())
      skey = getKey()
      the_eci = 
        read_only => getECI() // read-only ECI
                   | adminECI() // admin ECI
      return
      [full_name,name,the_eci,skey].join("|")
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
    fired {
      raise pds event "new_data_available" attributes {
        "domain":"person",
        "key":event:attr("name"),
        "value":event:attr("value")
      }
    }
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    every {
      wrangler:createChannel([meta:rid],eventPolicy,queryPolicy)
      wrangler:createChannel(
        [meta:rid,"read-only"],
        {"allow":[],"deny":[{"domain":"*","name":"*"}]},
        {"allow":[{"rid":meta:rid,"name":"index"}],"deny":[]}
      )
    }
  }
}
