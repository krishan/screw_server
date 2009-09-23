(function() {

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
      var trace = reason.stack;
      if (trace) {
        var trace_lines = trace.split("\n")
        var test_dom = $(this);
        $.each(trace_lines, function(number, line) {
          test_dom.append($('<p class="error"></p>').text(line));
        });
      }
    })
});

}());