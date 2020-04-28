var config = require("../../config.json"),
  hyphyJob = require("../hyphyjob.js").hyphyJob,
  code = require("../code").code,
  util = require("util"),
  fs = require("fs"),
  path = require("path");

var cfel = function(socket, stream, params) {

  var self = this;
  self.socket = socket;
  self.stream = stream;
  self.params = params;

  fs.writeFile('./cfel_params.json', JSON.stringify(self.params), function(err) {
    if (err) throw err;
  });


  // object specific attributes
  self.type = "cfel";
  self.qsub_script_name = "cfel.sh";
  self.qsub_script = __dirname + "/" + self.qsub_script_name;

  // parameter attributes
  self.msaid = self.params.msa._id;
  self.id = self.params.analysis._id;
  self.genetic_code = code[self.params.msa[0].gencodeid + 1];
  self.nwk_tree = self.params.analysis.tagged_nwk_tree;
  self.branch_sets = self.params.analysis.branch_sets.join(":");
  self.rate_variation = self.params.analysis.ds_variation == 1 ? "Yes" : "No";

  // parameter-derived attributes
  self.fn = __dirname + "/output/" + self.id;
  self.output_dir = path.dirname(self.fn);
  self.status_fn = self.fn + ".status";
  self.results_short_fn = self.fn + ".cfel";
  self.results_fn = self.fn + ".FEL.json";
  self.progress_fn = self.fn + ".cfel.progress";
  self.tree_fn = self.fn + ".tre";

  self.qsub_params = [
    "-l walltime=" + 
    config.cfel_walltime + 
    ",nodes=1:ppn=" + 
    config.cfel_procs,
    "-q",
    config.qsub_queue,
    "-v",
    "fn=" +
      self.fn +
      ",tree_fn=" +
      self.tree_fn +
      ",sfn=" +
      self.status_fn +
      ",pfn=" +
      self.progress_fn +
      ",rfn=" +
      self.results_short_fn +
      ",treemode=" +
      self.treemode +
      ",genetic_code=" +
      self.genetic_code +
      ",analysis_type=" +
      self.type +
      ",branch_sets=" +
      self.branch_sets +
      ",rate_variation=" +
      self.rate_variation +
      ",cwd=" +
      __dirname +
      ",msaid=" +
      self.msaid +
      ",procs=" +
      config.cfel_procs,
    "-o",
    self.output_dir,
    "-e",
    self.output_dir,
    self.qsub_script
  ];

  // Write tree to a file
  fs.writeFile(self.tree_fn, self.nwk_tree, function(err) {
    if (err) throw err;
  });

  // Ensure the progress file exists
  fs.openSync(self.progress_fn, "w");
  self.init();
};

util.inherits(cfel, hyphyJob);
exports.cfel = cfel;
