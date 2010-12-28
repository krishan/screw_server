require("javascripts/loader.js");

Screw.Unit(function(){
  describe("Loader", function() {
    use_fixture("loader");

    before(function() {
      init_loader();
    });

    it("should hide the area for extra content initially", function() {
      expect($(".replace_me").css("display")).to(be, "none");
    });

    describe("when user clicks", function() {
      it("should start loading content", function() {
        mock($).must_receive("ajax").and_execute(function(options) {
          expect(options.url).to(equal, "content.html");
        });
        $(".trigger_loading").click();
      });

      it("should show the area for the extra content", function() {
        $(".trigger_loading").click();
        expect($(".replace_me").css("display")).to(be, "block");
      });
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
        ajax_options.error();
        expect($(".replace_me").html()).to(equal, "loading content failed!");
      });
    });
  });
});