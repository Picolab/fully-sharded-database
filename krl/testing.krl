ruleset testing {
  meta {
    use module io.picolabs.wrangler alias wrangler
    use module html.byu alias html
    shares index
  }
  global {
    index = function(_headers){
      wth = _headers.klog("_headers")
      cookies = html:cookies(_headers).klog("cookies")
      try_eci = wrangler:channels("byu-hr-login").head().get("id")
      eci = try_eci => try_eci |
        ctx:query(
          wrangler:parent_eci(),
          "byu.hr.oit",
          "logout",
          {"_headers":_headers}
        ).extract(re#location='([^']*)'#).head()
      url = <<#{meta:host}/sky/event/#{eci}/none/byu_hr_login/logout_request>>
      html:header("testing","",url,_headers)
        + <<<h1>testing</h1>
<p>1, 2, 3, testing</p>
>>
        + html:footer()
    }
  }
}
