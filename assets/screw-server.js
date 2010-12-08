(function() {

if (!window.jQuery) {
  alert(
    "jQuery not found!\n"+
    "jQuery must be provided by your application.\n"+
    "Make sure the url for jquery required by your spec helper is correct.\n"+
    "\n"+
    "Example:\n"+
    "If jQuery is installed under\n"
    +"<your app>/public/javascripts/jquery.js\n"+
    "then make sure the following line is in your spec_helper.js\n"+
    "require('javascripts/jquery.js');"
    );
  return;
}

// save the ajax method in case a test messes with it
Screw.ajax = jQuery.ajax;

$.extend(Screw.Specifications, {
  use_fixture: function(fixture_name) {
    Screw.Specifications.before(function() {
      $("#fixture_container").html(window.fixture_container[fixture_name]);
    });
  }
});

window.require = function() {
  // require is a NOOP in javascript.
  // the require statement is only "used" by the screw_server.rb when generating the wrapper html.
  // the screw_server looks for require statements per regexp.
};

var exampleName = function(element){
  var exampleName = $.trim($(element).children("h2").text());

  var names = contextNamesForExample(element);
  names.push(exampleName);

  return names.join(" ");
};

var contextNamesForExample = function(element){
  var describes = $(element).parents('.describe').children('h1');

  var contextNames = $.map(describes, function(context){
    return $.trim($(context).text());
  });

  return contextNames.reverse();
};

$(Screw).bind('loaded', function() {
  $('.it')
    .bind('failed', function(e, reason) {
      if (!window.console || !window.console.debug) { return; }
      console.debug("Failure:");
      console.debug(exampleName(this));
      console.debug(reason.toString());

      var file = reason.fileName || reason.sourceURL;
      var line = reason.lineNumber || reason.line;
      if (file || line) {
        console.debug('line ' + line + ', ' + file);
      }
      var trace = reason.stack;
      if (trace) {
        console.debug(trace);
      }
    })
    .bind('failed', function(e, reason) {
      var test_dom = $(this);
      if (reason.message) {
        test_dom.append($('<p class="error"></p>').text(reason.message));
      }
      var trace = reason.stack;
      if (trace) {
        var trace_lines = trace.split("\n")
        $.each(trace_lines, function(number, line) {
          test_dom.append($('<p class="error"></p>').text(line));
        });
      }
    });

  $(Screw)
    .bind('after', function() {
      $("#fixture_container").empty();

      var failures = $("li .it.failed");
      if (failures.length > 0) {
        window.scrollTo(0, failures.first().position().top);
      }
    })

});

}());