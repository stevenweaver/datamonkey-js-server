ExecuteAFile("../Shared/HyPhyGlobals.ibf");ExecuteAFile("../Shared/GrabBag.bf");fscanf		(stdin,"String", filePrefix);fscanf		(stdin,"Number", optionOutput);/* ________________________________________________________________________________________________*/if (optionOutput == 1 || optionOutput == 2){	ExecuteAFile	("../Shared/DBTools.ibf");	slacDBID 		 = _openCacheDB      (filePrefix);	if (optionOutput == 1)	{		generalInfo = _ExecuteSQL  (slacDBID,"SELECT * FROM SUBTYPING_RESULTS ORDER BY FILE_INDEX");					fprintf 	  (stdout, "Index\tName\tSubtype\tExpanded subtype\tConfidence in Assignment\tSupport for recombination\tSupport for intra-subtype recombination\tBreakpoints\tSequence");				for (k = 0; k < Abs(generalInfo); k = k+1)		{			cleanName = (generalInfo[k])["ID"];			fprintf 	  (stdout, "\n", (generalInfo[k])["FILE_INDEX"], "\t",cleanName ,"\t", (generalInfo[k])["SIMPLIFIED"]);			if ((generalInfo[k])["SUBTYPE"] != "FAILED")			{				fprintf 	  (stdout, "\t", (generalInfo[k])["SUBTYPE"], "\t",											(generalInfo[k])["SUPPORT"], "\t",											(generalInfo[k])["REC_SUPPORT"], "\t",											(generalInfo[k])["INTRA_REC_SUPPORT"], "\t",											(generalInfo[k])["BREAKPOINTS"], "\t",											(generalInfo[k])["SEQUENCE"]							 );						}		}	}	else	{		generalInfo = _ExecuteSQL  (slacDBID,"SELECT SIMPLIFIED, COUNT(*) AS CNT FROM SUBTYPING_RESULTS GROUP BY SIMPLIFIED ORDER BY SIMPLIFIED");			totalCount  = _ExecuteSQL  (slacDBID,"SELECT COUNT(*) AS CNT FROM SUBTYPING_RESULTS");		totalCount  = 0 + (totalCount[0]);		cnt = Abs (generalInfo);		fprintf (stdout, "Subtype\tCount\tProportion");		for (k = 0; k < cnt; k = k + 1)		{			fprintf (stdout, "\n", (generalInfo[k])["SIMPLIFIED"], "\t", (generalInfo[k])["CNT"], "\t", Format ((0+(generalInfo[k])["CNT"])/totalCount*100, 5, 2), "%");		}			}	_closeCacheDB (slacDBID);}else{	defaultErrorOut ("Unsupported Format");}