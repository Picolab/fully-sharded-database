ruleset byu.hr.record {
  meta {
    use module html.byu alias html
    use module io.picolabs.pds alias pds
    use module io.picolabs.wrangler alias wrangler
    shares audio, test_audio
  }
  global {
    logout = function(_headers){
      ctx:query(
        wrangler:parent_eci(),
        "byu.hr.oit",
        "logout",
        {"_headers":_headers}
      )
    }
    test_audio = function(_headers){
      url = logout(_headers).extract(re#location='([^']*)'#).head()
      html:header("test audio","",url,_headers)
      + <<<audio controls src="#{pds:getData("person","audio")}"></audio>
>>
      + html:footer()
    }
    styles = <<<style type="text/css">
li { margin: 10px 0; }
audio { vertical-align: middle; }
.hide { visibility: hidden; }
</style>
>>
    scripts = function(netid){
<<<script type="text/javascript">
  var host = location.origin;
  var eci = location.pathname.split("/")[2];
  var audioSaved = function(){
    alert('Audio saved');
    location = document.referrer+'##{netid}';
  }
  var doSave = function(theForm){
    var url = host+'/c/'+eci+'/event/byu_hr_core/new_audio';
    var params = {};
    params.the_audio = theForm.the_audio.value;
    var xhr = new XMLHttpRequest();
    xhr.onload = function(){setTimeout('audioSaved()',100);}
    xhr.onerror = function(){alert(xhr.responseText);}
    xhr.open('POST',url,true);
    xhr.setRequestHeader('Content-type','application/json')
    xhr.send(JSON.stringify(params));
    return false;
  }
</script>
>>
    }
    audio = function(_headers){
      netid = html:cookies(_headers).get("netid")
      saved_audio = pds:getData("person","audio")
      url = logout(_headers).extract(re#location='([^']*)'#).head()
      html:header("record audio",styles+scripts(netid),url,_headers)
      + <<
<h1>Record audio of your name</h1>
<h2>Instructions</h2>
<ol>
<li>Make a recording of yourself pronouncing your name.
Try to be brief; a name takes only a second or two to say.
Trim empty space at the start and end of your name.
<br>
<br>
Here are some websites that allow you to do this:
<ul>
<li><a href="https://online-voice-recorder.com/">https://online-voice-recorder.com/</a></li>
<li><a href="https://www.rev.com/onlinevoicerecorder">https://www.rev.com/onlinevoicerecorder</a></li>
<li><a href="https://vocaroo.com/">https://vocaroo.com/</a></li>
</ul>
Download the recording into a file on your computer.
</li>
<li>Upload the file you just saved:
<input type="file" accept="audio/*" capture id="recorder">
<br>
File sizes:
<span id="file_size">No file chosen</span>.
<span class="hide" id="cond_display">
If the file size is more than about two hundred thousand (200,000),
please record again and/or choose a smaller file.
</span>
</li>
<li>Replay to make sure you sound okay:
<audio id="player" controls></audio>
If you don't like it, go back to step 1 and record again.
</li>
<li>Save your recording.
Either button below will return to the previous page.
<form method="POST" id="the_form" onsubmit="return doSave(this)">
<button type="submit" disabled id="the_button">Save</button>
<button onclick="location=document.referrer+'##{netid}';return false">Cancel</a>
<input name="the_audio" id="the_audio" type="hidden">
</form>
</li>
</ol>
<h2>Privacy Notice</h2>
<p>
By saving a recording of your voice saying your name,
you consent to its use by other members of the BYU community
so that they can hear how you like your name pronounced.
</p>
<p>
This recording will not be used for any other purpose.
</p>
<script type="text/javascript">
  const recorder = document.getElementById('recorder');
  const player = document.getElementById('player');
  const file_size = document.getElementById('file_size');

  recorder.addEventListener('change', function(e) {
    const file = e.target.files[0];
    //const url = URL.createObjectURL(file);
    //player.src = url;
    // let blob = await fetch(url).then(r => r.blob());
    const reader = new FileReader();
    reader.addEventListener('load', function() {
      const url = reader.result;
      player.src = url;
      file_size.innerText =
        file.size.toLocaleString()
        + '; '
        + url.length.toLocaleString();
      if (url.length > 200000) {
        document.getElementById('cond_display').classList.remove('hide');
      }
      document.getElementById('the_audio').value = url;
      document.getElementById('the_button').disabled = false;
    }, false);
    reader.readAsDataURL(file);
  });
</script>
>>
      + html:footer()
    }
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    every {
      wrangler:createChannel(
        ["record_audio"],
        {"allow":[{"domain":"byu_hr_core","name":"new_audio"}],"deny":[]},
        {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
      )
    }
  }
  rule accept_new_audio {
    select when byu_hr_core new_audio
    pre {
      the_audio = event:attr("the_audio")
    }
    if the_audio then noop()
    fired {
      raise pds event "new_data_available" attributes {
        "domain":"person","key":"audio","value":the_audio
      }
    }
  }
}
