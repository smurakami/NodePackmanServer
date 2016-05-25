// Generated by CoffeeScript 1.10.0
(function() {
  var Main;

  Main = (function() {
    function Main() {
      this.init();
      this.initSocket();
    }

    Main.prototype.init = function() {};

    Main.prototype.initSocket = function() {
      this.socket = new Socket();
      this.socket.onopen = (function(_this) {
        return function() {
          return _this.socket.send({
            event: "client_type",
            client_type: "player"
          });
        };
      })(this);
      return this.socket.onmessage = (function(_this) {
        return function(data) {
          console.log(data);
          return _this.onmessage(data);
        };
      })(this);
    };

    return Main;

  })();

  $(function() {
    var app;
    return app = new Main();
  });

}).call(this);
