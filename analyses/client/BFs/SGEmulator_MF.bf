ExecuteAFile("binomial.ibf");/*___________________________________________________________________________________________________________*/nucCharacters="ACGT";function codonString (ccode){	return nucCharacters[ccode$16]+nucCharacters[(ccode%16)$4]+nucCharacters[ccode%4];}/*----------------------------------------------------------------------------*/ambChoice = _in_dNdSAmbigs;if (useCustomCountingBias){	ExecuteAFile("Distances/CodonToolsMain.def");}else{	ExecuteAFile("Distances/CodonTools.def");}mutationRecord			  = {};observedCEFV 		  = {64,1};for (fileID = 1; fileID <= fileCount; fileID = fileID + 1){	ExecuteCommands 	  		("HarvestFrequencies (tp, filteredData_"+fileID+",3,3,0);cfs = filteredData_"+fileID+".sites;");	observedCEFV 				= observedCEFV 		 + tp*(cfs/totalCodonCount);}seqToBranchMap 				  			= {stateCharCount,1};senseCodonMap							= {stateCharCount,1};hShift = 0;for (k=0; k<64; k=k+1){	if (_Genetic_Code[k]==10)	{		hShift = hShift+1;	}	else	{		seqToBranchMap[k-hShift] = observedCEFV[k];		senseCodonMap[k-hShift] = _Genetic_Code[k];	}}observedCEFV = seqToBranchMap;vOffset 	 = 0;resultMatrix = {totalCodonCount,12};treeLengthArray = {};OPTIMIZE_SUMMATION_ORDER = 0;perBranchSubstitutions	 = {};for (fileID = 1; fileID <= fileCount; fileID = fileID + 1){	mutationRecord ["Partition"] = fileID;		ExecuteCommands ("LikelihoodFunction tempLF 				= (filteredData_"+fileID+",codonTree_"+fileID+");");	DataSet 		dsA		 									= ReconstructAncestors (tempLF);	ExecuteCommands ("DataSet		   	dsJoint 				= Combine(dsA,ds_"+fileID+");");	ExecuteCommands ("DataSetFilter		filteredData 			= CreateFilter (ds_"+fileID+",3,\"\",\"\",GeneticCodeExclusions);");		DataSetFilter 	filteredDataA = CreateFilter (dsA,3,"","",GeneticCodeExclusions);	DataSetFilter  filteredDataJ  = CreateFilter (dsJoint,3,"","",GeneticCodeExclusions);	ExecuteCommands ("branchNames = BranchName (codonTree_"+fileID+",-1);");	h 			= Columns (branchNames);	seqToBranchMap 	= {h, 2};	/* maps sequence names to branch order in column 1 	   and the other way around in column 2 */	GetString	   (ancsNames,      filteredDataA, -1);	GetString	   (givenSeqNames,  filteredData, -1);	for (k=0; k<filteredData.species; k=k+1)	{		seqName = givenSeqNames[k];		seqToBranchMap[k][0] = -1;		for (v=0; v<h; v=v+1)		{			if (branchNames[v] % seqName)			{				seqToBranchMap[k][0] = v;				seqToBranchMap[v][1] = k;				break;			}		}	}	seqToBranchMap[filteredData.species][0] = h-1;	seqToBranchMap[h-1][1] = filteredData.species;	for (k=1; k<filteredDataA.species; k=k+1)	{		seqName = ancsNames[k];		seqToBranchMap[filteredData.species+k][0] = -1;		for (v=0; v<h; v=v+1)		{			if (branchNames[v] % seqName)			{				seqToBranchMap[k+filteredData.species][0] = v;				seqToBranchMap[v][1] = k+filteredData.species;				break;			}		}	}	/* total tree length */	totalTreeLength = 0;		ExecuteCommands ("branchLengths   = BranchLength(nucTree_"+fileID+",-1);");	totalTreeLength = (branchLengths*(Transpose(branchLengths)["1"]))[0];		treeLengthArray [fileID] = totalTreeLength;	/* get codon matrix */	codonInfo  = {filteredData.species, filteredData.unique_sites};	codonInfo2 = {filteredDataA.species, filteredDataA.unique_sites};	GetDataInfo    (dupInfo, filteredData);	GetDataInfo	   (dupInfoA, filteredDataA);	matrixTrick  = {1,stateCharCount}["_MATRIX_ELEMENT_COLUMN_"];	matrixTrick2 = {1,stateCharCount}["1"];		for (v=0; v<filteredData.unique_sites;v=v+1)	{		for (h=0; h<filteredData.species;h=h+1)		{			GetDataInfo (siteInfo, filteredData, h, v);			if ((matrixTrick2 * siteInfo)[0] == 1)			{				codonInfo[h][v] = (matrixTrick * siteInfo)[0];			}			else			{				codonInfo[h][v] = -1;			}		}	}	for (v=0; v<filteredDataA.unique_sites;v=v+1)	{		for (h=0; h<filteredDataA.species;h=h+1)		{			GetDataInfo (siteInfo, filteredDataA, h, v);			if ((matrixTrick2 * siteInfo)[0] == 1)			{				codonInfo2[h][v] = (matrixTrick * siteInfo)[0];			}			else			{				codonInfo2[h][v] = -1;			}		}	}	_SITE_RESULTS = {4,filteredData.sites};	ExecuteCommands ("flatTreeRep	  = Abs (nucTree_"+fileID+");");	GetInformation (filterStrings, filteredData);	GetInformation (filterStringsA, filteredDataA);	for (v=0; v<filteredData.sites;v=v+1)	{		mutationRecord ["Site"] = v+1;		mutationRecord ["AbsSite"] = v+1+vOffset;		_SITE_ES_COUNT = {stateCharCount,stateCharCount};		_SITE_EN_COUNT = {stateCharCount,stateCharCount};		_SITE_OS_COUNT = {stateCharCount,stateCharCount};		_SITE_ON_COUNT = {stateCharCount,stateCharCount};				/* do internal nodes first */				k = filteredData.species+1;				/* first sequence is always the root */		c1 = dupInfoA[v];		if (codonInfo2[1][c1] < 0) /* gap at the root; nothing to do */		{			continue;		}		for (h=1; h<filteredDataA.species; h=h+1)		{			p2 			= seqToBranchMap[flatTreeRep[seqToBranchMap[k][0]]][1]-filteredData.species;						branchFactor = branchLengths[p1]/totalTreeLength;						cd1 = codonInfo2[h] [c1];			cd2 = codonInfo2[p2][c1];						if (cd1 < 0)			{				continue;			}			if (cd2 < 0)			{				continue;			}						if (Abs(cd1-cd2)>0) /* different codons */			{				mutationRecord 	   ["Branch"] 		    = ancsNames[h];				mutationRecord 	   ["EndCodon"]			= (filterStringsA[h])[v*3][v*3+2];				mutationRecord 	   ["StartCodon"]		= (filterStringsA[p2])[v*3][v*3+2];				mutationRecord 	   ["EndAA"]			= senseCodonMap[cd1];				mutationRecord 	   ["StartAA"]			= senseCodonMap[cd2];				mutationRecord 	   ["S"]				= _OBSERVED_S_[cd1][cd2];				mutationRecord 	   ["NS"]				= _OBSERVED_NS_[cd1][cd2];				_InsertRecord 		(slacDBID,"SLAC_MUTATION", mutationRecord);						}						_SITE_OS_COUNT[cd1][cd2] = _SITE_OS_COUNT[cd1][cd2] + 1;					_SITE_ON_COUNT[cd1][cd2] = _SITE_ON_COUNT[cd1][cd2] + 1;					_SITE_ES_COUNT[cd1][cd2] = _SITE_ES_COUNT[cd1][cd2] + branchFactor;					_SITE_EN_COUNT[cd1][cd2] = _SITE_EN_COUNT[cd1][cd2] + branchFactor;											k=k+1;		}				/* now do the leaves */				observedCEFV = {{0}};				c2 = dupInfo[v];		for (h=0; h<filteredData.species; h=h+1)		{			p1 = seqToBranchMap[h][0];			p2 = flatTreeRep[p1];			p2 = seqToBranchMap[p2][1]-filteredData.species;						cd2 = codonInfo2[p2][c1];			cd1 = codonInfo[h] [c2];						if (cd2 < 0)			{				continue;			}									branchFactor = branchLengths[p1]/totalTreeLength;			if (cd1>=0)			/* no ambiguities */			{				_SITE_OS_COUNT[cd1][cd2] = _SITE_OS_COUNT[cd1][cd2] + 1;						_SITE_ON_COUNT[cd1][cd2] = _SITE_ON_COUNT[cd1][cd2] + 1;						_SITE_ES_COUNT[cd1][cd2] = _SITE_ES_COUNT[cd1][cd2] + branchFactor;						_SITE_EN_COUNT[cd1][cd2] = _SITE_EN_COUNT[cd1][cd2] + branchFactor;						if (Abs(cd1-cd2)>0) /* different codons */				{					mutationRecord 	   ["Branch"] 		    = branchNames[p1];					mutationRecord 	   ["EndCodon"]	      	= (filterStrings[h])[v*3][v*3+2];					mutationRecord 	   ["StartCodon"]	    = (filterStringsA[p2])[v*3][v*3+2];					mutationRecord 	   ["EndAA"]			= senseCodonMap[cd1];					mutationRecord 	   ["StartAA"]			= senseCodonMap[cd2];					mutationRecord 	   ["S"]				= _OBSERVED_S_[cd1][cd2];					mutationRecord 	   ["NS"]				= _OBSERVED_NS_[cd1][cd2];					_InsertRecord 		(slacDBID,"SLAC_MUTATION", mutationRecord);							}			}				else			/* ambiguities here */			{				mutationRecord 	   ["Branch"] 		= givenSeqNames[h];				mutationRecord 	   ["EndCodon"]		= (filterStrings[h])[v*3][v*3+2];				mutationRecord 	   ["StartCodon"]	= (filterStringsA[p2])[v*3][v*3+2];				mutationRecord 	   ["StartAA"]		= senseCodonMap[cd2];				mutationRecord 	   ["EndAA"]		= -1;								GetDataInfo    (ambInfo, filteredData, h, c2);					if (Rows(observedCEFV) == 1)				{					siteFilter = ""+(v*3)+"-"+(v*3+2);					DataSetFilter filteredDataSite = CreateFilter (dsJoint,3,siteFilter,"",GeneticCodeExclusions);					HarvestFrequencies			  (observedCEFV,filteredDataSite,3,3,0);					tempMx = {stateCharCount,1};					hShift = 0;					for (k=0; k<64; k=k+1)					{						if (_Genetic_Code[k]==10)						{							hShift = hShift+1;						}						else						{							tempMx[k-hShift] = observedCEFV[k];						}					}						observedCEFV = tempMx;						}								weightFactor = matrixTrick2*ambInfo;				if (weightFactor[0]<stateCharCount)				{					ambInfo  	 = ambInfo$observedCEFV;										if (ambChoice)					{						weightFactor = 0;						tempMx = -1;						for (k=0; k<stateCharCount; k=k+1)						{							if (ambInfo[k]>weightFactor)							{								weightFactor = ambInfo[k];								tempMx = k;							}						}						if (tempMx>=0)						{							_SITE_OS_COUNT[tempMx][cd2] = _SITE_OS_COUNT[tempMx][cd2] + 1;									_SITE_ON_COUNT[tempMx][cd2] = _SITE_ON_COUNT[tempMx][cd2] + 1 ;									_SITE_ES_COUNT[tempMx][cd2] = _SITE_ES_COUNT[tempMx][cd2] + branchFactor;									_SITE_EN_COUNT[tempMx][cd2] = _SITE_EN_COUNT[tempMx][cd2] + branchFactor;									mutationRecord 	   ["S"]				= _OBSERVED_S_[tempMx][cd2];							mutationRecord 	   ["NS"]				= _OBSERVED_NS_[tempMx][cd2];							mutationRecord 	   ["EndAA"]			= senseCodonMap[tempMx];						}					}					else					{						weightFactor = matrixTrick2*ambInfo;						weightFactor = weightFactor[0];						mutationRecord 	   ["S"] = 0;						mutationRecord 	   ["NS"] = 0;												canResolve = -1;						 						if (weightFactor)						{							ambInfo		 = ambInfo * (1/weightFactor);							for (k=0; k<stateCharCount; k=k+1)							{								weightFactor = ambInfo[k];								if (weightFactor>0)								{									_SITE_OS_COUNT[k][cd2] = _SITE_OS_COUNT[k][cd2] + weightFactor;											_SITE_ON_COUNT[k][cd2] = _SITE_ON_COUNT[k][cd2] + weightFactor;											_SITE_ES_COUNT[k][cd2] = _SITE_ES_COUNT[k][cd2] + weightFactor*branchFactor;											_SITE_EN_COUNT[k][cd2] = _SITE_EN_COUNT[k][cd2] + weightFactor*branchFactor;									mutationRecord 	   ["S"]				= mutationRecord 	   ["S"] + weightFactor*_OBSERVED_S_[k][cd2];									mutationRecord 	   ["NS"]				= mutationRecord 	   ["NS"] + weightFactor*_OBSERVED_NS_[k][cd2];									if (canResolve >= 0)									{										if (canResolve != senseCodonMap[k])												{											canResolve = -2;										}									}									else									{										if (canResolve == (-1))										{											canResolve = senseCodonMap[k];										}									}									}							}														if (canResolve >= 0)							{								mutationRecord ["EndAA"] = canResolve;							}						}					}					_InsertRecord 		(slacDBID,"SLAC_MUTATION", mutationRecord);							}			}		}				_SITE_OS_COUNT = matrixTrick2*(_OBSERVED_S_$_SITE_OS_COUNT)*Transpose(matrixTrick2);		_SITE_ON_COUNT = matrixTrick2*(_OBSERVED_NS_$_SITE_ON_COUNT)*Transpose(matrixTrick2);		_SITE_ES_COUNT = matrixTrick2*(_PAIRWISE_S_$_SITE_ES_COUNT)*Transpose(matrixTrick2);		_SITE_EN_COUNT = matrixTrick2*(_PAIRWISE_NS_$_SITE_EN_COUNT)*Transpose(matrixTrick2);				shiftedV = v+vOffset;				resultMatrix[shiftedV][0] = _SITE_OS_COUNT[0];		resultMatrix[shiftedV][1] = _SITE_ON_COUNT[0];		resultMatrix[shiftedV][2] = _SITE_ES_COUNT[0];		resultMatrix[shiftedV][3] = _SITE_EN_COUNT[0];				if (_onlyDoAncestralReconstruction == 0)		{			p = _SITE_ES_COUNT[0]/(_SITE_EN_COUNT[0]+_SITE_ES_COUNT[0]);						resultMatrix[shiftedV][5] = p;						p2 = resultMatrix[shiftedV][0]+resultMatrix[shiftedV][1];						resultMatrix[shiftedV][7] = resultMatrix[shiftedV][1]/resultMatrix[shiftedV][3];						if (resultMatrix[shiftedV][2])			{				resultMatrix[shiftedV][6]  = resultMatrix[shiftedV][0]/resultMatrix[shiftedV][2];				resultMatrix[shiftedV][8]  = resultMatrix[shiftedV][7]-resultMatrix[shiftedV][6];					resultMatrix[shiftedV][11] = resultMatrix[shiftedV][8]/totalTreeLength;				}						if (p2)			{				resultMatrix[shiftedV][4]  = resultMatrix[shiftedV][0]/p2;						resultMatrix[shiftedV][9]  = extendedBinTail (p2,p,resultMatrix[shiftedV][0]);								if (resultMatrix[shiftedV][0]>=1)				{					resultMatrix[shiftedV][10] = 1-extendedBinTail(p2,p,resultMatrix[shiftedV][0]-1);				}				else				{					resultMatrix[shiftedV][10] = 1-extendedBinTail (p2,p,0);				}			}				}	}			vOffset = vOffset + filteredData.sites;}/*labelMatrix 			= {1,12};labelMatrix[0] 			= "Observed S Changes";labelMatrix[1] 			= "Observed NS Changes";labelMatrix[2] 			= "E[S Sites]";labelMatrix[3] 			= "E[NS Sites]";labelMatrix[4] 			= "Observed S. Prop.";labelMatrix[5] 			= "P{S}";labelMatrix[6] 			= "dS";labelMatrix[7] 			= "dN";labelMatrix[8] 			= "dN-dS";labelMatrix[9]  		= "P{S leq. observed}";labelMatrix[10] 		= "P{S geq. observed}";labelMatrix[11] 		= "Scaled dN-dS";*/if (_onlyDoAncestralReconstruction == 0){	sigLevel 				= _in_dNdSPValue;	posSelected 			= 0;	negSelected 			= 0;	p = Rows(resultMatrix);	siteRecord = {};	for (p2=0; p2<p; p2=p2+1)	{		siteRecord ["FIELD_0"] = p2;		for (v = 0; v<12; v=v+1)		{			siteRecord["FIELD_"+(v+1)] = resultMatrix[p2][v];		}		_InsertRecord (slacDBID,"SLAC_RESULTS", siteRecord);		v = resultMatrix [p2][8];		if (resultMatrix[p2][0]+resultMatrix[p2][1] >= 1.0)		{			if (v>0 )			{				if (resultMatrix [p2][9] < sigLevel)				{					posSelected = posSelected+1;				}			}			else			{				if (v<0)				{					if (resultMatrix [p2][10] < sigLevel)					{						negSelected = negSelected+1;					}				}			}		}	}	fprintf (intermediateHTML,"<p>Using significance level ", sigLevel);	if (posSelected)	{		psMatrix = {posSelected, 3};		h = 0;		for (p2=0; p2<p; p2=p2+1)		{			v = resultMatrix [p2][8];			if (v>0)			{				if ((resultMatrix [p2][9] < sigLevel)&& (resultMatrix[p2][0]+resultMatrix[p2][1] >= 1.0))				{					psMatrix[h][0] = p2+1;					psMatrix[h][1] = v;					psMatrix[h][2] = resultMatrix [p2][9];					h = h+1;				}			}		}			fprintf (intermediateHTML,"<p>Found ", posSelected, " positively selected sites</p>");	}	else	{		fprintf (intermediateHTML,"<p>Found no positively selected sites</p>");	}	if (negSelected)	{		psMatrix = {negSelected, 3};		h = 0;		for (p2=0; p2<p; p2=p2+1)		{			v = resultMatrix [p2][8];			if (v<0)			{				if ((resultMatrix [p2][10] < sigLevel)&& (resultMatrix[p2][0]+resultMatrix[p2][1] >= 1.0))				{					psMatrix[h][0] = p2+1;					psMatrix[h][1] = v;					psMatrix[h][2] = resultMatrix [p2][10];					h = h+1;				}			}		}				fprintf (intermediateHTML,"<p>Found ", negSelected, " negatively selected sites </p>");	}	else	{		fprintf (intermediateHTML,"<p>Found no negtively selected sites</p>");	}}