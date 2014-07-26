/* 

INPUT:

	1. file descriptor			: upload.numbers.1
	2. gencodeid				: >=0 for a genetic code, Universal = 0
	3. treeMode					: default = 0 (NJ) or 1 (User single)
	
OUTPUT:

	ERROR: anyting 
		BranchSiteREL run failed with the stated problem

	[STRING]: the tree string (scaled on expected substitutions under the local model)
	[NMATRIX]: for each branch (postorder), output the results of testing
	[NEXUS]: the alternative model fit
		
*/

/*---------------------------------------------------------------------------------------------------------------------------------------------*/

ExecuteAFile				("../Shared/GrabBag.bf");
ExecuteAFile				("../Shared/ReadDelimitedFiles.bf");
ExecuteAFile				("../Shared/globals.ibf");
ExecuteAFile				("../Shared/CF3x4.bf");
ExecuteAFile				("BranchSiteTemplate.mdl");
ExecuteAFile			 	("../Shared/DescriptiveStatistics.bf");

startTimer 					= Time(1);
fscanf  					(stdin,"String",fileSpec);
fscanf						(stdin,"Number",genCodeID);
fscanf						(stdin,"Number",treeMode);

GetURL 						(dataFileString,BASE_URL_PREFIX+MANGLED_PREFIX+"/"+fileSpec);
GetURL						(analysisSpecRaw, _getTreeLink (fileSpec,treeMode,""));

baseFilePath  				= BASE_CLUSTER_DIR + "Analyses/BranchSiteREL/spool/"+fileSpec;
progressFilePath			= baseFilePath + ".progress";//".progress";
_branchSiteREL		 		= baseFilePath;
outputFilePath				= baseFilePath + ".out"; /* .details file */


cleanupMPI			  = 0;

skipCodeSelectionStep = 1;
ExecuteAFile		("../Shared/chooseGeneticCode.def");
ApplyGeneticCodeTable ( genCodeID );

ExecuteAFile		("../Shared/_MFReader_.ibf");


//BEGIN THE ANALYSIS

omega1 = 0.2;
omega2 = 0.5;
omega3 = 1.0;

nucCF						= CF3x4	(positionFrequencies, GeneticCodeExclusions);

PopulateModelMatrix			  ("MGMatrix1",  nucCF, "t", "omega1", "");
PopulateModelMatrix			  ("MGMatrix2",  nucCF, "t", "omega2", "");
PopulateModelMatrix			  ("MGMatrix3",  nucCF, "t", "omega3", "");

PopulateModelMatrix			  ("MGMatrixLocal",  nucCF, "syn", "", "nonsyn");

codon3x4					= BuildCodonFrequencies (nucCF);
Model		MGL				= (MGMatrixLocal, codon3x4, 0);

T0 = Time (1);

fprintf						  (progressFilePath, CLEAR_FILE, "<DIV class = 'RepClassSM'><b>EPISODIC SELECTION ANALYSIS PROGRESS</b></DIV><DIV class = 'RepClassSM'>Fitting the local MG94 (no site-to-site variation) to obtain initial parameter estimates.</DIV>");

VERBOSITY_LEVEL				= 0;

populateTrees 				   ("givenTree", 1);
LikelihoodFunction	base_LF	 = (filteredData_1, givenTree_1);

//AUTO_PARALLELIZE_OPTIMIZE 	  = 4;
Optimize	(res_base, base_LF);
//AUTO_PARALLELIZE_OPTIMIZE 	  = 0;
OPTIMIZATION_TIME_HARD_LIMIT = (Time(1)-T0)*10;


AC := AC__;
AT := AT__;
CG := CG__;
CT := CT__;
GT := GT__;

/*lfOut	= "phase0.out";
LIKELIHOOD_FUNCTION_OUTPUT = 7;
fprintf (lfOut, CLEAR_FILE, three_LF);
LIKELIHOOD_FUNCTION_OUTPUT = 2;
lfOut = "phase0.mx";
fprintf (lfOut, CLEAR_FILE, res_base);*/

