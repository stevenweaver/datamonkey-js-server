/*

  Datamonkey - An API for comparative analysis of sequence alignments using state-of-the-art statistical models.

  Copyright (C) 2013
  Sergei L Kosakovsky Pond (spond@ucsd.edu)
  Steven Weaver (sweaver@ucsd.edu)

  Permission is hereby granted, free of charge, to any person obtaining a
  copy of this software and associated documentation files (the
  "Software"), to deal in the Software without restriction, including
  without limitation the rights to use, copy, modify, merge, publish,
  distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to
  the following conditions:

  The above copyright notice and this permission notice shall be included
  in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
  CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

*/

var spawn = require('child_process').spawn,
    fs = require('fs'),
    config = require('../../config.json'),
    util = require('util'),
    Tail = require('tail').Tail,
    EventEmitter = require('events').EventEmitter;

var DoBustedAnalysis = function () {};
util.inherits(DoBustedAnalysis, EventEmitter);

/**
 * Once the job has been scheduled, we need to watch the files that it
 * sends updates to.
 */
DoBustedAnalysis.prototype.status_watcher = function () {
  self = this;

  // Update progress
  fs.openSync(self.progress_fn, 'w')
  fs.watch(self.progress_fn, function(e, filename) { 
    fs.readFile(self.progress_fn, 'utf8', function (err,data) {
      if(data) {
        self.emit('status update', {'phase': self.status_stack[1], 'msg': data});
      }
    });
  });

  while (!self.job_completed) {

    // Check qstat to see if job is completed
    var qstat =  spawn('qstat', [self.torque_id] );

    qstat.stderr.on('data', function (data) {
      // Could not start job
      console.log(data.toString());
      self.job_completed = true;
      self.emit('completed');
    });

    qstat.stdout.on('data', function (data) {
      var re = /(\s)+/g;
      var job_status = data.toString().split("\n")[2].replace(re, " ").split(" ")[4];
      if(job_status == 'C') {
        self.job_completed = true;
        //TODO: submit completion
        self.emit('completed');
      }

    });
  }
}

/**
 * Submits a job to TORQUE by spawning qsub_submit.sh
 * The job is executed as specified in ./busted/README
 * Emit events that are being listened for by ./server.js
 */
DoBustedAnalysis.prototype.start = function (busted_params) {

  var self = this;
  self.id = busted_params.analysis._id;
  self.msaid = busted_params.msa._id;
  self.output_dir  = __dirname + '/output/';
  self.qsub_script = __dirname + '/busted_submit.sh';
  self.filepath = self.output_dir + self.id;
  self.status_fn = self.filepath + '.status';
  self.progress_fn = self.filepath + '.progress';
  self.tree_fn = self.filepath + '.tre';
  self.progress_fn = self.filepath + '.progress';
  self.busted = config.busted;
  self.status_stack = busted_params.status_stack;
  self.genetic_code = "1";
  self.torque_id = "unk";
  self.job_completed = false;

  // Write tree to a file
  fs.writeFile(self.tree_fn, busted_params.analysis.tagged_nwk_tree, function (err) {
    if (err) throw err;
  });

  // qsub_submit.sh
  var qsub_submit = function () {

    var qsub =  spawn('qsub', 
                         ['-v',
                          'fn='+self.filepath+
                          ',tree_fn='+self.tree_fn+
                          ',sfn='+self.status_fn+
                          ',pfn='+self.progress_fn+
                          ',treemode='+self.treemode+
                          ',genetic_code='+self.genetic_code+
                          ',msaid='+self.msaid,
                          '-o', self.output_dir,
                          '-e', self.output_dir, 
                          self.qsub_script], 
                          { cwd : self.output_dir});

    qsub.stderr.on('data', function (data) {
      // Could not start job
      console.log('stderr: ' + data);
    });

    qsub.stdout.on('data', function (data) {
      self.torque_id = String(data).replace(/\n$/, '');
      self.emit('job created', { 'torque_id': self.torque_id });
    });

    qsub.on('close', function (code) {
      // Should have received a job id
      // Write queuing to status
      fs.writeFile(self.status_fn, 
                   self.status_stack[0], function (err) {
        self.status_watcher();
      });
    });
  }

  // Write the contents of the file in the parameters to a file on the 
  // local filesystem, then spawn the job.
  var do_busted = function(stream, busted_params) {
    self.emit('status update', {'phase': self.status_stack[0], 'msg': ''});
    qsub_submit();
  }

  do_busted(busted_params);

}

exports.DoBustedAnalysis = DoBustedAnalysis;