# Screw Server

## Installation

(from source)

    git submodule update --init
    gem build screw_server.gemspec
    gem install screw_server*.gem

## Prerequisites

Screw Server expects to be executed in your application's root directory, where it expects the following directory structure by default:

  * `public`
      (Contains the code to test. May use subdirectories,
      i.e. `/public/javascripts` when using rails)
  * `spec`
      * `javascripts`
          * `spec_helper.js`
          * your javascript test suites having a `"_spec.js"` - suffix (i.e. `my_spec.js`, `another_spec.js`)
          * `fixtures` (optional)
            * your HTML fixture files having a `".html"` - suffix (i.e. `my_fixture.html`)

Your application must contain jQuery.
To tell Screw Server where to find jQuery, you must require it in your `spec_helper.js`.

### Example:
If jQuery's file is `/public/javascripts/jquery-1.4.0.js` then make sure the following line is in your `spec_helper.js`:

    require('javascripts/jquery-1.4.0.js');


## Starting the Screw Server

    cd <my app>
    screw_server

Open `http://localhost:3210` in the browser you want your tests to run in.

You may open Screw Server in several browsers in parallel to do cross-browser testing.

If you require a different port or wish to use a different directory structure for your application, you can configure screw_server via command line options. To learn more, use:

    screw_server --help

### Monitoring (Autotest)

Click on `MONITOR` in Screw Server's start page. Screw Server will then monitor the modification times in your applications code and tests. Whenever you touch (= save) a test suite, Screw Server will automatically run that suite. When you touch a code file that is tested by that suite, the suite will automatically be re-run.

## Wrinting Tests

To get started, take a look at the example "app" located in Screw Server's source under `/example`.

Screw Server uses [Screw Unit](https://github.com/infopark/screw-unit) as a test suite framework and [Smoke](https://github.com/infopark/smoke) as a mocking and stubbing framework. Please refer to their documentation for test syntax.

Notice that you do not need the static HTML suite mentiond in Screw Unit's documentation.
Screw Server generates that for you.

## Requiring Files

Screw Server provides a special mechanism for requiring files, the `require` directive.
When writing tests, you need to tell Screw Server which javascript source files from your application should be loaded (= the code-under-test).

### Example

You want to test a javascript class defined in `/javascripts/my_class.js`.
This class depends on some utility methods defined in `/javascript/utils.js`.
Then you need to require these files at the top of your test, i.e. in `/spec/javascripts/my_class_spec.js`:

    require("/javascripts/utils.js");
    require("/javascripts/my_class.js");

If all your tests depend on `utils.js`, you should move it's `require` directive into the `spec_helper.js` to avoid repeating it in every test.

Notice that `require` is not an actual javascript function! It is a directive that is parsed statically by Screw Server. Therfore the following will NOT work:

    // DO NOT DO THIS! IT DOES NOT WORK!
    var some_file = "/javascripts/utils.js";
    require(some_file);

Also `require` directives are only parsed in your spec files and the `spec_helper.js`. Do not put `require` directives into your application's actual code.

## HTML Fixtures

When the javascript code you want to test uses the browser's DOM, HTML fixtures come in handy.
An HTML fixture is a snippet of HTML that is inserted into the DOM before a test is run.
Insert the `use_fixture` directive into your test to tell Screw Server which fixture is used by that test.

### Example

    Screw.Unit(function(){
      describe("My Test", function() {
        use_fixture("my_fixture");

        it("should do A", function() {
          // ...
        });

        it("should do B", function() {
          // ...
        });
      });
    });

Screw Server will load the HTML snippet found in `/spec/javascripts/fixtures/my_fixture.html`.
The HTML snippet will be inserted into the DOM before running `it` blocks inside the `describe` block where `use_fixture` is declared. This also applies to nested `describe` blocks.

The HTML snippet will be restored to it's initial state before each `it` block, so feel free to manipulate the fixture DOM as you like.

### Beware

Do not manipulate any DOM elements outside of your fixtures! This could interfere with Screw Server's test runner. If a test does not declare `use_fixture`, it should not access the DOM at all and neither should the code-under-test.

## JSLint

Screw Server is able to test your coding style using JSLint.
Unfortunately there is no documentation yet.
Feel free to ask the maintainer ^__^