localLL						 = res_base[1][0];
localParams					 = res_base[1][1] + 9;


totalBranchCount			 = BranchCount(givenTree_1) + TipCount (givenTree_1);

pValueByBranch				  = {totalBranchCount,10};
bNames						  = BranchName (givenTree_1, -1);

for (k = 0; k < totalBranchCount; k = k+1)
{
	srate  = Eval ("givenTree_1." + bNames[k] + ".syn");
	nsrate = Eval ("givenTree_1." + bNames[k] + ".nonsyn");
	if (srate > 0)
	{
		pValueByBranch [k][0] = Min (10, nsrate/srate);
	}
	else
	{
		pValueByBranch [k][0] = 10;
	}	
}

omegaStats					 = GatherDescriptiveStats (pValueByBranch[-1][0]);

fprintf						(progressFilePath, CLEAR_FILE, 
									"<DIV class = 'RepClassSM'><b>PHASE 1 Complete</b></DIV>",
									"<DIV class = 'RepClassSM'>Local MG94xREV CF3x4 model fit.",
									"<br>Log L = ", localLL, " with ", localParams, " degrees of freedom\n",
									"<br><pre>");

GLOBAL_FPRINTF_REDIRECT = progressFilePath;
PrintDescriptiveStats		 ("Branch omega values", omegaStats);
GLOBAL_FPRINTF_REDIRECT	= "";

ASSUME_REVERSIBLE_MODELS	  = 1;
USE_LAST_RESULTS              = 1;
OPTIMIZATION_METHOD           = 0;
Tree stepupTree               = givenTree_1;

/*Paux1 						 = 0.3;
Paux1 						 :< 1;
Paux2 						 = 0.4;
Paux2 						 :< 1;
omega1                       :< 1;
omega2                       :< 1;*/

Model 		                  MG1		=		  ("Exp(MGMatrix1)*Paux1+Exp(MGMatrix2)*(1-Paux1)*Paux2+Exp(MGMatrix3)*(1-Paux1)*(1-Paux2)",codon3x4,EXPLICIT_FORM_MATRIX_EXPONENTIAL);


fprintf						  (progressFilePath, "</pre></div><DIV class = 'RepClassSM'>[PHASE 1] Fitting Branch Site REL models to one branch at a time</DIV>");


mg94bls   = BranchLength (givenTree_1,-1);
sortedBLs = {totalBranchCount, 2}["mg94bls[_MATRIX_ELEMENT_ROW_]*(_MATRIX_ELEMENT_COLUMN_==0)+_MATRIX_ELEMENT_ROW_*(_MATRIX_ELEMENT_COLUMN_==1)"];
sortedBLs = sortedBLs%0;
//fprintf (stdout, sortedBLs, "\n");

these_branches_use_mg94 = {};

