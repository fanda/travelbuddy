//= require jquery.input-hint
//= require jquery.vector-map
//= require world-en

var selected = []; // helper global array for map-checkboxes synchro

var jvm_color = '#cccccc',    jvm_scaleColors = ['#47bdff', '#3b5998'],
    jvm_selected = '#1f4189', jvm_backgroundColor = '#ffffff',
    jvm_filter = '#ff6600';

var js_date_format = 'MM/dd/yyyy';



$(document).ready(function() {


  // turn on input hint for preferences
  $('input:not([value]).date,input[value=""].date').inputHints();


  // init datepicker with range dates check
  initDatepicker('.date');

  // initial setting of Start/End dates in New Travel preferences
  $('#matchwrap .date').each(function() {
    if ($(this).hasClass('hint')) return;
    var sibling = $(this).siblings('.date');
    var date = new Date($(this).val());
    if ($(this).attr('id').indexOf('ends') >= 0) { // on ends date
      sibling.datepicker('setEndDate', date.f(js_date_format));
    } else { // on begins date
      sibling.datepicker('setStartDate', date.f(js_date_format));
    }
  });

  // remove icon for time preferences
  $('#preferences i').click(function() {
    var inputs = $(this).siblings('.date');
    inputs.val('');// remove icon action = remove input text
    inputs.removeAttr('value');
    inputs.datepicker('setStartDate').datepicker('setEndDate');
    $('input:not([value]).date').inputHints();// turn on input hint for preferences
  });

  $(".continent").click(function() {
    if ($(this).hasClass("collapsed")) {
      $(this).removeClass("collapsed");
      $(this).addClass("expanded");
      $(this).siblings('ul').show();
    } else {
      $(this).removeClass("expanded");
      $(this).addClass("collapsed");
      $(this).siblings('ul').hide();
    }
  });

  $('.continent').each(function() {
    // init callback - check and show continents checkboxes
    // if there are some selected countries from contintent
    if ($(this).siblings('ul').find('input:checked').length > 0)
      $(this).addClass("expanded").siblings('ul').show();
    else
      $(this).addClass("collapsed");
  });

  // show/hide checkboxes according to selecting
  $('ul#countries input[type="checkbox"]').each(function() {
    $(this).bind('click change', function () {//
      if($(this).is(':checked')) {
        $(this).parent().siblings('ul').show();
        //$(this).parents('ul').
          //siblings('label input[type="checkbox"]').attr('checked', 'checked');
      } else {
        $(this).parent().siblings('ul').hide();
          //find('label input[type="checkbox"]').removeAttr('checked', 'checked');
      }
    });
  });

  // client-side validation for time preferences
  // both (begins,ends) dates must by filled
  $('#new_travels').submit(function(e) {
    // validation
    var validity = true;
    $(this).find('.hint').val('').removeClass('hint');
    $('#preferences li').each(function() {
      var dates = $(this).find('.date');
      // check two invalid options and mark bad input with red color
      if ($(dates[0]).val().length <= 0 && $(dates[1]).val().length > 0) {
        $(dates[0]).css('border-color', 'red');
        validity = false;
      } else
      if ($(dates[1]).val().length <= 0 && $(dates[0]).val().length > 0) {
        $(dates[1]).css('border-color', 'red');
        validity = false;
      }
    });
    if (!validity) { // INVALID
      e.preventDefault();// to be sure that form will not be sent
      // do not show if there is
      $('#new_travels div.alert').remove();
      // message: create, insert and do nice efect
      $('<div class="alert alert-error"><a class="close" data-dismiss="alert">×</a>Both dates must be filled.</div>').insertAfter('#preferences').hide().fadeIn(500);
    }
    else { // VALID
      // we want to create picture of map - larger than map: 1024x768 and more
      // must re-create jvectormap's SVG to dimensions and send it to server
      // dimensions are set in application.css - id #fb_atlas
      $('#content').append($('<div id="fb_atlas">')); // create hidden element
      // init new (larger) svg map
      $('#fb_atlas').vectorMap({ color: jvm_color, backgroundColor: jvm_backgroundColor });
      var len = selected.length;
      for (var i = 0; i < len; i++) // show selected countries
        setMapColor('#fb_atlas', selected[i], jvm_selected);
      var input = $('#map_data'); // set data input for server
      input.val($('<div>').append($('#fb_atlas svg:last').clone()).html());
      $(this).append(input);
    }
    return validity; // if false -> submit aborted
  });

  // checkbox checked -> synchronize map
  $('ul#countries input[type="checkbox"]').live("change", function() {
    if ($(this).hasClass('continent')) return;
    atlasClickCase( '#atlas' , $(this).val() );
  });

  // tab change callback - show different map
  $('a[data-toggle="tab"]').on('shown', function (e) {
    var old_selected, len; // declaration
    $('#countries li').hide(); // hide all country names in sidebar

    // Search by Schedule activated
    if (String(e.target).indexOf('time') >= 0) {
      // heat map for all if none selected
      if (selected.length <= 0)
        removeMapHeat('#atlas', heat_country);
      // classify
      $('#atlas').removeClass('country_matches').addClass('time_matches');
      $('#preferences').show(); // show date inputs (they are out of tab)

      old_selected = selected_country;// save current map
      selected = selected_time;// load new selected

      len = old_selected.length;
      for (var i = 0; i < len; i++) {// hide all
        setMapColor('#atlas', old_selected[i], jvm_color);
        $('.'+old_selected[i]).hide();
      }

      $('#preference_choice').trigger('change'); // map coloring is there
    } else

    // Search by Destination activated
    if (String(e.target).indexOf('country') >= 0) {
      old_selected = selected_time;// create alias
      selected = selected_country;// load new selected
      // classify
      $('#atlas').removeClass('time_matches').addClass('country_matches');
      $('#preferences').hide(); // hide date inputs (they are out of tab)

      if (old_selected.length <= 0)
        removeMapHeat('#atlas', heat_time);
      else {
        // as first de-colorize whole map
        len = old_selected.length;
        for (var i = 0; i < len; i++) {// hide all
          setMapColor('#atlas', old_selected[i], jvm_color);
          $('.'+old_selected[i]).hide();
        }
      }
      // set map heat for countries
      if (selected.length <= 0) {
        setMapHeat('.country_matches', heat_country);
        for (code in heat_country)
          $('#countries_'+code).show().parents('.continents').show();
        $('#country_matches .match').show();
      } else {
        // set new colors
        len = selected.length;
        for (var i = 0; i < len; i++) {// show selected countries
          setMapColor('#atlas', selected[i], jvm_filter);
          $('#countries_'+selected[i]).parents('.continents').show();
          $('.'+selected[i]+',#countries_'+selected[i]).show();
        }
      }
    }
  });

  // time_match preference choice callback
  $('#preference_choice').bind('change', function() {
    $("#preference_choice option:selected").each(function () {
      if ($(this).val().length <= 0) filterTimeMatches();
      else if($(this).val() == '-') {
        $('#time_matches .match').show();
        $('#begins').val(begins).datepicker('setEndDate');
        $('#ends').val(ends).datepicker('setStartDate');
        $('#begins,#ends').datepicker('setStartDate', (new Date()).f(js_date_format));
        filterTimeMatches(); // hide/show matches
        if ( ! $('#begins,#ends').hasClass('hint'))
          $('#begins,#ends').val('');
        $('input[value=""].date').inputHints();
        setMapHeat('#atlas', heat_time);
        $('#countries li').hide();
        for (code in heat_time)
          $('#countries_'+code).show().parents('.continents').show();
      } else {
        //removeMapHeat('.country_matches', heat_time);
        var substrs = $(this).val().split('_');
        // maybe format would be in locale file or global variable
        $('#begins,#ends').removeClass('hint');
        var begins = parseDate(substrs[0]).f(js_date_format),
            ends   = parseDate(substrs[1]).f(js_date_format);
        $('#begins').val(begins).datepicker('setEndDate', ends);
        $('#ends').val(ends).datepicker('setStartDate', begins);
        filterTimeMatches(); // hide/show matches
      }
    });
  });

  // time_match custom dates choice callback
  $('#begins,#ends').bind('change', function() {
    if ($('#preference_choice option[value=""]').length <= 0)
      $('#preference_choice').append($('<option value="">Custom</option>'));
    $('#preference_choice option[value=""]').attr('selected', 'selected');
    $(this).removeClass('hint');
    filterTimeMatches(); // hide/show matches
  }).
  // disable dates before today for "Search by Schedule" preference
  datepicker('setStartDate', (new Date()).f(js_date_format));

  if ($('#country_matches').length > 0) {
    $.get('/other-facebook-friends', function(html) {
        $('#locations').append(html);
    });
  }

});



