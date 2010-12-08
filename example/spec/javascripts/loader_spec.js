require("javascripts/loader.js");

Screw.Unit(function(){
  describe("Loader", function() {
    use_fixture("loader");

    before(function() {
      init_loader();
    });

    it("should start loading content when user clicks", function() {
      mock($).must_receive("ajax");
      $(".trigger_loading").click();
    });

    describe("when loading content has been started", function() {
      var ajax_options;

      before(function() {
        mock($).must_receive("ajax").and_execute(function(o) {
          ajax_options = o;
        });
        $(".trigger_loading").click();
      });

      it("should display the content when loading succeeds", function() {
        ajax_options.success("Content");
        expect($(".replace_me").html()).to(equal, "Content");
      });

      it("should display an alert when loading fails", function() {
        // notice: IE does not allow mocking alerts
        // when testing alerts for IE use intermediate function as a workaround
        mock(window).must_receive("alert");
        ajax_options.error();
      });
    });
  });
});