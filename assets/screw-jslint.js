(function() {

Screw.jslint_scripts = {};

Screw.matching_suite = function(filename) {
  var suite;
  $.each(Screw.jslint_suites, function() {
    var found;
    $.each(this.file_list, function() {
      if (this == filename) { found = true; }
    });
    if (found) { suite = this; }
  });
  return suite;
};

$("script").map(function() {
  var source_url = $(this).attr("src");
  if (source_url && source_url !== "") {
    var normalized_source_url = source_url.split("?")[0];

    if (!Screw.matching_suite(normalized_source_url)) { return; }

    Screw.jslint_scripts[normalized_source_url] = null;

    Screw.ajax({
      url: source_url,
      dataType: "text",
      contentType: "text/plain",
      success: function(code) {
        Screw.jslint_scripts[normalized_source_url] = code;
      }
    });
  }
});

Screw.Unit(function(){
  describe("JSLINT check", function() {
    it("should succeed", function() {
      var message = "";
      var ajax = Screw.ajax;
      $.each(Screw.jslint_scripts, function(name, source_code) {
        if (source_code === null) { throw "failed to load "+name; }

        var suite = Screw.matching_suite(name);

        if (!JSLINT(source_code, suite.options)) {
          for (var i = 0; i < JSLINT.errors.length; i += 1) {
            var e = JSLINT.errors[i];
            if (e) {
              var line = parseInt(e.line, 10) + 1;
              var character = parseInt(e.character, 10) + 1;
              message += 'Lint at ' + name + ":" + line + ' character ' +
                character + ': ' + e.reason + "\n";
              message += (e.evidence || '').
                replace(/^\s*(\S*(\s+\S+)*)\s*$/, "$1") + "\n";
              message += "\n";
            }
          }
        }
      });
      if (message.length > 0) { throw message; }
    });
  });
});

}());