/*
    Functions definitions

*/

/* Refresh country heat map with new heat data */
function actualizeCountryHeatMap(heat) {
  //if (selected.length <= 0) removeMapHeat('.country_matches', heat_country);
  var to_select = [];
  for (code in heat) {
    if (code in heat_country)
      heat_country[code] += heat[code];
    else
      heat_country[code] = heat[code];
  }
  if ($('.active a[data-toggle="tab"]').attr('href') == '#country_matches') {
    if (selected.length <= 0) {
      setMapHeat('#atlas', heat_country);
    } else {
      $('.noapp').hide();
      for (var i = 0; i < selected.length; i++) {
        $('.'+selected[i]).show();
      }
    }
  }
}


/* to hide/show matches according to choice */
function filterTimeMatches() {
  // save values and de-colorize whole map
  var p_begins = new Date($('#begins').val()).valueOf(),
      p_ends   = new Date($('#ends').val()).valueOf();
  var len = selected.length;
  if (selected.length <= 0)
    removeMapHeat('#atlas', heat_time);
  for (var i = 0; i < len; i++) // hide all
    setMapColor('#atlas', selected[i], jvm_color);
  // clear selected
  selected = [];
  $('#countries li').hide();
  var heat_time_active = {};
  $('#time_matches .match').hide().each(function() {
    // each match - will be hidden or visible ??
    var match = $(this);
    var classes = match.attr('class').split(/\s/);
    var hidden = true, codes = [];
    // check all classes
    $.each(classes, function(i, cls) { // for each friend
      var dates = cls.split('_');
      // date classes
      if (dates.length > 1) { // validate classes
        var c_begins = parseDate(dates[0].valueOf()),
            c_ends   = parseDate(dates[1].valueOf());
        if (c_begins <= p_ends && c_ends >= p_begins) {
          hidden = false;
        }
      } else
      // country classes
      if (cls != 'match') { // this class name is country code
        codes.push(cls);
      }
    });
    if (!hidden) {// show or hide
      len = codes.length;
      // compute heat map
      for (var i = 0; i < len; i++) { // each code
        if (heat_time_active[codes[i]] == undefined)
          heat_time_active[codes[i]] = 1; // first time seeing code
        else
          heat_time_active[codes[i]] += 1; // increment
        if ($.inArray(codes[i], selected) < 0)
          selected.push(codes[i]);// add to selected too
      }
      match.show();
    }
  });
  setMapHeat('#atlas', heat_time_active);
  selected_time = selected;
};


