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

function autoResize(id,count) {
	$("#Wait").hide();
	$("#IframeBox").fadeIn();
}

function applyPromoCode() {
	response = null;
	$(document).ready(function(){
		var code = jQuery.trim($("#promo_code_text").val());
		
		if (code != "") {
		  $.ajax({
		    type:"POST", 
		    url: "/bookings/promo",
		    data: {promo_code:code},
				dataType: "json"
		  })
		  .done(function(json){
		    $("#promo").empty().append(json.html);
		  })
		} else {
			window.alert("Please input a promo code");
		}
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

function carouselPause() {
	$('.carousel-indicators').find('li').bind("click", function() {
		$('.carousel').carousel('pause');
	});
}

function changeCar(id,name,dom,action) {
	$('#'+dom+'Val').val(id);
	$('#'+dom+'Html').html(name);
	$('#'+dom+'Menu').find('li').removeClass('active');
	$('#'+dom+id).addClass('active');
	if(action == 'home') {
		pushEvent('Homepage Search', 'Car', name);
	} else if(action == 'nav') {
		pushEvent('Cars Selected', name, 'Search Bar');
	} else if(action == 'cal') {
		pushEvent('Calculator', 'Car', name);
	} else if(action == 'recal') {
		pushEvent('Rescheduler', 'Car', name);
	}
}

function changeLocation(id,name,action) {
	$('#LocationVal').val(id);
	$('#LocationHtml').html(name);
	$('#LocationsMenu').find('li').removeClass('active');
	$('#Location'+id).addClass('active');
	if(action == 'home') {
		pushEvent('Homepage Search', 'Location', name);
	} else if(action == 'nav') {
		pushEvent('Locations Selected', name, 'Search Bar');
	}
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

function checkout(data) {
	$("#CheckoutWait").show();
	if(typeof(data) === 'undefined'){
		window.location = "/#{@city.name.downcase}/bookings/docreate";	
	} else {
		window.location = '/#{@city.name.downcase}/bookings/docreate?starts=' + data.starts + '&ends=' + data.ends + '&loc=' + data.loc + '&car=' + data.car;
	}
}

function checkUser() {
	if($('#UserBar').length) {
		if($('body').hasClass('body-header-new'))
			getData("/users/status", 'UserBar', 'replace', null);
		else
			getData("/users/status_old", 'UserBar', 'replace', null);
	}
}

function clearLogin() {
	$('#UserBar').popover('destroy');
}

function deltaX() {
	(function(d,w,s,l,i){
		w[l]=w[l]||[];w[l].push({xb:i,'start':new Date().getTime()});
		var x = d.createElement(s);x.async = true;
		x.src = ('https:' == d.location.protocol ? 'https://d1adj61x0fgvmc.cloudfront.net/' : 'http://s.adx.io/')+i+'/uni.js';
		var s = d.getElementsByTagName(s)[0];s.parentNode.insertBefore(x, s);
	})(document, window, 'script', 'universal_variable', '35BDU410');
}

function doBooking(carId, locId) {
	window.location = "bookings/do?car=" + carId + "&loc=" + locId;
}

function doBookingNotify(carId, locId) {
	window.location = "/#{@city.name.downcase}/bookings/do?car=" + carId + "&loc=" + locId + "&notify=true";
}

function getCookie(cname) {
	var name = cname + "=";
	var ca = document.cookie.split(';');
	for(var i=0; i<ca.length; i++) {
		var c = ca[i];
		while (c.charAt(0)==' ') c = c.substring(1);
		if (c.indexOf(name) != -1) return c.substring(name.length, c.length);
	}
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
      			} else if(divAction == 'prepend') {
      				$("#"+divId).prepend(data["html"]);
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
      $('.help').tooltip();
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

function hideCalculator() {
	$('#Overlay').toggle('explode');
}

function hideMobile() {
	$('#MobileRedirect').toggle('explode');
	getData('/device?web=1', null, null, null);
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
		endDate: d.getDate() + "/" + (d.getMonth()+1) + "/" + (d.getFullYear() - 21),
		startView: 4,
		minView: 2, 
		autoclose: true
	});
	var dropdownCheck = 0;
	$(".datetimebox").click(function() {
		var id = $(this).attr("id");
		$('#' + id + 'ValError').hide();
		$('#' + id + 'Val').removeClass('field_with_errors');
		$('#' + id + 'Val').datetimepicker('show');
		if(id.search('Start') != -1) {
			dropdownCheck = 0;
			if($('#' + id + 'Val').hasClass('starts-home')) {
				pushEvent('Homepage Search', 'Starts');
			} else if($('#' + id + 'Val').hasClass('starts-nav')) {
				pushEvent('Search Bar', 'Pickup Dropdown');
			} else if($('#' + id + 'Val').hasClass('starts-cal')) {
				pushEvent('Calculator', 'Starts', 'Tariff Page');
			} else if($('#' + id + 'Val').hasClass('starts-recal')) {
				pushEvent('Rescheduler', 'Org Starts');
			} else if($('#' + id + 'Val').hasClass('newstarts-recal')) {
				pushEvent('Rescheduler', 'New Starts');
			}
		} else if(id.search('End') != -1) {
			dropdownCheck = 1;
			var pid = id.replace('End','Start');
			if($('#' + pid + 'Val').val() != $('#' + pid + 'Val').attr('dummy-title')) {
				$('#' + id + 'Val').datetimepicker('show');
				if($('#' + id + 'Val').hasClass('ends-home')) {
					pushEvent('Homepage Search', 'Ends');
				} else if($('#' + id + 'Val').hasClass('ends-nav')) {
					pushEvent('Search Bar', 'Drop Dropdown');
				} else if($('#' + id + 'Val').hasClass('ends-cal')) {
					pushEvent('Calculator', 'Ends', 'Tariff Page');
				} else if($('#' + id + 'Val').hasClass('ends-recal')) {
					pushEvent('Rescheduler', 'Org Ends');
				} else if($('#' + id + 'Val').hasClass('newends-recal')) {
					pushEvent('Rescheduler', 'New Ends');
				}
			} else {
				// alert(id);
				$('#' + id + 'ValError').html('please select start date first');
				$('#' + id + 'ValError').show();
			}
		}
	});
	$('.datetimepicker-days').click(function(){
		if(dropdownCheck==0) {
			pushEvent('Search Bar', 'Pickup Date');
		}
		else {
			pushEvent('Search Bar', 'Drop Date');
		}
	});

	$('.datetimepicker-hours').click(function(){
		if(dropdownCheck==0) {
			pushEvent('Search Bar', 'Pickup Hour');
		}
		else {
			pushEvent('Search Bar', 'Drop Hour');
		}
	});

	$('.datetimepicker-minutes').click(function(){
		if(dropdownCheck==0) {
			pushEvent('Search Bar', 'Pickup Minute');
			dropdownCheck = 1;
		}
		else {
			pushEvent('Search Bar', 'Drop Minute');
		}
	});

	$('.datetime').datetimepicker().on('hide', function(ev) {
		if(ev.date.valueOf() < jQuery.now().valueOf()) {
			$('#' + ev.currentTarget.id).val($('#' + ev.currentTarget.id).attr('dummy-title'));
		}
	});
	$('.datetime').datetimepicker().on('changeDate', function(ev) {
		var id = ev.currentTarget.id;
		if(id.search('Start') != -1) {
			var d = ev.date;
			d = new Date(d.getTime() - 270*60000);
			var nid = id.replace('Start','End');
			$('#' + nid).datetimepicker('setStartDate', d.getFullYear() + "-" + (d.getMonth()+1) + "-" + d.getDate() + " " + d.getHours() + ":" + d.getMinutes());
			$('#' + nid).removeClass('field_with_errors');
			$('#' + nid + 'Error').hide();
			$('#' + nid).datetimepicker('show');
			$('.ends-home').datetimepicker().on('changeDate', function(ev) {pushEvent('Homepage Search', 'Ends');});
			$('.ends-nav').datetimepicker().on('changeDate', function(ev) {pushEvent('Navigation Search', 'Ends');});
		}
	});
}

function logOut(url) {
	getData(url, 'JsResponse', 'replace', null);
}

function mapZoom(map,newVal) {
	$("#ZoomMinus").removeClass('box-inactive');
	$("#ZoomMinus").addClass('box-active');
	$("#ZoomPlus").removeClass('box-inactive');
	$("#ZoomPlus").addClass('box-active');
	var minVal = 10;
	var maxVal = 16;
	if(newVal > minVal && newVal < maxVal) {
		map.setZoom(newVal);
	} else if(newVal <= minVal) {
		curVal = minVal;
		map.setZoom(minVal);
		$("#ZoomMinus").removeClass('box-active');
		$("#ZoomMinus").addClass('box-inactive');
	} else if(newVal >= maxVal) {
		curVal = maxVal;
		map.setZoom(maxVal);
		$("#ZoomPlus").removeClass('box-active');
		$("#ZoomPlus").addClass('box-inactive');
	}
	return false;
}

function newUserSessionEvent(path, category, action) {
	if(path=='/bangalore'||path=='/pune') {
		pushEvent(category, action, 'Home Page (My Account)');
	}
	else if(path=='/bookings/login') {
		pushEvent(category, action, 'Login Process');
	}
	else {
		pushEvent(category, action, 'Misc');
	}
}

function populateLocations(cityId, zoom, divId) {
	$("#"+divId+'Wait').show();
	$("#"+divId).html('');
	getData('/get_locations_map/' + cityId + '?zoom=' + zoom, divId, 'replace', divId + 'Wait');
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
      $('.help').tooltip();
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

function pushEvent(category, action, label) {
	_gaq.push(['_trackEvent', category, action, label]);
}

function showAvailability(carId, locId, avail, locName, carName) {
	$('#Avail' + carId).removeClass('yes no');
	if(avail == 1) {
		$('#Avail' + carId).text("Available");
		$('#Avail' + carId).addClass('yes');
		$("#ButtonYes" + carId).attr("onClick", "doBooking(" + carId + ", " + locId + ");");
		$("#ButtonYes" + carId).show();
		$("#ButtonNo" + carId).hide();
		$("#ButtonNotify" + carId).hide();
	} else {
		$('#Avail' + carId).text("Not Available");
		$('#Avail' + carId).addClass('no');
		$("#ButtonYes" + carId).attr("onClick", "");
		$("#ButtonYes" + carId).hide();
		$("#ButtonNotify" + carId).attr("onClick", "doBookingNotify(" + carId + ", " + locId + ");");
		$("#ButtonNotify" + carId).show();
		$("#ButtonNo" + carId).show();
	}
	$('#LocName' + carId).text(locName);
	$('#LocMenu' + carId).find('li').removeClass('active');
	$('#LocSel' + carId + locId).addClass('active');
	if($('#Timeline' + carId).html() != '') {
		showTimeline(carId, 0);
		showTimeline(carId, 0);
	}
	//pushEvent('Search', carName, 'Location');
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
	$('#NavBuffer').removeClass('nav-buffer').addClass('nav-buffer-big');
	getData('/bookings/widget', 'SHContent', 'replace' ,'SHWait');
}

function showTimeline(carId, action, carName) {
	var locId = $('#LocMenu' + carId).find('li.active').attr("id").split('LocSel' + carId)[1];
	if(action == 0) {
		if($('#Timeline' + carId).html() == '') {
			$('#TimelineWait' + carId).slideDown();
			if(carName) {
				//pushEvent('Search', carName, 'Timeline Open');
				pushEvent('Cars Selected', carName, 'Timeline Open');
			}
			getData("/bookings/timeline?car=" + carId + "&location=" + locId, 'Timeline' + carId, 'replace', null);
		} else {
			if(carName) {
				//pushEvent('Search', carName, 'Timeline Close');
				pushEvent('Cars Selected', carName, 'Timeline Close');
			}
			$('#TimelineWait' + carId).slideUp();
			$('#Timeline' + carId).slideUp();
			$('#Timeline' + carId).html('');
			$('#TimelineText' + carId).html("Show Availability");
			$('#TimelineAction' + carId).html("<div class='arrw-d'></div>");
		}
		$('#TimelineAction' + carId).tooltip('hide');
	} else if(action == 1) {
		$('#TimelineWait' + carId).slideDown();
		var num = $('#TimelineMoreNum' + carId).val();
		getData("/bookings/timeline?car=" + carId + "&location=" + locId + "&page=" + num, 'TimelineContent' + carId, 'append', null);
	} else if(action == -1) {
		$('#TimelineWait' + carId).slideDown();
		var num = $('#TimelineLessNum' + carId).val();
		getData("/bookings/timeline?car=" + carId + "&location=" + locId + "&page=" + num, 'TimelineContent' + carId, 'prepend', null);
	}
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

function trackEventsForPageScroll(isDuplicate) {
	$(window).scroll(function(){
		var bottom = $(window).height() + $(window).scrollTop();
		var height = $(document).height();
		var percentage = Math.round(100*bottom/height);

		if(isDuplicate == 0) {
			pushEvent('Home Page Scroll', 'Top');
			isDuplicate = 1;
		}
		//70% is the mark where map occupies major part of the screen - middle part of page visually
		if(percentage >= 70 && isDuplicate < 2) {
			pushEvent('Home Page Scroll', 'Middle');
			isDuplicate = 2;
		}
		else if(percentage >= 100 && isDuplicate < 3) {
			pushEvent('Home Page Scroll', 'Bottom');
			isDuplicate = 3;
		}
	});
}

function userActive() {
	$('#UserBar').popover({
		title: 'Signup',
		content: "Your account is activated, please continue.",
		placement: 'bottom'
	});
	$('#UserBar').popover('show');
	window.setTimeout(clearLogin, 3000);
}

function userLogin() {
	$('#UserBar').popover({
		title: 'Sign In',
		content: "You are now logged in, please continue.",
		placement: 'bottom'
	});
	$('#UserBar').popover('show');
	pushEvent('Sign In', 'Successful Sign-in', 'Home Page (My Account)');
	window.setTimeout(clearLogin, 3000);
}

function userLogout() {
	$('#UserBar').popover({
		title: 'Signout',
		content: "You are logged out, please continue.",
		placement: 'bottom'
	});
	$('#UserBar').popover('show');
	window.setTimeout(clearLogin, 3000);
}

function ValidateDate(inputText) {
	var dateformat = /^(0?[1-9]|[12][0-9]|3[01])[\/](0?[1-9]|1[012])[\/]\d{4}$/;
	if(inputText.value.match(dateformat)) {  
		return true;
	} else {
		return false;
	}
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

deltaX();
$('.carousel').carousel();
carouselPause();
$('.help').tooltip();
checkJail();
initializeDatePicker();
checkUser();

/* Tariff Details, FAQ, Fee and Payment Tabs */
$(function () {
	$('#tariff-header a, #faqs-tabs a, #fee-tabs a').click(function (e) {
  		e.preventDefault();
  		$(this).siblings().removeClass('active');
  		$(this).addClass('active');
  		$(this).tab('show');
  		pushEvent('Wallet', 'Wallet FAQ Pop Up (Checkout)');
	})
});


$(".clickable-row").click(function() {
	window.document.location = $(this).attr("href");
});

$('.pop').popover();

$('.safe-booking, .unsafe-booking').on('hide.bs.popover', function(){
	var title = $(this).attr('data-original-title');
	var el = $('#row'+title);
	el.removeClass('highlight');
});

$('.safe-booking, .unsafe-booking').on('show.bs.popover', function(){
	var title = $(this).attr('data-original-title');
	var el = $('#row'+title);
	el.addClass('highlight');
});

//flag to prevent bogus google analytics events
var flg = true;
$('.safe-booking, .unsafe-booking').on('show.bs.popover', function(){
	if(flg){
		pushEvent('Wallet', 'Graph Booking Icon (My Bookings)');
		flg = false;
	}
	else {
		flg = true;
	}
});

$('#resume_header').click(function(){
	$('#resume_body').slideToggle();
	return false;
});


var url = document.location.toString();
if (url.match('#')) {
	var anchor = url.split('#')[1];
	if(anchor == 'faq-42')
	{
		$('#faqs-tabs a[href=#faqs-7]').tab('show').addClass('active').siblings().removeClass('active');
	    $(document).scrollTop($('#faq-42').offset().top);
	}
}

if($('body').hasClass('body-header-new'))
{
	$(document).scroll(function(){
		if($(document).scrollTop() >= 115)
		{
			$('#HomepageForm')
				.addClass('line-bg border-b-c')
				.css({'position': 'fixed', 'z-index': 10, 'top': '96px', 'height': '40px', 'width': '100%',})
				.find('.widget-hor')
					.css({'top': '0'})
					.children().first().removeClass('bg r-5 bs-3').css({'padding': '4px 10px 4px 10px'});
		}
		else
		{
			$('#HomepageForm')
				.removeClass('line-bg border-b-c')
				.css({'position': 'relative', 'z-index': 10, 'top': '0', 'height': '40px', 'width': '100%',})
				.find('.widget-hor')
					.css({'top': '107px'})
					.children().first().addClass('bg r-5 bs-3').css({'padding': '10px'});
		}
	});
}

$('#ContinueToSite').click(function(){
	$('#MobileRedirect').remove();
	$('meta[name=viewport]').remove();
});

$('#proceedToPayment').click(function(){
	$('.tariff-details').slideUp();

	$('.payment-options').slideDown();

	return false;
});

function verifyGoDaddySSLSeal()
{
  var bgHeight = "460";
	var bgWidth = "593";
	if (document.location.hostname === "www.zoomcar.com") {
		var sealId = "Ny6EijIfOSXkAo0dlbSlYNs0ZFMtzRvqFfiLzW78jh8vlbbgLpcc7s";
	}
	else{
		var sealId = "3yCVbZLiXFziOzM9ZKtu3FP5qb8hkkipd76ehYTJzYmggPqLSbF1u4Vn";
	}
	var url = "https:\/\/seal.godaddy.com\/verifySeal?sealID=" + sealId;
	window.open(url,'SealVerfication','menubar=no,toolbar=no,personalbar=no,location=yes,status=no,resizable=yes,fullscreen=no,scrollbars=no,width=' + bgWidth + ',height=' + bgHeight);
}
// $('input.credit-card-cvv')
// 	.payment('formatCardCVC')
// 	.focus(function(){
// 	$('#credit-card-cvv-icon').fadeIn();
// })
// 	.blur(function(){
// 	$('#credit-card-cvv-icon').fadeOut();
// });
