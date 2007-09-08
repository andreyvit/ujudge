
function safe(f) {
	return f();
	try {
		return f();
	} catch(e) {
	    var s = "";
	    for(i in e) {
	      var v = e[i];
	      var x;
	      try {
	      	x = v();
	      } catch(z) {
	        x = v;
	      }
	      s += "\n" + i + " = " + x;
	    }
		alert("Error " + e.name + "\n" + e.message + "\n" + s);
	}
}

var uJudge = Class.create();

uJudge.assertionError = function(message) {
    uJudge.error("Assertion failed, message: ")
};

uJudge.error = function(message) {
    try {
        var type = (arguments[1] || "Error");
        var msg = "[uJudge " + type + "] " + message;
        if (window.console) {
            // Safari JavaScript debug log
            alert(message);
            window.console.log(msg);
            try {
                if (typeof(Humanized) != "undefined")
                    Humanized.showMessage("uJudge " + type + " logged");
            } catch (e) {
            }
        } else {
            alert(msg);
        }
    } catch (e) {
        alert("uJudge Inner Error: " + e.message);
    }
};

uJudge.log = function(message) {
    var msg = "[uJudge] " + message;
    if (window.console) {
        window.console.log(msg);
        if (typeof(Humanized) != "undefined")
            Humanized.showMessage(message);
    } else {
        if (typeof(Humanized) != "undefined")
            Humanized.showMessage(message);
        else
            alert(msg);
    }
};

uJudge.safeExec = function(func) {
    try {
        func();
    } catch (e) {
        uJudge.error(e.message, "Exception");
    }
};

Function.prototype.safe = function() {
    var __func = this;
    return function() {
        try {
            __func.apply(this, arguments);
        } catch (e) {
            uJudge.error(e.message, "Exception");
        }
    }
};

uJudge.Editors = {};

uJudge.Editors.Table = Class.create();

uJudge.Editors.Table.prototype.initialize = function(tableId) {
    this.tableId = tableId;
    this.editorTypes = {};
    this.rowIdToActiveEditor = {};
    this.observedCells = [];

    this.table = $(this.tableId);
    if (this.table == null)
        return uJudge.assertionError("Table with id " + this.tableId + " not found.");
}

uJudge.Editors.Table.prototype.registerEditorType = function(editorType, generatorFunction) {
    this.editorTypes[editorType] = generatorFunction;
}

uJudge.Editors.Table.prototype.registerEditorTypes = function(hash) {
    for (key in hash)
        this.registerEditorType(key, hash[key]);
}

uJudge.Editors.Table.prototype.install = function() {
    var self = this;
	$A(document.getElementsByClassName('editable-cell', this.table)).each(function(el) {
		var editorType = el.getAttribute("editor");
		if (editorType == null || editorType.length == 0)
			return;
		self.installEditor(el, editorType);
	});
}

uJudge.Editors.Table.prototype.installEditor = function(cell, editorType) {
	var startEditor = this.editorTypes[editorType];
	if (startEditor == null)
		return uJudge.assertionError("Unknown editor type: " + editorType);
    this.observedCells.push(cell);
    var table = this;
	Event.observe(cell, 'click', function(arg) {
		var e = arg || window.event;
		safe(function() {
			startEditor(table, cell, editorType);
			Event.stop(e);
		});
	}, true);
}

uJudge.Editors.Table.prototype.closeEditorByNode = function(node) {
	var row = Element.ancestor($(node), "TR");
    var editor = this.getActiveEditorByRowId(row);
    if (editor != null) 
    	editor.close();
}

uJudge.Editors.Table.prototype.getActiveEditorByRowId = function(row_id) {
    if (row_id.id)
        row_id = row_id.id;
	var r = this.rowIdToActiveEditor[row_id];
	if (r == null)
	    ;
	return r;
}

uJudge.Editors.Editor = Class.create();

uJudge.Editors.Editor.prototype.initialize = function(table, cell, type, colspan, editorClass, cellClass, url) {
    this.table = table;
	this.cell = Element.ancestor(cell, "TD");
	this.row = Element.ancestor(this.cell, "TR");
	this.type = type;
	var prevEditor = table.getActiveEditorByRowId(this.row.id);
	if (prevEditor) {
		prevEditor.prepareClose();
		if (prevEditor.cell == this.cell) {
			prevEditor.close();
			return;
		}
	}

	this.editorRow = document.createElement("TR");
	this.editorRow.id = this.row.id + "_editor";
	this.row.parentNode.insertBefore(this.editorRow, this.row.nextSibling);
	this.editorCell = document.createElement("TD");
	this.editorCell.colSpan = colspan;
	this.editorCell.id = this.row.id + "_editor_body";
	this.editorRow.appendChild(this.editorCell);
	this.editorRow.style.display = "none";
	this.editorRow.className = editorClass;
	this.cellClass = cellClass;
	
	this.spinner = document.createElement("IMG");
	var editor = this;
	$A(this.cell.getElementsByTagName("SPAN")).each(function(el) {
		var child = el.firstChild;
		if (child != null && child.nodeType == 3) // TEXT_NODE
			if (child.nodeValue == " »") {
				editor.textChild = child;
				editor.textParent = el;
				child.parentNode.removeChild(child);
			}
	});
	if (this.textParent) 
		this.textCloseChild = document.createTextNode(" «");
	this.cell.appendChild(this.spinner);
	this.spinner.src = "/images/indicator-small.gif";
/*	this.spinner.setAttribute("style", "position: absolute; left: 50%;");*/

	new Ajax.Request(url, {method: 'get', onComplete: function(request, object) {
		safe(function() {
		    editor.onShow(prevEditor);
		});
    	try {
    		eval(request.responseText);
    	} catch (e) {
    	   alert(e);
    	}
	}});
}

uJudge.Editors.Editor.prototype.onShow = function(prevEditor) {
	if (this.textParent)
		this.textParent.appendChild(this.textCloseChild);
	Element.remove(this.spinner);
	if (prevEditor)
		prevEditor.close();
	this.editorRow.style.display = "";
	Element.addClassName(this.cell, this.cellClass);
	this.table.rowIdToActiveEditor[this.row.id] = this;
}

uJudge.Editors.Editor.prototype.close = function() {
	Element.removeClassName(this.cell, this.cellClass);
	Element.remove(this.editorRow);
	if (this.textParent) {
		Element.remove(this.textCloseChild);
		this.textParent.appendChild(this.textChild);
	}
	this.table.rowIdToActiveEditor[this.row.id] = null;
}

uJudge.Editors.Editor.prototype.prepareClose = function(node) {
	// TODO: check for unsaved changes
}

Element.ancestor = function(node, tagName) {
	tagName = tagName.toUpperCase();
	while (node != null && (node.nodeType != 1 || node.tagName.toUpperCase() != tagName)) // ELEMENT_NODE
		node = node.parentNode;
	return node;
}