// helper for parsing date from class name
function parseDate(date_string) {
  var parts = date_string.split("-");
  // construcor format is: Y, M, D
  return new Date(parts[0], (parts[1] - 1) ,parts[2]);
};

// case for more maps and click callbacks
function atlasClickCase(atlas, code) {
  if ($(atlas).hasClass('new-travels'))
    synchronizeMapAndBoxes(code);
  else
  if ($(atlas).hasClass('country_matches')) {
    showOnlyMatchesWithCode(code);
  }
};

/* for country_match - show only checked country matches */
function showOnlyMatchesWithCode(code) {
  // no selected country, but will be selected, so clean colors
  if (selected.length <= 0) removeMapHeat('.country_matches', heat_country);
  var i = $.inArray(code, selected);
  if (i >= 0) { // map marked
    setMapColor('.country_matches', code, jvm_color);
    $('#country_matches .match, #countries li').hide();
    selected.splice(i, 1); // remove
    var len = selected.length;
    for (var i = 0; i < len; i++) {
      $('#countries_'+selected[i]).parents('.continents').show();
      $('.'+selected[i]+',#countries_'+selected[i]).show();
    }
  }
  else { // map not marked => select
    setMapColor('.country_matches', code, jvm_filter);
    $('#country_matches .match, #countries li').hide();
    selected.push(code);
    var len = selected.length;
    for (var i = 0; i < len; i++) {
      $('#countries_'+selected[i]).parents('.continents').show();
      $('.'+selected[i]+',#countries_'+selected[i]).show();
    }
  }
  // no selected country, so show heat
  if (selected.length <= 0) {
    setMapHeat('.country_matches', heat_country);
    for (code in heat_country)
      $('#countries_'+code).show().parents('.continents').show();
    $('#country_matches .match').show();
  }
  selected_country = selected;

  // amazon widget search
  $('#amzn_search_textfield').val($('#countries_'+code).text() + ' travel guide');
  var action = $('#amzn_search_textfield').siblings('input[type="image"]').attr('onclick');
  eval(action);

};

