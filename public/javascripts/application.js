// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function alert_connection_error(request) {
    rep = "Пожалуйста, повторите попытку позже.";
    switch(request.status) {
    case 404:
        alert("Ошибка при работе с сервером (не получилось найти требуемый объект). " + rep);
        break;
    case 500:
        alert("Ошибка при работе с сервером. " + rep);
        break;
    default:
        alert("Не удалось связаться с олимпиадным сервером (ошибка " + request.status + "). " + rep);
    }
}

function $SEL() {
  return $A(arguments).map(function(expression) {
    return expression.strip().split(/\s+/).inject(null, function(results, expr) {
      if (null == results) {
        if (match = expr.match(/^#([a-z0-9_-]+)$/)) {
          return [$(match[1])];
        }
        results = [null];
      }
      var selector = new Selector(expr);
      return results.map(selector.findElements.bind(selector)).flatten();
    });
  }).flatten();
}

Object.extend(Element, {
    makeVisible: function() {
        for (var i = 0; i < arguments.length; i++) {
          var element = $(arguments[i]);
          element.style.visibility = 'visible';
        }
    },
    
    makeInvisible: function() {
        for (var i = 0; i < arguments.length; i++) {
          var element = $(arguments[i]);
          element.style.visibility = 'hidden';
        }
    }
});

var AppendableSelect = Class.create();
Object.extend(AppendableSelect.prototype, {
    initialize: function(element, selector) {
      this.element = $(element);
      this.selector = selector;
      Event.observe(this.element, 'change', this.onChange.bind(this));
      on_load(this.onLoad.bind(this));
    },
    
    onLoad: function() {
      this.onChange();
    },
    
    onChange: function() {
      var v = (this.element.value - 0);
      var showing = (v == 0);
      $SEL(this.selector).each(function(el) {
        if (showing)
            Element.show(el);
        else
            Element.hide(el);
      });
      //this.listVisibility.each(showing ? Element.makeVisible : Element.makeHidden);
    }
});

function showOrHideUniversityInfo () {
	var id = $('team[university_id]');
	var v = (id.value - 0);
	sp1.style.visibility = (v == 0 ? "visible" : "hidden");
	if (v != -1) {
		if (id.childNodes && id.childNodes [0] && -1 == id.childNodes [0].value) {
			id.removeChild (id.childNodes [0]);
		} else if (id.children && id.children [0] && -1 == id.children [0].value) {
			id.removeChild (id.children [0]);
		}
	}
}


