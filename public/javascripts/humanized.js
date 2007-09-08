
var Humanized = {
    opacity: 0.9,
    msg_id: 'humanized_msg',
    top_offset: 100,
    format: "<div class='r2'></div><div class='r1'></div><p>%s</p><div class='r1'></div><div class='r2'></div>",
    //format: "<p>%s</p>",
    msgFadeEffect: null,
    currMsgContent: null
};

Humanized._hideMessage = function(){
    /* Hides the message via fade animation. It won't attempt to hide a 
       message if it is currently being hidden. */
   if (!Element.visible(Humanized.msg_id)) return;
   if (Element.getOpacity(Humanized.msg_id) >= Humanized.opacity )
        Effect.Fade(Humanized.msg_id, {duration: 0.5});
}

Humanized.hideMessage = function(){
	setTimeout(Humanized._hideMessage, 250);
}

Humanized._showMessage = function( message ){
  /* A private method which shows the transparent message. Doesn't handle
     concurrency. */
  var el = $( Humanized.msg_id );
  if (typeof(el) == "undefined") {
      setTimeout(function() {Humanized._showMessage(message);}, 50);
      return;
  }
  el.innerHTML = Humanized.format.replace(/%s/, message);
  Humanized.currMsgContent = message;
  Element.show( Humanized.msg_id );

  Position.prepare();
  
  var msg = $(Humanized.msg_id);
  msg.style.position = "absolute";
  msg.style.top = (Position.deltaY + Humanized.top_offset) + "px";
  Element.setOpacity( msg, Humanized.opacity);
}

Humanized.showMessage = function( message ){
  /* Shows the message: handles the cases where a second message is attempted
     to be displayed before the first is done. */
  if (Humanized.msgFadeEffect != null && Humanized.msgFadeEffect.state != "finished"){
    // If the same message is displayed while the current message is being
    // faded away, it doesn't need to be shown again. This handles the case
    // where the user takes an action to dismiss a message and inadvertantly
    // causes the message to be shown again.
    if (Humanized.currMsgContent != message ){
      Humanized.msgFadeEffect.options.afterFinish = function(){ _showMessage(message) }
    }
  }
  else{
    /* This is needed for IE: otherwise after a click, a mousemove event would
       cause the message to fade away instantly. */
    setTimeout(function() {Humanized._showMessage(message);}, 50);
  }
}

//----------------------------------------------------------------------------
// Initialization
//----------------------------------------------------------------------------

Humanized.initTransparentMessage = function(){
    /* Adds the message div to the page and sets up its event handlers. */
    var msg = document.createElement("DIV");
    msg.className = Humanized.msg_id;
    msg.id = Humanized.msg_id;

    var hideEvents = ["mousedown", "keydown", "mousemove"];
    for(i in hideEvents){
        Event.observe( document.body, hideEvents[i], Humanized.hideMessage );
    }

    Element.hide( msg )
    document.body.appendChild( msg )
}

Humanized.installTransparentMessage = function() {
    var prev = window.onload;
    window.onload = function() {
        Humanized.initTransparentMessage();
        if (prev != null)
            prev();
    }
}

Humanized.installTransparentMessage();