/* Synchronizes map and check_boxes in form - using global 'selected' array */
function synchronizeMapAndBoxes(code) {
  var i = $.inArray(code, selected);
  if (i >= 0) { // map marked
    setMapColor('.new-travels', code, jvm_color);
    $("#countries_"+code).removeAttr('checked', 'checked');
    selected.splice(i, 1); // remove
  }
  else { // map not marked => select in last selectbox
    selected.push(code);
    $("#countries_"+code).attr('checked', 'checked');
    setMapColor('.new-travels', code, jvm_selected);
  }
};

/* Helper for map's onLabelShow trigger */
function peopleText(people) {
  if (people.length > 0) {
    if (people.length > 5)
      return people.slice(0, 4).join(', ')+' and '+(people.length-4)+' others';
    else
      return people.join(', ');
  } else return '';
}


/* Function for document.ready - marks countries on the map according to saved travels */
function initMap(codes) { // called in new travels template
  selected = codes;

  $('#atlas').vectorMap({
    color: jvm_color,
    backgroundColor: jvm_backgroundColor,
    values: {},
    scaleColors: jvm_scaleColors,
    normalizeFunction: 'polynomial',
    hoverOpacity: 0.7,
    hoverColor: false,
    // click callback -> synchronize checkboxes
    onRegionClick: function(event, code) {
      atlasClickCase( this , code );
    },
    // big trigger to show people in country on hover
    onLabelShow: function(event, label, code){
      if ( ! $('#atlas').hasClass('heat')) return;// no heatmap, no people
      var people = [], ptext = '', temp_text;
      // have country or time matches ?
      var id = $('#matchtabs .active a').attr('href');
      $(id+' .'+code+' a.name').each(function() {// search..
          people.push($(this).text());// ..and destroy :)
      });
      if ((temp_text = peopleText(people)).length > 0) { // make text
        ptext += '<strong>'+people.length + ' friend' +(people.length==1 ? ' wants' : 's want');
        ptext += ' to go to ' + label.text()+':</strong><br/>' + temp_text + '<br/>';
      }

      people = []; id = '#locations';// re-init
      $(id+' .'+code+' .current a.name').each(function() {// search..
        people.push($(this).text());// ..and destroy .. 2
      });
      if ((temp_text = peopleText(people)).length > 0) { // make text
        ptext += '<strong>'+people.length + ' friend' +(people.length==1 ? ' now lives' : 's now live');
        ptext += ' in ' + label.text()+':</strong><br/>' + temp_text + '<br/>';
      }

      people = [];// re-init
      $(id+' .'+code+' .hometown a.name').each(function() {// search..
        people.push($(this).text());// ..and destroy .. 3
      });
      if ((temp_text = peopleText(people)).length > 0) { // make text
        ptext += '<strong>'+people.length + ' friend' +(people.length==1 ? ' is' : 's are');
        ptext += ' from ' + label.text()+':</strong><br/>' + temp_text + '<br/>';
      }
      if (ptext.length > 0)
        label.html('<strong>'+label.text()+'</strong><br/>'+ptext);
    }
  });

  var len = codes.length;
  for (var i = 0; i < len; i++)
    setMapColor('#atlas', codes[i], jvm_selected);
};

/* ini checkboxes when document.ready */
function initBoxes(codes) {
  var len = codes.length;
  for (var i = 0; i < len; i++)
    $("#countries_"+codes[i]).attr('checked', 'checked');
};

/* draw heatmap in shown map */
function setMapHeat(id, values) {
  $(id).vectorMap('set', 'values', values);
  $(id).addClass('heat');
  $('#legend').show();
};

/* remove heatmap from shown map */
function removeMapHeat(id, values) {
  $(id).removeClass('heat');
  colors = {};
  for (code in values)
    colors[code] = 0;
  $(id).vectorMap('set', 'values', colors);
  $('#legend').hide();
};

