jQuery.fn.center = function(){
	if(window.fixedSupported) {
		this.css("position","fixed");
	  this.css("top", (($(window).height() - this.outerHeight()) / 2) + "px");
  	this.css("left", (($(window).width() - this.outerWidth()) / 2) + "px");
	} else {
		this.css("position","absolute");
	  this.css("top", (($(window).height() - this.outerHeight()) / 2) + $(window).scrollTop() + "px");
  	this.css("left", (($(window).width() - this.outerWidth()) / 2) + $(window).scrollLeft() + "px");
	}
  return this;
}

jQuery.fn.jail = function() {
	var cacheSrc = this.attr("data-background");
	if(cacheSrc && cacheSrc != '') {
		this.removeAttr('data-src');
		this.css("background","url(" + cacheSrc + ") no-repeat center top;");
	}
  return this;
}

function checkJail() {
	$('.lazy').each(function() {
		var cacheSrc = $(this).attr("data-background");
		if(cacheSrc && cacheSrc != '') {
			$(this).removeAttr('data-src');
			$(this).css("background","url(" + cacheSrc + ") no-repeat center top");
		}
	});
}

function autoResize(id,count) {
	$("#Wait").hide();
	$("#IframeBox").fadeIn();
}

function showModal() {
	$("#Calculator").hide();
  h = $(document).height();
  w = $(document).width();
  $("#Overlay").height(h);
  $("#Overlay").width(w);
  $("#Overlay").fadeIn();
  $("#Calculator").slideDown();
}

function getData(complete_url,divId,divAction,divWait) {
	checkajax = $("#AjaxActive").val();
  if(checkajax == 1){
  	if("undefined" != typeof(event)) event.returnValue = false;
    return false;	
  }
  $("#AjaxActive").val(1);
  if(divWait) {
  	$("#"+divWait).show();
  } else {
		showOverlay();
	}
  var resp = $.ajax({
  	url: complete_url, 
		dataType: "json"
	});
	resp.done(
    function(data){
      if(data["alert"]) {
        alert(data["alert"]);
      } else {
      	if(divId) {
      		if(divAction) {
      			if(divAction == 'append') {
      				$("#"+divId).append(data["html"]);
      			} else {
      				$("#"+divId).html(data["html"]);
      			}
      		} else {
				    $("#"+divId).html(data["html"]);
				  }
			  }
      }
      if(divWait) {
      	$("#"+divWait).hide();
      } else {
	      $("#Wait").hide();
	    }
      $("#AjaxActive").val(0);
    }
  );
  resp.fail(
  	function(jqXHR, textStatus) {
  		if(divWait) {
      	$("#"+divWait).hide();
      } else {
	      $("#Wait").hide();
	    }
  		$("#AjaxActive").val(0);
  		if(jqXHR.getAllResponseHeaders()) {
	  		alert("Request failed, please try again later.");
	  	}
		}
	);
	if("undefined" != typeof(event)) event.returnValue = false;
	return false;
}

function ValidateEmail(email){
  var re = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
  if (! email.match(re)) {
    return false;
  }
  return true;
}

function ValidateNumeric(numValue){
	if (!numValue.toString().match(/^[-]?\d*\.?\d*$/)){
		return false;
	}
	return true;
}

