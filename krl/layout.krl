ruleset layout {
  meta {
    use module io.picolabs.wrangler alias wrangler
  }
  global {
    engine_ui_rid = "io.picolabs.pico-engine-ui"
    max = function(x,x_max){
      x > x_max => x_max | x
    }
  }
  rule setup_layout {
    select when layout preview_needed
    foreach wrangler:children() setting(child,index)
    pre {
      uiECI = ctx:query(child{"eci"},engine_ui_rid,"uiECI")
      row = math:floor(index / 50)
      col = index % 50
      x_offset = (col*25+100).max(1200)
      y_offset = (row*50+100).max(600)
    }
    every {
      send_directive("layout",{
        "index":index,
        "name":child{"name"},
        "child":uiECI,
        "x":x_offset,
        "y":y_offset,
      })
      event:send({
        "eci":uiECI,"domain":"engine_ui","type":"box",
        "attrs":{
          "x":x_offset,
          "y":y_offset,
        }
      })
    }
  }
}
