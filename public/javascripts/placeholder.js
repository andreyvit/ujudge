/* Adapted from http://www.artlebedev.ru/svalka/InputPlaceholder.js, v 0.1c */

function InputPlaceholder (input, value, cssEmpty)
{
	var thisCopy = this
	
	this.Input = input
	this.Value = value
	this.SaveOriginal = (input.value == value)
	this.CssFilled = this.Input.className;
	this.CssEmpty = cssEmpty

	this.setupEvent (this.Input, 'focus', function() {return thisCopy.onFocus()})
	this.setupEvent (this.Input, 'blur',  function() {return thisCopy.onBlur()})
	this.setupEvent (this.Input, 'keydown', function() {return thisCopy.onKeyDown()})

	if (input.value == '') this.onBlur();

	return this
}

InputPlaceholder.prototype.setupEvent = function (elem, eventType, handler)
{
	if (elem.attachEvent)
	{
		elem.attachEvent ('on' + eventType, handler)
	}

	if (elem.addEventListener)
	{
		elem.addEventListener (eventType, handler, false)
	}
}

InputPlaceholder.prototype.onFocus = function()
{
	if (!this.SaveOriginal &&  this.Input.value == this.Value)
	{
		this.Input.value = ''
	}
	else
	{
			this.Input.className = ''
	}
}

InputPlaceholder.prototype.onKeyDown = function()
{
	this.Input.className = ''
}

InputPlaceholder.prototype.onBlur = function()
{
	if (this.Input.value == '' || this.Input.value == this.Value)
	{
		this.Input.value = this.Value
		this.Input.className = this.CssEmpty
	}
	else
	{
		this.Input.className = this.CssFilled
	}
}

function activatePlaceholders() {
    /* if (navigator.userAgent.toLowerCase().indexOf("safari") > 0) return false; */
    var inputs = document.getElementsByTagName("input");
    for (var i=0;i<inputs.length;i++) {
        if (inputs[i].getAttribute("type") == "text") {
            var placeholderText = inputs[i].getAttribute("placeholder");
            if (placeholderText && placeholderText.length > 0) {
                var placeholderClass = inputs[i].getAttribute("placeholder-class");
                new InputPlaceholder(inputs[i], placeholderText, placeholderClass);
            }
        }
    }
}

var prev = window.onload;
window.onload = function() {
    if (prev != null)
        prev();
    activatePlaceholders();
}