for (k = 0; k < totalBranchCount; k+=1) {
    reordered_index = sortedBLs[totalBranchCount-k-1][1];
    branch_name_to_test = "stepupTree." + bNames[reordered_index];
    ExecuteCommands ("SetParameter (`branch_name_to_test`, MODEL, MG1);");
    local_branch_name = bNames[reordered_index];
   
    Tree         mixtureTree = stepupTree;


    for (l = 0; l < totalBranchCount; l+=1) {
        if (l != reordered_index) {
            _constrainVariablesAndDescendants ("mixtureTree." + bNames[l]);
        }
    }
    
    
    branch_name_to_test = "mixtureTree." + bNames[reordered_index];
    ExecuteCommands (branch_name_to_test+".Paux1 :< 1");
    ExecuteCommands (branch_name_to_test+".Paux2 :< 1");
    ExecuteCommands (branch_name_to_test+".omega1 :< 1");
    ExecuteCommands (branch_name_to_test+".omega2 :< 1");
    copyomegas (branch_name_to_test, Eval ("givenTree_1." + bNames[reordered_index] + ".syn"), Eval ("givenTree_1." + bNames[reordered_index] + ".nonsyn"));
    
    LikelihoodFunction three_LF = (filteredData_1, mixtureTree);
    Optimize                      (res, three_LF);
    
    fprintf 					  (progressFilePath, "<DIV class = 'RepClassSM'>[PHASE 1] Branch ", bNames[reordered_index], " log(L) = ", res[1][0], "</DIV>");
    Tree stepupTree = mixtureTree;
    
    skip_this_node = checkNodeModel ("mixtureTree.`local_branch_name`");

    if (skip_this_node) {
        branch_name_to_test = "stepupTree.`local_branch_name`";
        ExecuteCommands ("SetParameter (`branch_name_to_test`, MODEL, MGL);");
        ExecuteCommands ("`branch_name_to_test`.syn = givenTree_1.`local_branch_name`.syn");
        ExecuteCommands ("`branch_name_to_test`.nonsyn = givenTree_1.`local_branch_name`.nonsyn");
        fprintf 		(stdout, "\n\tBranch ", local_branch_name, " will use the MG94 model -- either the branch length is 0 or the substitution process is too simple.");
        these_branches_use_mg94 [reordered_index] = 1;
        /*
         _expression = ("`branch_name_to_test`." && 6) + ".+";
        GetInformation (_matchedVars, "`_expression`");
        fprintf (stdout, "\n", _matchedVars, "\n");
        */
    }
}



ClearConstraints (mixtureTree);
unconstrainGlobalParameters ("three_LF");

for (k = 0; k < totalBranchCount; k+=1) {
    if (these_branches_use_mg94 [k] != 1) {
        branch_name_to_test = "mixtureTree." + bNames[k];
        ExecuteCommands (branch_name_to_test+".Paux1 :< 1");
        ExecuteCommands (branch_name_to_test+".Paux2 :< 1");
        ExecuteCommands (branch_name_to_test+".omega1 :< 1");
        ExecuteCommands (branch_name_to_test+".omega2 :< 1");
    }
}
fprintf						  (progressFilePath, "<DIV class = 'RepClassSM'>[PHASE 2] Fitting the full LOCAL alternative model (no constraints)</DIV>");

VERBOSITY_LEVEL				  = 0;
Optimize					  (res_three_LF,three_LF);
VERBOSITY_LEVEL				  = 0;

lfOut	= "phase1.out";
LIKELIHOOD_FUNCTION_OUTPUT = 7;
fprintf (lfOut, CLEAR_FILE, three_LF);
LIKELIHOOD_FUNCTION_OUTPUT = 2;

lfOut = "phase1.mx";
fprintf (lfOut, CLEAR_FILE, res_three_LF);

//return 0;



/*ExecuteAFile 				 ("phase1.out");
fscanf		 				 ("phase1.mx", "NMatrix", res_three_LF);*/

altLL						 = res_three_LF[1][0];
altParams					 = res_three_LF[1][1] + 9;

fprintf						(progressFilePath, CLEAR_FILE, 
									"<DIV class = 'RepClassSM'><b>PHASE 2 Complete</b></DIV>",
									"<DIV class = 'RepClassSM'>Branch REL MG94xREV CF3x4 model fit.",
									"<br>Log L = ", altLL, " with ", altParams, " degrees of freedom.",
									"<br>A global test for site-variable selective pressures (vs local MG94xREV): p = ", 1-CChi2(2*(altLL-localLL),altParams-localParams), "</DIV>");

SHORT_MPI_RETURN = 1;
MPI_NODE_STATUS = {MPI_NODE_COUNT-1, 1}["-1"];

k = 0;

