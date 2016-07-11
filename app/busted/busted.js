
var config   = require('../../config.json'),
    cs       = require('../../lib/clientsocket.js'),
    job      = require('../job.js'),
    hyphyJob = require('../hyphyjob.js').hyphyJob,
    jobdel   = require('../../lib/jobdel.js'),
    util     = require('util'),
    _        = require('underscore'),
    fs       = require('fs'),
    path     = require('path'),
    ss       = require('socket.io-stream');

var busted = function (socket, stream, busted_params) {

  var self = this;
  self.socket = socket;
  self.stream = stream;
  self.params = busted_params;


  // object specific attributes
  self.type             = 'busted';
  self.qsub_script_name = 'busted_submit.sh';
  self.qsub_script      = path.join(__dirname,  self.qsub_script_name);

  // parameter attributes
  self.msaid        = busted_params.msa._id;
  self.id           = busted_params.analysis._id;
  self.genetic_code = self.params.msa[0].gencodeid + 1;
  self.type         = self.params.type;

  // parameter-derived attributes
  self.fn          = __dirname + '/output/' + self.id;
  self.output_dir  = path.dirname(self.fn);
  self.status_fn   = self.fn + '.status';
  self.progress_fn = self.fn + '.BUSTED.progress';
  self.results_fn  = self.fn + '.BUSTED.json';
  self.tree_fn     = self.fn + '.tre';

  self.qsub_params =  ['-q',
                          config.qsub_queue,
                          '-v',
                          'fn='+self.fn+
                          ',tree_fn='+self.tree_fn+
                          ',sfn='+self.status_fn+
                          ',pfn='+self.progress_fn+
                          ',treemode='+self.treemode+
                          ',genetic_code='+self.genetic_code+
                          ',cwd='+__dirname+
                          ',msaid='+self.msaid,
                          '-o', self.output_dir,
                          '-e', self.output_dir, 
                          self.qsub_script];

  // Write tree to a file
  fs.writeFile(self.tree_fn, busted_params.analysis.tagged_nwk_tree, function (err) {
    if (err) throw err;
  });

  // Ensure the progress file exists
  fs.openSync(self.progress_fn, 'w');

  self.init();

};

util.inherits(busted, hyphyJob);

exports.busted = busted;

