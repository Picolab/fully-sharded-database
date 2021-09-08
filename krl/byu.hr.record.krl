ruleset byu.hr.record {
  meta {
    use module html
    use module io.picolabs.pds alias pds
    shares audio, test_audio
  }
  global {
    test_audio = function(){
      html:header("test audio")
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
    scripts = <<<script type="text/javascript">
  var host = location.origin;
  var eci = location.pathname.split("/")[2];
  var doSave = function(theForm){
    var url = host+'/c/'+eci+'/event/byu_hr_core/new_audio';
    var params = {};
    params.the_audio = theForm.the_audio.value;
    var xhr = new XMLHttpRequest();
    xhr.onload = function(){setTimeout('alert("Audio saved")',100);}
    xhr.onerror = function(){alert(xhr.responseText);}
    xhr.open('POST',url,true);
    xhr.setRequestHeader('Content-type','application/json')
    xhr.send(JSON.stringify(params));
    return false;
  }
</script>
>>
    audio = function(){
      saved_audio = pds:getData("person","audio")
      html:header("record audio",styles+scripts)
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
<li>Save your recording and then close this tab.
<form method="POST" id="the_form" onsubmit="return doSave(this)">
<button type="submit" class="hide" id="the_button">Save</button>
<input name="the_audio" id="the_audio" type="hidden">
</form>
</li>
</ol>
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
      document.getElementById('the_button').style.visibility = "visible";
    }, false);
    reader.readAsDataURL(file);
  });
</script>
>>
      + html:footer()
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
