var express = require("express");
var request = require("request");

var app = express.createServer();
app.use(express.bodyParser());
app.use(express.static('pub'));
app.set('view engine', 'jade');

app.get('/', function(req, res) {
   res.render('index');
});

var port = process.env.PORT || 8081;
app.listen(port);

