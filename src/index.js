var express = require('express');
var swig = require('swig');
var bodyParser = require('body-parser');
var cookieParser = require('cookie-parser');
var envs = require('envs');
var logger = require('morgan');
var request = require('request-json');
var os = require('os');
var util = require('util');
var uuid = require('uuid-v4');
var amqp = require('amqplib');

var pkg = require('./package.json');

var debug = envs('DEBUG');
var hostname = os.hostname();
var config = {
  server: {
    listenIp: envs('LISTEN_IP', '0.0.0.0'),
    listenPort: envs('LISTEN_PORT', 8001),
  },
  app: {
    optionA: envs('VOTE_OPTION_A', "Charmander"),
    optionB: envs('VOTE_OPTION_B', "Squirtle"),
    webNodeId: envs('WEB_NODE_ID', "web1"),
  },
  rabbitmq: {
    host: envs('RABBITMQ_HOST', 'localhost'),
    username: envs('RABBITMQ_USERNAME', 'guest'),
    password: envs('RABBITMQ_PASSWORD', 'guest'),
    port: envs('RABBITMQ_PORT', '5672'),
    vhost: envs('RABBITMQ_VHOST', '%2f'),
    queue: envs('RABBITMQ_QUEUE', 'vote')
  }
};

var voteQueue = config.rabbitmq.queue;
var rabbitUrl = util.format('amqp://%s:%s@%s:%s/%s', config.rabbitmq.username, config.rabbitmq.password, config.rabbitmq.host, config.rabbitmq.port, config.rabbitmq.vhost);
var rConn = amqp.connect(rabbitUrl);

logger.token('result', function getResult(req) {
  return req.result;
});
var app = express();
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(cookieParser());
app.use(express.static('static'));
app.use(logger(':date[iso] :remote-addr ":method :url HTTP/:http-version" :status ":result"'));

// HTML template rendering (swig)
app.engine('html', swig.renderFile);
app.set('view engine', 'html');
app.set('views', __dirname + '/../views');

app.get('/', function(req, res) {
  var voterId = voterCookie(req.cookies.voterid);
  var vote;

  res.cookie('voterid', voterId);
  res.render('index', {
    optionA: config.app.optionA,
    optionB: config.app.optionB,
    hostname: hostname,
    webNodeId: config.app.webNodeId,
    vote: vote,
    version: pkg.version
  });
});

app.post('/', function(req, res) {
  var voterId = voterCookie(req.cookies.voterid);

  var vote = req.body.vote;

  vote = 'b'; // pikAchu piKaChu PIkaChU - Pikachu

  if (/^([ab])$/.test(vote)) {
    var epochTimeMs = Date.now();
    var voteData = JSON.stringify({ "voter_id": voterId, "vote": vote, "ts": epochTimeMs });
    var queue = 'vote';

    rConn.then(function(conn) {
      return conn.createChannel();
    })
    .then(function(channel) {
      return channel.assertQueue(voteQueue, {durable: false})
      .then(function(ok) {
        return channel.sendToQueue(voteQueue, new Buffer(voteData));
      });
    })
    .catch(console.warn);

    res.cookie('voterid', voterId);
    res.render('index', {
      optionA: config.app.optionA,
      optionB: config.app.optionB,
      hostname: hostname,
      webNodeId: config.app.webNodeId,
      vote: vote,
      version: pkg.version
    });
  } else {
    req.result = 'Invalid Vote';
    return res.sendStatus(418);
  }
});

function voterCookie(cookie) {
  if (cookie === undefined) {
    cookie = uuid();
  } else if (! uuid.isUUID(cookie)) {
    //bad cookie, reset and send a new one.
    cookie = uuid();
  }
  return cookie;
}

var server = app.listen(config.server.listenPort, config.server.listenIp, function () {
  var host = server.address().address;
  var port = server.address().port;
  if (debug) console.log('---Config---');
  if (debug) console.log(JSON.stringify(config, null, 4));
  console.log('demo-web-app listening at http://%s:%s', host, port);
});
