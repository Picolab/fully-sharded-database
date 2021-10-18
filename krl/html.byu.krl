ruleset html {
  meta {
    use module io.picolabs.wrangler alias wrangler
    provides header, footer, cookies
    shares __testing
  }
  global {
    __testing = { "queries":
      [ { "name": "__testing" }
      //, { "name": "entry", "args": [ "key" ] }
      ] , "events":
      [ //{ "domain": "d1", "type": "t1" }
      //, { "domain": "d2", "type": "t2", "attrs": [ "a1", "a2" ] }
      ]
    }
    header = function(title,scripts,_headers) {
      netid = cookies(_headers).get("netid")
      action = netid => "Sign Out" | "Sign In"
      eci = wrangler:channels("byu-hr-login").head().get("id")
      url = <<#{meta:host}/sky/event/#{eci}/none/byu_hr_login/logout_request>>
      <<<!DOCTYPE HTML>
<html>
  <head>
    <title>#{title}</title>
    <meta charset="UTF-8">
#{scripts.defaultsTo("")}
<style type="text/css">
#byu_bar {
  background-color: #002E5D;
  height: 65px;
  position: fixed;
  top: 0px;
  left: 1px;
  right: 1px;
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
#byu_bar .title {
  color: white;
  vertical-align: middle;
  font-family: Arial, sans-serif;
  font-size: 24px;
  padding-left: 20px;
}
#byu_bar .logout {
  float: right;
  color: white;
  font-family: Arial, sans-serif;
  vertical-align: middle;
  margin: 23px 20px 0 0;
}
#byu_bar .logout a {
  text-decoration: none;
}
#byu_bar .username {
  float: right;
  color: white;
  font-family: Arial, sans-serif;
  vertical-align: middle;
  margin: 23px 0 0 0;
}
</style>
  </head>
  <body>#{netid
  => <<<div id="byu_bar">
<img class="logo" src="images/BYU%20logo.svg">
<span class="title">Calling Me By Name</span>
<span class="logout"><a href="#{url}">Sign Out</a></span>
<img class="user-circle" src="images/user-circle-o-white.svg">
<span class="username">#{netid}</span>
</div>
>>
   | <<<script type="text/javascript">location="#{url}"</script>
>>}
>>
    }
    footer = function() {
      <<  </body>
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
  }
}

