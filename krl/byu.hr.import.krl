ruleset byu.hr.import {
  meta {
  }
  global {
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
    lines_from = function(url){
      response = http:get(url)
      ok = response{"content_type"}.match(re#text/tab-separated-values#)
        && response{"status_code"}==200
      content = ok => response{"content"} | null
      content => content.split(10.chr()) | []
    }
    lineAsAttributes = function(line){
      fields = line.split(9.chr())
      netid = fields.head()
      data = fields.tail()
      json = element_names.reduce(function(a,en,i){
        a.put(en,data[i])
      },{})
      return {"person_id":netid,"import_data":json.encode()}
    }
  }
  rule doImportFromURL {
    select when byu_hr_dds import_available
      url re#(.+)#
      setting(url)
    foreach lines_from(event:attrs{"url"}) setting(line)
    fired {
      raise byu_hr_dds event "new_person_available" attributes
        line.lineAsAttributes()
    }
  }
  rule doImportOfOneLine {
    select when byu_hr_dds import_available
      line re#(.+)#
      setting(line)
    fired {
      raise byu_hr_dds event "new_person_available" attributes
        line.lineAsAttributes()
    }
  }
}
