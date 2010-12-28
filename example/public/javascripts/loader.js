init_loader = function() {
  $(".replace_me").hide();
  $(".trigger_loading").click(function() {
    $(".replace_me").show();
    $.ajax({
      url: "content.html",
      success: function(result) {
        $(".replace_me").html(result);
      },
      error: function() {
        $(".replace_me").html("loading content failed!");
      }
    });
  });
};

