//= require jquery
//= require jquery_ujs
//= require jquery.cookie
//= require jquery.hoverIntent
//= require jquery.cluetip
//= require jquery.scrollable
//= require facebox
//= require date
//= require twitter/bootstrap
//= require twitter/bootstrap/bootstrap-tab
//= require twitter/bootstrap/bootstrap-tooltip
//= require twitter/bootstrap/bootstrap-dropdown
//= require twitter/bootstrap/bootstrap-datepicker
//= require travels
//= require_self

var at = '';// facebook access_token variable for API
$(document).ready(function() {

  $('a[rel*=facebox]').facebox();// init facebox
  $('a').tooltip({placement: 'bottom'});
  $('.dropdown-toggle').dropdown();
  $(document).bind('loading.facebox', function() {
    $('.dropdown-toggle').parent().removeClass('open');
  });
  $('#trip_tabs a').click(function (e) {
    e.preventDefault(); $(this).tab('show');
    $('#countries li').show();
  });

  $('.ac').click(function() {
    $('#'+$(this).attr('id').replace(/^a/, '')).show();
    $('.'+$(this).attr('id')).hide(); $(this).hide();
  });

  //$(".grouped").scrollable({circular: false, mousewheel: true});
  initScrollable('.photos, .photos-messages', 3);

  /* if user signed in */
  if ($.cookie("at") != null) {
    at = $.cookie("at");
    var sql_app_users = 'select uid, name from user where uid in (select uid2 from friend where uid1=me()) and is_app_user=1';
  } // end of signed user code
  else {
    var sql_app_users = 'select uid, name from user where uid in ('+some_fb_uids()+')';
  }


 fbEnsureInit(function() {
  FB.api({
    // get user's friends for sidebar
    method: 'fql.query',
    access_token: at,
    query: sql_app_users // FQL
  }, function(response) {
    var exclude_ids = [];
    $.each(response, function(i, f) { // for each friend
      // work with result
      exclude_ids.push(f['uid']);
      // url of picture and picture tag
      var url = 'https://graph.facebook.com/'+f['uid']+'/picture';
      var atr = 'class="i'+f['uid']+' tip" rel="/friend/facebook/'+f['uid']+'"';
      var img = '<img src="'+url+'" title="'+f['name']+'" '+atr+'/>';
      var link = '<a href="/user/'+f['uid']+'">'+img+'</a>';
      // add image to its place
      $('#travel_buddy_friends').append(link);
    });
    $('.tip').cluetip({ cluetipClass: 'rounded', hoverIntent: true });
  });
 });

});

/* use when something have to be done after fb api init */
function fbEnsureInit(callback) {
  if (!window.fbApiInit) {
    setTimeout(function() {fbEnsureInit(callback);}, 50);
  } else {
    if (callback) callback();
  }
};

function inviteOnFacebook(_msg) {
  FB.ui({
    method: 'apprequests',
    access_token: at,
    display: 'popup',
    filters: ['app_non_users'],
    message: _msg //'<%= "#{current_user.name} #{t('invitation_text')}" %>'
  }, function(response){
      $('#messages').html('');
      if (!response || response == null) {
        $('#messages').append(
          $('<div class="alert alert-notice"><a class="close" data-dismiss="alert">×</a>No invitation sent.</div>')
        ).hide().fadeIn(500);
      } else {
        $('#messages').append(
          $('<div class="alert alert-success"><a class="close" data-dismiss="alert">×</a>Thank you for inviting your friends.</div>')
        ).hide().fadeIn(500);
      }
  });
};

/* check status on facebook and do something */
function loginStatus() {
  FB.getLoginStatus(function(response) {
    if (response.status === 'connected') {
    // the user is logged in and has authenticated your
    // app, and response.authResponse supplies
    // the user's ID, a valid access token, a signed
    // request, and the time the access token
    // and signed request each expire
    } else if (response.status === 'not_authorized') {
      /*FB.login(function(response) {
        if (response.authResponse) {
          location = '/auth/facebook';
          location.href = '/auth/facebook';
        }
      });*/
    } else {
    // the user isn't logged in to Facebook.
    }
  });
};