while (k < totalBranchCount)
{
	for							  (k = 0; k < totalBranchCount; k = k+1)
	{
		ref = "mixtureTree."+bNames[k];
		
		thisOmega3 = Eval (ref+".omega3");
		wt3        = Eval ("(1-"+ref+".Paux1)*(1-"+ref+".Paux2)");
	
		pValueByBranch [k][1] = Eval (ref+".omega1");
		pValueByBranch [k][2] = Eval (ref+".Paux1");
		pValueByBranch [k][3] = Eval (ref+".omega2");
		pValueByBranch [k][4] = Eval ("(1-"+ref+".Paux1)*"+ref+".Paux2");
		pValueByBranch [k][5] = thisOmega3;
		pValueByBranch [k][6] = wt3;
		
		fscanf  (progressFilePath, REWIND, "Raw", previousFile);
		fprintf (progressFilePath, CLEAR_FILE,  "<DIV class = 'RepClassSM'><DL><DT class = 'DTH'>Branch: ", ref, 
						 "</DT><DT class = 'DT1'>Class 1: omega = ", Format(Eval (ref+".omega1"),5,2), " weight = ", Format(Eval (ref+".Paux1"),5,2),
						 "</DT><DT class = 'DT2'>Class 2: omega = ", Format(Eval (ref+".omega2"),5,2), " weight = ", Format(Eval ("(1-"+ref+".Paux1)*"+ref+".Paux2"),5,2),
						 "</DT><DT class = 'DT1'>Class 3: omega = ", Format(thisOmega3,5,2), " weight = ", Format(wt3,5,2) , "</DT>",
						 "</DT><DT class = 'DT2'>"
						 );
			
		if (thisOmega3 > 1 && wt3 > 1e-6 && these_branches_use_mg94 [k] != 1)
		{
			_stashLF = saveLF ("three_LF");
			ExecuteCommands ("mixtureTree." + bNames[k] + ".omega3 := 1");
			if (SendAJob 					  (k) == 0)
			{
				break;
			}
			ExecuteCommands ("mixtureTree." + bNames[k] + ".omega3 :< 1e26");
			_stashLF ["restoreLF"][""];
		}
		else
		{
			pValueByBranch[k][8] = 1.0;
			fprintf (progressFilePath, "<span style = 'color:red'>No sites with &omega;&gt;1 along this branch.</span></DT></DL></DIV>", previousFile);
		}
	}
	
	CleanUpMPI ();
}


OPTIMIZATION_METHOD = 4;

pValueSorter = {totalBranchCount,2};
pValueSorter = pValueSorter["_MATRIX_ELEMENT_ROW_*(_MATRIX_ELEMENT_COLUMN_==0)+pValueByBranch[_MATRIX_ELEMENT_ROW_][8]*(_MATRIX_ELEMENT_COLUMN_==1)"];
pValueSorter = pValueSorter % 1;
pValueSorter = pValueSorter["_MATRIX_ELEMENT_VALUE_*(_MATRIX_ELEMENT_COLUMN_==0)+_MATRIX_ELEMENT_VALUE_*(totalBranchCount-_MATRIX_ELEMENT_ROW_)*(_MATRIX_ELEMENT_COLUMN_==1)"];

for		(k = 0; k < totalBranchCount; k = k+1)
{
	pValueByBranch[pValueSorter[k][0]][9] = Min (1,pValueSorter[k][1]);
}

LIKELIHOOD_FUNCTION_OUTPUT = 7;
fprintf 			(outputFilePath,   Format (givenTree_1, 1, 1), "\n", pValueByBranch, "\n", three_LF);
fprintf 			(progressFilePath, CLEAR_FILE, "DONE");
GetString 			(HTML_OUT, TIME_STAMP, 1);

/*usage log: taxa, sites, time, proportion of branches under selection, mean proportion of sites with omega > 1 */

propUnderSelection = +((pValueSorter[-1][1])["_MATRIX_ELEMENT_VALUE_ <= 0.05"]);
omegaOver1 = 0;
for (k = 0; k < totalBranchCount; k+=1)
{
	if (pValueByBranch[k][5] > 1.)
	{
		omegaOver1 += pValueByBranch[k][6];
	}
}