function SubmitForm(frm,url,divId){
	var frmId = frm.id;
	if($("#" + frmId.replace('Form','Submit')).length > 0 && $("#" + frmId.replace('Form','Wait')).length > 0){
		hideDiv = frmId.replace('Form','Wait');
	} else {
		hideDiv = null;
	}
  var new_url = url;
  var failed = false;
	for(var i = 0; i < frm.elements.length; i++) {
    if(frm.elements[i].name != 'commit') {
    	if($(frm.elements[i]).prop("type") == 'checkbox') {
    		if($(frm.elements[i]).prop("checked")) {
		    	new_url += "&" + frm.elements[i].name + "=" + frm.elements[i].value;
		    }
		  } else {
		  	new_url += "&" + frm.elements[i].name + "=" + frm.elements[i].value;
		  }
    	$('#' + frm.elements[i].id + 'Error').text("");
	    $(frm.elements[i]).removeClass('field_with_errors');
	    if($(frm.elements[i]).hasClass('validate-presence') && (frm.elements[i].value.length == 0)) {
	    	if(!failed){
			    frm.elements[i].focus();
			  }
	    	if($('#' + frm.elements[i].id + 'Error').length > 0) {
			    $('#' + frm.elements[i].id + 'Error').text("can't be empty");
					$(frm.elements[i]).addClass('field_with_errors');
				} else {
					alert("Can't be empty.");
				}
				failed = true;
	    } else {
				if($(frm.elements[i]).hasClass('validate-numeric') && (!ValidateNumeric(frm.elements[i].value))) {
					if(!failed){
		        frm.elements[i].focus();
			    }
			    if($('#' + frm.elements[i].id + 'Error').length > 0) {
					  $('#' + frm.elements[i].id + 'Error').text("should be numeric");
						$(frm.elements[i]).addClass('field_with_errors');
					} else {
						alert("Should be numeric.");
					}
		      failed = true;
			  }
			  if($(frm.elements[i]).hasClass('validate-length') && (frm.elements[i].value.length != $(frm.elements[i]).data("length"))) {
					if(!failed){
		        frm.elements[i].focus();
			    }
			    if($('#' + frm.elements[i].id + 'Error').length > 0) {
					  $('#' + frm.elements[i].id + 'Error').text("need " + $(frm.elements[i]).data("length") + " characters");
						$(frm.elements[i]).addClass('field_with_errors');
					} else {
						alert("Should be of " + $(frm.elements[i]).data("length") + " characters.");
					}
		      failed = true;
			  }
			  if($(frm.elements[i]).hasClass('validate-email') && (!ValidateEmail(frm.elements[i].value))){
				  if(!failed){
		        frm.elements[i].focus();
			    }
			    if($('#' + frm.elements[i].id + 'Error').length > 0) {
					  $('#' + frm.elements[i].id + 'Error').text("is invalid");
						$(frm.elements[i]).addClass('field_with_errors');
					} else {
						alert("Email is invalid.");
					}
		      failed = true;
			  }
			}
    }
  }
  if(!failed){
  	$("#" + frmId.replace('Form','Submit')).hide();
    getData(new_url,divId,'replace',hideDiv);
  }
  if("undefined" != typeof(event)) event.returnValue = false;
  return false;
} 

function initializeDatePicker() {
	var d = new Date(jQuery.now());
	var mint = d.getMinutes();
  mint = (parseInt((mint/15))*15) + 15;
	$('.datepicker').pickadate({
		format: 'dd/mm/yyyy',
		formatSubmit: 'dd/mm/yyyy',
		min: [d.getFullYear(), d.getMonth(), d.getDate()],
		max: 60,
		onSet: function(event) {
			initializeTimePicker(this.$node.attr('id'));
		}
	});
}

function initializeTimePicker(dateId) {
	var d = new Date(jQuery.now());
	var mint = d.getMinutes();
	var datePick = $("#" + dateId);
	if (datePick.val() == (d.getDate() + "/" + (d.getMonth()+1) + "/" + d.getFullYear())) {
  	mint = [d.getHours(), (parseInt((mint/15))*15) + 15];
  } else {
  	mint = [0, 0];
  }
	var timePick = $("#" + dateId.replace('Date','Time')).pickatime({
		format: 'hh:i A',
		formatSubmit: 'HH:i',
		interval: 15,
		min: mint,
	});
}

