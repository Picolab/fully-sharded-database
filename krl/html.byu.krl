ruleset html.byu {
  meta {
    provides header, footer, cookies, defendHTML
  }
  global {
    byu_logo_svg = "https://raw.githubusercontent.com/Picolab/fully-sharded-database/main/images/BYU%20logo.svg"
    user_circle_svg = "https://raw.githubusercontent.com/Picolab/fully-sharded-database/main/images/user-circle-o-white.svg"
    header = function(title,scripts,unused,notused,_headers) {
      logout_url = meta:host.extract(re#(.+):\d+#).head()
      the_cookies = cookies(_headers)
      netid = the_cookies.get("netid")
      display_name = the_cookies.get("displayname")
      logout_path = the_cookies.get("logoutpath")
      logoutURL = logout_path => meta:host+logout_path | logout_url+"?old"
      home_path = the_cookies.get("homepath")
      homeURL = home_path => meta:host+home_path | null
      displayLink = homeURL => <<<a href="#{homeURL}">#{display_name}</a\>>>
                             | null
      CMBN = "Calling Me By Name"
      displayCMBN = homeURL => <<<a href="#{homeURL}">#{CMBN}</a\>>> | CMBN
      <<<!DOCTYPE HTML>
<html>
  <head>
    <title>#{title}</title>
    <meta charset="UTF-8">
<!-- OneTrust Cookies Consent Notice start for byu.edu -->
<script type="text/javascript" src="https://cdn.cookielaw.org/consent/6985a5b2-0d75-4cac-8d42-8564ff47121f/OtAutoBlock.js" ></script>
<script src="https://cdn.cookielaw.org/scripttemplates/otSDKStub.js"  type="text/javascript" charset="UTF-8" data-domain-script="6985a5b2-0d75-4cac-8d42-8564ff47121f" ></script>
<script type="text/javascript">
function OptanonWrapper() { }
</script>
<!-- OneTrust Cookies Consent Notice end for byu.edu -->
#{scripts.defaultsTo("")}
<style type="text/css">
body {
  background: linear-gradient(60deg, #D1CCBD, #FBFBFA);
  min-height: 100vh;
  font-family: Arial, Helvetica, sans-serif;
}
#byu_bar {
  background-color: #002E5D;
  height: 65px;
}
#byu_bar img {
  padding: 20px;
  vertical-align: middle;
}
#byu_bar img.logo {
  border-right: solid 1px #0057b8;
}
#byu_bar img.user-circle {
  float:right;
}
#byu_bar .cmbn {
  color: white;
  vertical-align: middle;
  font-size: 24px;
  padding-left: 20px;
}
#byu_bar .logout {
  float: right;
  color: white;
  vertical-align: middle;
  margin: 23px 20px 0 0;
}
#byu_bar a {
  color: inherit;
  text-decoration: none;
}
#byu_bar .username {
  float: right;
  color: white;
  vertical-align: middle;
  margin: 23px 0 0 0;
}
</style>
  </head>
  <body>#{netid
  => <<<div id="byu_bar">
<img class="logo" src="#{byu_logo_svg}">
<span class="cmbn">#{displayCMBN}</span>
<span class="logout"><a href="#{logoutURL}">Sign Out</a></span>
<img class="user-circle" src="#{user_circle_svg}">
<span class="username">#{displayLink || display_name || netid}</span>
</div>
>>
   | <<<script type="text/javascript">location="#{logoutURL}"</script>
>>}
>>
    }
    footer = function() {
      <<
<div>
<a href="https://privacy.byu.edu/" target="_blank">Privacy Notice</a>
 | 
<a href="https://infosec.byu.edu/cookie-prefs" target="_blank">Cookie Preferences</a>
</div>
  </body>
</html>
>>
    }
    cookies = function(_headers) {
      arg = event:attr("_headers") || _headers
      arg{"cookie"}.isnull() => {} |
      arg{"cookie"}
        .split("; ")
        .map(function(v){v.split("=")})
        .collect(function(v){v.head()})
        .map(function(v){v.head()[1]})
    }
    defendHTML = function(input,max_length=50){
      length = input.length()
      input
        .substr(0,length>max_length => max_length | null)
        .replace(re#&#g,"&amp;")
        .replace(re#<#g,"&lt;")
        .replace(re#>#g,"&gt;")
        .replace(re#'#g,"&apos;")
        .replace(re#"#g,"&quot;")
    }
  }
}