fprintf  			("usage.log",HTML_OUT[0][Abs(HTML_OUT)-2],",",filteredData_1.species,",",filteredData_1.sites,",",Time(1)-startTimer,",",propUnderSelection/totalBranchCount, ",",  omegaOver1/totalBranchCount, "\n");

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function SendAJob (bID)
{
	fprintf (progressFilePath, "<span style = 'color:green'>Testing for selection at branch ", ref, "</span></DT></DL></DIV>", previousFile);
	for (nodeID = 0; nodeID < MPI_NODE_COUNT - 1; nodeID += 1) {
		if (MPI_NODE_STATUS[nodeID] < 0) {
			break;
		}
	}
	if (nodeID == MPI_NODE_COUNT - 1) {
		nodeID = ReceiveJobs (0)-1;
	}
	
	if (nodeID >= 0) {
		MPI_NODE_STATUS[nodeID] = bID;
		MPISend (nodeID + 1, three_LF);
		return 1;
	}
		
	return 0;
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function ReceiveJobs (rereadPrevious)
{
	MPIReceive  				   (-1, from, result);
	ExecuteCommands (result);

	branchID = MPI_NODE_STATUS[from-1];
	MPI_NODE_STATUS[from-1] = -1;
	
	pValueByBranch[branchID][7]			  = 2*(-three_LF_MLES[1][0] + res_three_LF[1][0]);				 
	pValueByBranch[branchID][8]			  = (1-CChi2 (pValueByBranch[branchID][7],1))*.5;

	if (pValueByBranch[branchID][7] < (-1.))
	{
		fprintf 					  (progressFilePath, CLEAR_FILE, "<DIV class = 'RepClassSM'>[PHASE 2/REPEAT] Detected a convergence problem. <br> The log likelihood from the null model for branch ",
																	  bNames[branchID]," is ",three_LF_MLES[1][0],"<br>Refitting the LOCAL alternative model with new starting values.</DIV>");
																	  
		//fprintf (stdout, pValueByBranch, "\n", three_LF_MLES, "\n", res_three_LF, "\n");
		
		three_LF_MLE_VALUES 		  ["restoreLF"][""];
		
		for (bid = 0; bid < totalBranchCount; bid += 1) {
			ExecuteCommands ("mixtureTree." + bNames[bid] + ".omega3 :< 1e26");		
		}

		if (cleanupMPI == 0)
		{
			CleanUpMPI 					  ();
		
		
			VERBOSITY_LEVEL = 0;
			AUTO_PARALLELIZE_OPTIMIZE 	  = 4;
			Optimize					  (res_three_LF,three_LF);
			AUTO_PARALLELIZE_OPTIMIZE 	  = 0;
			_stashLF = saveLF ("three_LF");
			VERBOSITY_LEVEL = 0;
			k = 0;
		}
		return -1;
	}
	else
	{				
		if (rereadPrevious)
		{
			fscanf  (progressFilePath, REWIND, "Raw", previousFile);
		    fprintf (progressFilePath,CLEAR_FILE, "<DIV class = 'RepClassSM'>UNCORRECTED p-value for branch ", bNames[branchID] ," = ", Format(pValueByBranch[branchID][8],5,2),".<br/>log(L) = ", Format(three_LF_MLES[1][0],9,2),".</DIV>", previousFile);
		}
		else
		{
		    fprintf (progressFilePath,"<DIV class = 'RepClassSM'>UNCORRECTED p-value for branch ", bNames[branchID] ," = ", Format(pValueByBranch[branchID][8],5,2),".<br/>log(L) = ", Format(three_LF_MLES[1][0],9,2),".</DIV>");
		}
	}
	
	return from;		
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
function CleanUpMPI ()
{
	totalLeft   = + (MPI_NODE_STATUS["_MATRIX_ELEMENT_VALUE_ >= 0"]);
	cleanupMPI = cleanupMPI + 1;
	
	for (nodeID = 0; nodeID < totalLeft; nodeID += 1)
	{
		ReceiveJobs (1);
	}
	cleanupMPI = cleanupMPI - 1;
	return 0;
}


//------------------------------------------------------------------------------------------------------------------------
function saveLF (ID)
{
	ExecuteCommands ("GetString(_lfInfo,"+ID+",-1)");
	_stashLF = {};
	for (_k = 0; _k < Columns (_lfInfo["Global Independent"]); _k+=1) {
		_stashLF [(_lfInfo["Global Independent"])[_k]] = Eval ((_lfInfo["Global Independent"])[_k]);
	}
	for (_k = 0; _k < Columns (_lfInfo["Local Independent"]); _k+=1) {
		_stashLF [(_lfInfo["Local Independent"])[_k]] = Eval ((_lfInfo["Local Independent"])[_k]);
	}
	
	return _stashLF;
}

//------------------------------------------------------------------------------------------------------------------------

function restoreLF (key, value)
{
	ExecuteCommands (key + " = " + value);
	return 0;
}

//------------------------------------------------------------------------------------------------------------------------

function copyomegas (node, syn, nonsyn) {
    local_omega = =  Min (10, nonsyn/syn);
    Eval("`node`.omega2 = 1");
    if (local_omega < 1) {
        Eval("`node`.Paux1 = 1");
        Eval("`node`.Paux2 = 0");
        Eval("`node`.omega1 =  local_omega");
        Eval("`node`.omega3 = 10");
    } else {
        Eval("`node`.Paux1 = 0");
        Eval("`node`.Paux2 = 0");
        Eval("`node`.omega3 =  local_omega");
        Eval("`node`.omega1 = 0");    
    }
    Eval("`node`.t = syn");
    return 0;
    
}


/*---------------------------------------------------------------------*/

lfunction _constrainVariablesAndDescendants (variable) {
    GetInformation (allVars, "^" + (variable&&6) + "\\..+$");
    for (k = 0; k < Columns (allVars); k += 1) {
        variableID    = allVars[k];
        current_value = ^variableID;
        ^variableID := current_value__;
    }
    return 0;
}

/*---------------------------------------------------------------------*/

lfunction _unconstrainVariablesAndDescendants (variable) {
    GetInformation (allVars, "^" + (variable&&6) + "\\..+$");
    for (k = 0; k < Columns (allVars); k += 1) {
        variableID    = allVars[k];
        ClearConstraints (^variableID);
    }
    return 0;
}

/*---------------------------------------------------------*/
/* fix global variables in a LF at their current values */
   
function fixGlobalParameters (_lfName) {
	GetString (_lfInfo,^_lfName,-1);
	_lfInfo = _lfInfo["Global Independent"];
	for (_gb_idx = 0; _gb_idx < Columns (_lfInfo); _gb_idx += 1) {
		ExecuteCommands (_lfInfo[_gb_idx] + ":=" + _lfInfo[_gb_idx] + "__;");
	} 	
	return 0;
}

/*---------------------------------------------------------*/
/* unconstrain global variables in a LF at their current values */
   
function unconstrainGlobalParameters (_lfName) {
	GetString (_lfInfo,^_lfName,-1);
	_lfInfo = _lfInfo["Global Constrained"];
	for (_gb_idx = 0; _gb_idx < Columns (_lfInfo); _gb_idx += 1) {
		ExecuteCommands (_lfInfo[_gb_idx] + "=" + _lfInfo[_gb_idx]);
	} 	
	return 0;
}

function checkNodeModel (ref) {
    wts = {{ Eval (ref+".Paux1"), Eval ("(1-"+ref+".Paux1)*"+ref+".Paux2"), Eval ("(1-"+ref+".Paux1)*(1-"+ref+".Paux2)")}};
                 
    return (Eval (ref+".t") == 0 || wts[0] == 1 || wts[1] == 1);

}