var ProcessingClass = function() {};

ProcessingClass.prototype = {
    run: function(arguments) {
        let keywords = document.querySelector('meta[name="keywords"]');
        let description = document.querySelector('meta[name="description"]');
      arguments.completionFunction({
          "title": document.title,
          "url": document.URL,
          "selected": document.getSelection().toString(),
          "keywords": keywords != null ? keywords.content : "",
          "description": description != null ? description.content : "",
          //"html": document.documentElement.outerHTML
      });
    },
    finalize: function(arguments) {}
};

var ExtensionPreprocessingJS = new ProcessingClass