function setMapColor(id, code, color) {
  $(id).vectorMap('set', 'colors', eval("({'"+code+"': '"+color+"'})"));
};

// the same debug function
function dbg(obj) {
  $('footer #debug').append('<pre>'+JSON.stringify(obj, null, '\t')+'</pre>');
};

/* Aggregation for Locations, because of AJAX reqeust for non-app friends */
function groupLocationsByCountry() {
  var current = {}, hometown = {};
  $('#locations .match').each(function() {
    var match = $(this);
    var codes = $(this).attr('class').replace(/\s?match\s?/,'').replace(/\s?noapp\s?/,'');
    $.each(codes.split(/\s/), function(i, code) {
      if (match.find('.current').length > 0) {
        if (code in current)
          current[code] += 1;
        else
          current[code] = 1;
      }
      if (match.find('.hometown').length > 0) {
        if (code in hometown)
          hometown[code] += 1;
        else
          hometown[code] = 1;
      }
    });
  });
  makeGrouped('current', current, 'of your friends live in');
  makeGrouped('hometown', hometown, 'of your friends are from');
  $('#locations .match-to-remove').remove();
  $('#locations .location').addClass('match');
};

/* Helper for groupLocationsByCountry */
function makeGrouped(what, group, message) {
  for (code in group)
    if (group[code] > 1) {
      $('#locations').append(
        '<div class="location '+code+'">'+
          '<span>'+group[code]+' '+message+' '+ MapData['pathes'][code]['name'] +'</span>'+
          '<div class="grouped '+what+'">'+
            '<div class="items"></div>'+
          '</div>'+
          '<a href="#" class="prev browse left" onclick="return false;"></a>'+
          '<a href="#" class="browse next right" onclick="return false;"></a>'+
          '<div class="out"></div>'+
        '</div>'
      );
      // very nice block of code :)
      $('#locations .match.'+code).each(function() {
        if ($(this).find('.'+what).length <= 0) return;
        var amatch = $(document.createElement('span'));
        var image = $(this).find('img').clone().removeClass('tip');
        image.attr('src',  image.attr('src')+'?type=large');
        image.attr('title', $(this).find('.'+what).text().replace(/\s+/g,' '));
        var link = $(document.createElement('a'));
        link.attr('href', $(this).find('.name').attr('href')).attr('target', '_blank').addClass('bimg');
        amatch.addClass('amatch').append(link.append(image)).append($(this).find('.name').clone());
        //amatch.addClass('amatch').append(image);
        $('#locations .'+code+' .'+what+' .items').append(amatch);
        $(this).addClass('match-to-remove').hide();
      });
    }
}

function initDatepicker(klass) {
  // init datepicker with range dates check
  $(klass).datepicker({ startDate: new Date() }).
    // set start date
    on('beforeShow', function(e, data) {
      var sibling = $(this).siblings(klass);
      if (! sibling.hasClass('hint') && $(this).hasClass('hint')) {
        // sibling value not empty and this value empty
        data.date = new Date(sibling.val());
        data.change = true;
      }
    }).
    // validation on change
    on('changeDate', function(ev){
      var begins, ends;
      // get values -> set Start/End date for sibling input
      if ($(this).hasClass('ends')) { // on ends date
        ends = ev.date.valueOf();
        var sibling = $(this).siblings(klass);
        begins = new Date(sibling.val()).valueOf();
        sibling.datepicker('setEndDate', ev.date.f(js_date_format));
      } else { // on begins date
        begins = ev.date.valueOf();
        var sibling = $(this).siblings(klass);
        ends = new Date(sibling.val()).valueOf();
        sibling.datepicker('setStartDate', ev.date.f(js_date_format));
      }
      // show error if invalid = second validation
  		if (begins > ends) {
        $('.alert').remove();
        $('<div class="alert alert-error"><a class="close" data-dismiss="alert">×</a>The start date can not be later then the end date.</div>').insertAfter('#preferences,').hide().fadeIn(500);
        $(this).css('border-color', 'red');
  		} else {
        $('.alert').fadeOut(200);
        $(this).css('border-color', '#ddd');
        $(this).siblings('.date').css('border-color', '#ddd');
        //$(this).attr('value', $(this).data('date'));
      }
 	  });
};
