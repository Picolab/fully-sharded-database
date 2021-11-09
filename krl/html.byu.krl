ruleset html.byu {
  meta {
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
    header = function(title,scripts,logout_url,_headers) {
      netid = cookies(_headers).get("netid")
      <<<!DOCTYPE HTML>
<html>
  <head>
    <title>#{title}</title>
    <meta charset="UTF-8">
#{scripts.defaultsTo("")}
<style type="text/css">
body {
  background: linear-gradient(60deg, #D1CCBD, #FBFBFA);
  overflow: hidden;
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
  color: inherit;
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
<img class="logo" src="/images/BYU%20logo.svg">
<span class="title">Calling Me By Name</span>
<span class="logout"><a href="#{logout_url}">Sign Out</a></span>
<img class="user-circle" src="/images/user-circle-o-white.svg">
<span class="username">#{netid}</span>
</div>
>>
   | <<<script type="text/javascript">location="#{logout_url}"</script>
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