/* wall post wrapper to view in facebox */
function shareWithFacebookOnFacebox(_name, _caption, _desc, _link, _pic, _callback) {
  $('#fb_foot').html('<img src="/img/wait.gif" alt="in process" />');
  shareWithFacebook(_name, _caption, _desc, _link, _pic);
  //jQuery(document).trigger('close.facebox');
  return false;
};

/* Facebook dialog for Wall post */
function shareWithFacebook(_name, _caption, _desc, _link, _pic, _callback) {
  FB.api('/photos', 'post', {
    access_token: at,
    message: _caption,
    url: _pic
  }, function(response){
    if (!response || response.error) {
        alert('Error occured');
        dbg(response);
    } else {
        _callback;
        jQuery(document).trigger('close.facebox');
    }
  });
  return false;
};

/* heat map init - called in /main/index view */
function initHeatmap(heat) {
  $('#heatmap').vectorMap({
      color: jvm_color,
      backgroundColor: jvm_backgroundColor,
      values: heat,
      scaleColors: jvm_scaleColors,
      normalizeFunction: 'polynomial',
      hoverOpacity: 0.7,
      hoverColor: false,
      onRegionClick: function(event, code) {
        if (at.length <= 0) {
          window.location = '/signin';
          window.location.href = '/signin';
        }
      },
      onLabelShow: function(event, label, code){
        var people = [], ptext = '', temp_text;
        if ($('#country_'+code).length > 0) {
          people = $('#country_'+code).text().split(',');
          if ((temp_text = peopleText(people)).length > 0) { // make text
            ptext += '<strong>'+people.length + ' friend' +(people.length==1 ? ' wants' : 's want');
            ptext += ' to go to ' + label.text()+':</strong><br/>' + temp_text + '<br/>';
          }
        }
        if ($('#location_'+code).length > 0) {
          people = $('#location_'+code).text().split(',');
          if ((temp_text = peopleText(people)).length > 0) { // make text
            ptext += '<strong>'+people.length + ' friend' +(people.length==1 ? ' now lives' : 's now live');
            ptext += ' in ' + label.text()+':</strong><br/>' + temp_text + '<br/>';
          }
        }
        if ($('#hometown_'+code).length > 0) {
          people = $('#hometown_'+code).text().split(',');
          if ((temp_text = peopleText(people)).length > 0) { // make text
            ptext += '<strong>'+people.length + ' friend' +(people.length==1 ? ' is' : 's are');
            ptext += ' from ' + label.text()+':</strong><br/>' + temp_text + '<br/>';
          }
        }
        if (ptext.length > 0)
          label.html('<strong>'+label.text()+'</strong><br/>'+ptext);

    }
  });
};

/* For aggregated photos/posts/travels - horizontal scrollable */
function initScrollable(selector, size) {
  $(selector).each(function() {  // loop through scrollers
    var count = $(this).find('img').length; // get number of buckets in this scroller
    var thisNext = $(this).parent().find('a.next'); // var this next controller
    if (count < size + 1)  // hide next controller if less than size
      thisNext.addClass('disabled');
    $(this).scrollable({circular: false, mousewheel: true});
    var scrollable = $(this).data("scrollable");
    // Handle the Scrollable control's onSeek event
    scrollable.onSeek(function(event, index) {
      // Check to see if we're at the end
      if (this.getIndex() >= this.getSize() - size)
        thisNext.addClass('disabled');// Disable the Next link
    });
    // Handle the Scrollable control's onBeforeSeek event
    scrollable.onBeforeSeek(function(event, index) {
      // Check to see if we're at the end
      if (this.getIndex() >= this.getSize() - size) {
        // Check to see if we're trying to move forward
        if (index > this.getIndex())
          return false;// Cancel navigation
      }
    });
  });
}
