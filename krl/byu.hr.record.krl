ruleset byu.hr.record {
  meta {
    name "audio"
    use module html.byu alias html
    use module io.picolabs.pds alias pds
    use module io.picolabs.wrangler alias wrangler
    shares audio, test_audio, export_audio
  }
  global {
    export_audio = function(){
      netid = wrangler:name()
      netid + chr(9) + pds:getData("person","audio")
    }
    test_audio = function(_headers){
      html:header("test audio","",null,null,_headers)
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
  var actionDone = function(theAction){
    alert('Audio '+theAction);
    location = document.referrer+'##{netid}';
  }
  var doAction = function(theForm,theAction){
    var host = location.origin;
    var eci = location.pathname.split("/")[2];
    var url = host+'/c/'+eci+'/event/byu_hr_core/new_audio';
    var form_data = "the_audio=" + encodeURIComponent(theForm.the_audio.value);
    var xhr = new XMLHttpRequest();
    xhr.onload = function(){setTimeout(actionDone,100,theAction);}
    xhr.onerror = function(){alert(xhr.responseText);}
    xhr.open('POST',url,true);
    xhr.setRequestHeader('Content-type', 'application/x-www-form-urlencoded');
    xhr.send(form_data);
    return false;
  }
</script>
>>
    }
    audio = function(_headers){
      netid = html:cookies(_headers).get("netid")
      saved_audio = pds:getData("person","audio")
      url = meta:host.extract(re#(.+):\d+#).head()
      html:header("record audio",styles+scripts(netid),null,null,_headers)
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
<li><a href="https://online-voice-recorder.com/" target="_blank">https://online-voice-recorder.com/</a></li>
<li><a href="https://www.rev.com/onlinevoicerecorder" target="_blank">https://www.rev.com/onlinevoicerecorder</a></li>
<li><a href="https://vocaroo.com/" target="_blank">https://vocaroo.com/</a></li>
</ul>
Download the recording into a file on your computer.
</li>
<li>Upload the file you just saved:
<input type="file" accept="audio/*" id="recorder" onclick="this.value=null">
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
Buttons below will return to the previous page.
<form method="POST" onsubmit="return doAction(this,'saved')">
<button type="submit" disabled id="the_button">Save</button>
<button onclick="location=document.referrer+'##{netid}';return false">Cancel</a>
<input name="the_audio" id="the_audio" type="hidden">
</form>
</li>
<li>If you wish, you may return to this page and delete your recording.
<form method="POST" onsubmit="if(confirm('If you continue, your audio recording will be removed. This cannot be undone.')){return doAction(this,'removed');}">
<button type="submit"#{saved_audio => "" | " disabled"}>Delete audio</button>
<input name="the_audio" type="hidden" value="">
</form>
</li>
</ol>
<h2>Export</h2>
#{ saved_audio => <<<form method="GET" action="#{meta:host}/sky/cloud/#{meta:eci}/#{meta:rid}/export_audio.txt">
<button type="submit">Export audio</button>
</form>
>> | ""}<h2>Privacy Notice</h2>
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
    fired {
      raise byu_hr_record event "channel_created"
    }
  }
  rule keepChannelsClean {
    select when byu_hr_record channel_created
    foreach wrangler:channels(["record_audio"]).reverse().tail() setting(chan)
    wrangler:deleteChannel(chan.get("id"))
  }
  rule acceptNewAudio {
    select when byu_hr_core new_audio
    pre {
      the_audio = event:attr("the_audio")
    }
    if the_audio then noop()
    fired {
      raise pds event "new_data_available" attributes {
        "domain":"person","key":"audio","value":the_audio
      }
    } else {
      raise pds event "data_not_pertinent" attributes {
        "domain":"person","key":"audio"
      }
    }
  }
}