function initializeBubbles() {
	$('#BubbleAllIn').qtip({
		position: {
			my: 'bottom left', 
			target: 'mouse',
			adjust: { x: 10, y: -10 }
		},
		style: {
			classes: 'qtip-dark'
		},
		content: {
			title: 'No Hidden Costs',
			text: 'Here at Zoom, you will get what you pay for. Below items are standard in all our cars.'
    }
	});
	$('#BubbleFuel').qtip({
		position: {
			my: 'bottom left', 
			target: 'mouse',
			adjust: { x: 10, y: -10 }
		},
		style: {
			classes: 'qtip-dark'
		},
		content: {
			title: 'Fuel is Ours',
			text: 'All Zoom reservations comes with unlimited fuel as part of the tariff. If you need more fuel, just fill up the tank, keep the receipt and <b><u><i>we will refund the amount!</i></u></b>.'
    }
	});
	$('#BubbleInsurance').qtip({
		position: {
			my: 'bottom left', 
			target: 'mouse',
			adjust: { x: 10, y: -10 }
		},
		style: {
			classes: 'qtip-dark'
		},
		content: {
			title: "No Worries, You're All Covered",
			text: 'All Zoom reservations are covered with full comprehensive insurance, as long as a Zoom member is driving the car. <b><u><i>Maximum liability</i></u> for any damage for a Zoom member <u><i>is Rs.5000</i></u></b>.'
    }
	});
	$('#BubbleTaxes').qtip({
		position: {
			my: 'bottom left', 
			target: 'mouse',
			adjust: { x: 10, y: -10 }
		},
		style: {
			classes: 'qtip-dark'
		},
		content: {
			title: 'We Get Govt. Off Your Back',
			text: 'Tariff includes all taxes, except the relevant tolls/taxes one has to pay while visiting another state.'
    }
	});
	$('#BubbleNav').qtip({
		position: {
			my: 'bottom right', 
			target: 'mouse',
			adjust: { x: 10, y: -10 }
		},
		style: {
			classes: 'qtip-dark'
		},
		content: {
			title: 'Zip Zap Zoom',
			text: 'All Zoom cars are fitted with a 3G enabled tablet to guide you on your journey.'
    }
	});
	$('#BubbleDeposit').qtip({
		position: {
			my: 'bottom right', 
			target: 'mouse',
			adjust: { x: 10, y: -10 }
		},
		style: {
			classes: 'qtip-dark'
		},
		content: {
			title: 'In You We Trust',
			text: 'The start of our relationship is not with a bag of money. Just pay the rental using your credit/debit card and you are good to zoom.'
    }
	});
}

function showCalculator(action) {
	if (action == 'tariff') {
		_gaq.push(['_trackEvent', 'Calculator', 'Open']);
	} else {
		_gaq.push(['_trackEvent', 'Rescheduler', 'Open']);
	}
	$('#CalculatorContentWait').show();
	$('#CalculatorContent').html('');
	showModal();
	getData("/showcal/" + action, 'CalculatorContent', 'replace' ,'CalculatorContentWait');
}

function hideCalculator() {
	$('#Overlay').toggle('explode');
}

(function(d, s, id) {
  var js, fjs = d.getElementsByTagName(s)[0];
  if (d.getElementById(id)) return;
  js = d.createElement(s); js.id = id;
  js.src = "//connect.facebook.net/en_US/all.js#xfbml=1&appId=196733960374479";
  fjs.parentNode.insertBefore(js, fjs);
}(document, 'script', 'facebook-jssdk'));

(function() {
  var po = document.createElement('script'); po.type = 'text/javascript'; po.async = true;
  po.src = 'https://apis.google.com/js/plusone.js';
  var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(po, s);
})();

(function(d,s,id){var js,fjs=d.getElementsByTagName(s)[0];if(!d.getElementById(id)){js=d.createElement(s);js.id=id;js.src="//platform.twitter.com/widgets.js";fjs.parentNode.insertBefore(js,fjs);}}(document,"script","twitter-wjs"));

$("#CalculatorButton").fadeIn();
initializeDatePicker();
