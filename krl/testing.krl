ruleset testing {
  meta {
    use module html.byu alias html
    shares index
  }
  global {
    index = function(_headers){
      wth = _headers.klog("_headers")
      cookies = html:cookies(_headers).klog("cookies")
      html:header("testing","",_headers)
        + <<<h1>testing</h1>
<p>1, 2, 3, testing</p>
>>
        + html:footer()
    }
  }
}
