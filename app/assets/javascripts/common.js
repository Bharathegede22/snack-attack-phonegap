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

function showModal(title,url) {
	$('#ModalContentWait').show();
	$('#ModalContent').html('');
	$('#ModalLabel').text(title);
	$('#Modal').modal('show');
	getData(url, 'ModalContent', 'replace' ,'ModalContentWait');
}

function showSearch() {
	$('#SHWait').show();
	$('#SHContent').html('');
	$('#SH').show();
	$('#NavBuffer').css('height', 95);
	getData('/search/widget', 'SHContent', 'replace' ,'SHWait');
}

function getData(complete_url,divId,divAction,divWait) {
	//checkajax = $("#AjaxActive").val();
  //if(checkajax == 1){
  //	if("undefined" != typeof(event)) event.returnValue = false;
  // return false;	
  //}
  //$("#AjaxActive").val(1);
  if(divWait) {
  	$("#"+divWait).show();
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
      }
      //$("#AjaxActive").val(0);
    }
  );
  resp.fail(
  	function(jqXHR, textStatus) {
  		if(divWait) {
      	$("#"+divWait).hide();
      }
  		//$("#AjaxActive").val(0);
  		if(jqXHR.getAllResponseHeaders()) {
	  		alert("Request failed, please try again later.");
	  	}
		}
	);
	if("undefined" != typeof(event)) event.returnValue = false;
	return false;
}

