const http = require('http');

const server = http.createServer();

server.on('request', (req, res) => {

  res.end("Hello, this is Kubernetes demo app")
})

server.listen(8080);
