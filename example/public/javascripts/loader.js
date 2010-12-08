init_loader = function() {
  $(".trigger_loading").click(function() {
    $.ajax({
      url: "content.html",
      success: function(result) {
        $(".replace_me").html(result);
      },
      error: function() {
        alert("loading content failed!");
      }
    });
  });
};