function postData(complete_url,divId,divAction,divWait,dataStr) {
	checkajax = $("#AjaxActive").val();
  if(checkajax == 1){
  	if("undefined" != typeof(event)) event.returnValue = false;
    return false;	
  }
  $("#AjaxActive").val(1);
  if(divWait) {
  	$("#"+divWait).show();
  }
  var resp = $.ajax({
  	url: complete_url, 
  	data: dataStr, 
		dataType: "json",
		type: 'POST'
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
      }
      $("#AjaxActive").val(0);
    }
  );
  resp.fail(
  	function(jqXHR, textStatus) {
  		if(divWait) {
      	$("#"+divWait).hide();
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

function ValidateDate(inputText) {
	var dateformat = /^(0?[1-9]|[12][0-9]|3[01])[\/](0?[1-9]|1[012])[\/]\d{4}$/;
	if(inputText.value.match(dateformat)) {  
		return true;
	} else {
		return false;
	}
}  

function SubmitForm(frm,url,divId){
	var frmId = frm.id;
	if($("#" + frmId.replace('Form','Submit')).length > 0 && $("#" + frmId.replace('Form','Wait')).length > 0){
		hideDiv = frmId.replace('Form','Wait');
	} else {
		hideDiv = null;
	}
  var new_url = '';
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
    	$('#' + frm.elements[i].id + 'Error').html("");
    	$('#' + frm.elements[i].id + 'Error').hide();
	    $(frm.elements[i]).removeClass('field_with_errors');
	    if($(frm.elements[i]).hasClass('validate-presence') && (frm.elements[i].value.length == 0 || frm.elements[i].value == $('#'+frm.elements[i].id).attr('dummy-title'))) {
	    	if(!failed){
			    frm.elements[i].focus();
			  }
	    	if($('#' + frm.elements[i].id + 'Error').length > 0) {
			    $('#' + frm.elements[i].id + 'Error').html("<p>can't be empty</p>");
			    $('#' + frm.elements[i].id + 'Error').show();
					$(frm.elements[i]).addClass('field_with_errors');
				} else {
					alert("Can't be empty.");
				}
				failed = true;
	    } else {
				if($(frm.elements[i]).hasClass('validate-numeric') && (frm.elements[i].value.length > 0) && (!ValidateNumeric(frm.elements[i].value))) {
					if(!failed){
		        frm.elements[i].focus();
			    }
			    if($('#' + frm.elements[i].id + 'Error').length > 0) {
					  $('#' + frm.elements[i].id + 'Error').html("<p>should be numeric</p>");
					  $('#' + frm.elements[i].id + 'Error').show();
						$(frm.elements[i]).addClass('field_with_errors');
					} else {
						alert("Should be numeric.");
					}
		      failed = true;
			  }
			  if($(frm.elements[i]).hasClass('validate-length') && (frm.elements[i].value.length > 0) && (frm.elements[i].value.length != $(frm.elements[i]).data("length"))) {
					if(!failed){
		        frm.elements[i].focus();
			    }
			    if($('#' + frm.elements[i].id + 'Error').length > 0) {
					  $('#' + frm.elements[i].id + 'Error').html("<p>need " + $(frm.elements[i]).data("length") + " characters</p>");
					  $('#' + frm.elements[i].id + 'Error').show();
						$(frm.elements[i]).addClass('field_with_errors');
					} else {
						alert("Should be of " + $(frm.elements[i]).data("length") + " characters.");
					}
		      failed = true;
			  }
			  if($(frm.elements[i]).hasClass('validate-email') && (frm.elements[i].value.length > 0) && (!ValidateEmail(frm.elements[i].value))){
				  if(!failed){
		        frm.elements[i].focus();
			    }
			    if($('#' + frm.elements[i].id + 'Error').length > 0) {
					  $('#' + frm.elements[i].id + 'Error').html("<p>is invalid</p>");
					  $('#' + frm.elements[i].id + 'Error').show();
						$(frm.elements[i]).addClass('field_with_errors');
					} else {
						alert("Email is invalid.");
					}
		      failed = true;
			  }
			  if($(frm.elements[i]).hasClass('validate-date') && (frm.elements[i].value.length > 0) && (!ValidateDate(frm.elements[i].value))){
				  if(!failed){
		        frm.elements[i].focus();
			    }
			    if($('#' + frm.elements[i].id + 'Error').length > 0) {
					  $('#' + frm.elements[i].id + 'Error').html("<p>is invalid</p>");
					  $('#' + frm.elements[i].id + 'Error').show();
						$(frm.elements[i]).addClass('field_with_errors');
					} else {
						alert("Date is invalid.");
					}
		      failed = true;
			  }
			}
    }
  }
  if(!failed){
  	$("#" + frmId.replace('Form','Submit')).hide();
    postData(url, divId, 'replace', hideDiv, new_url);
  }
  if("undefined" != typeof(event)) event.returnValue = false;
  return false;
} 

function initializeDatePicker() {
	var d = new Date(jQuery.now());
	var nd = new Date(); nd.setDate(nd.getDate() + 60);
	var mint = d.getMinutes();
 	mint = (parseInt((mint/15))*15) + 15;
  $(".datetime").datetimepicker({
		format: "dd/mm/yyyy hh:ii",
		startDate: d.getFullYear() + "-" + (d.getMonth()+1) + "-" + d.getDate() + " " + d.getHours() + ":" + mint,
		endDate: nd.getFullYear() + "-" + (nd.getMonth()+1) + "-" + nd.getDate() + " 00:00",
		startView: 2,
		autoclose: true,
		minuteStep: 15,
		todayHighlight: true
	});
	$(".dob").datetimepicker({
		format: "dd/mm/yyyy",
		endDate: d.getDate() + "/" + (d.getMonth()+1) + "/" + (d.getFullYear() - 22),
		startView: 4,
		minView: 2, 
		autoclose: true
	});
	$("#StartDate").click(function() {
		$('#StartDateValError').hide();
		$('#StartDateVal').removeClass('field_with_errors');
		$('#StartDateVal').datetimepicker('show');
	});
	$("#EndDate").click(function() {
		$('#EndDateValError').hide();
		$('#EndDateVal').removeClass('field_with_errors');
		if($('#StartDateVal').val() != $('#StartDateVal').attr('dummy-title')) {
			$('#EndDateVal').datetimepicker('show');
		} else {
			$('#EndDateValError').html('please select start date first');
			$('#EndDateValError').show();
		}
	});
	$('#StartDateVal').datetimepicker().on('hide', function(ev) {
		if(ev.date.valueOf() < jQuery.now().valueOf()) {
			$('#StartDateVal').val($('#StartDateVal').attr('dummy-title'));
		}
	});
	$('#EndDateVal').datetimepicker().on('hide', function(ev) {
		if(ev.date.valueOf() < jQuery.now().valueOf()) {
			$('#EndDateVal').val($('#EndDateVal').attr('dummy-title'));
		}
	});
	$('#StartDateVal').datetimepicker().on('changeDate', function(ev) {
		var d = ev.date;
		d = new Date(d.getTime() - 270*60000);
    $('#EndDateVal').datetimepicker('setStartDate', d.getFullYear() + "-" + (d.getMonth()+1) + "-" + d.getDate() + " " + d.getHours() + ":" + d.getMinutes());
    $('#EndDateVal').removeClass('field_with_errors');
    $('#EndDateValError').hide();
    $('#EndDateVal').datetimepicker('show');
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

function changeCar(id,name) {
	$('#CarVal').val(id);
	$('#CarHtml').html(name);
}

function changeLocation(id,name) {
	$('#LocationVal').val(id);
	$('#LocationHtml').html(name);
}

function checkUser() {
	getData("/users/status", 'UserBar', 'replace', null);
}

function logOut(url) {
	getData(url, 'JsResponse', 'replace', null);
}

function userLogin() {
	$('#UserBar').popover({
		title: 'Sign In',
		content: "You are now logged in, please continue.",
		placement: 'bottom'
	});
	$('#UserBar').popover('show');
	$('#UserBar').bind("click", function() {
		$('#UserBar').popover('destroy');
	});
}

function userLogout() {
	$('#UserBar').popover({
		title: 'Signout',
		content: "You are logged out, please continue.",
		placement: 'bottom'
	});
	$('#UserBar').popover('show');
	$('#UserBar').bind("click", function() {
		$('#UserBar').popover('destroy');
	});
}

function userActive() {
	$('#UserBar').popover({
		title: 'Signup',
		content: "Your account is activated, please continue.",
		placement: 'bottom'
	});
	$('#UserBar').popover('show');
	$('#UserBar').bind("click", function() {
		$('#UserBar').popover('destroy');
	});
}

function bindCountry() {
	$('.bind-country').bind("change", function() {
		if($(this).val() == 'IN') {
			$('.bind-to-country').show();
		} else {
			$('.bind-to-country').hide();
		}
	});
}

function socialPlugins() {
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
}

$('.carousel').carousel();
$('.help').tooltip();
checkJail();
initializeDatePicker();
checkUser();
