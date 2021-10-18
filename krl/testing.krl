ruleset testing {
  meta {
    use module html.byu alias html
    shares index
  }
  global {
    index = function(_headers){
      html:header("testing")
        + <<<h1>testing</h1>
<p>1, 2, 3, testing</p>
>>
        + html:footer()
    }
  }
}
