ExecuteAFile("../Shared/HyPhyGlobals.ibf");ExecuteAFile("../Shared/GrabBag.bf");fscanf		(stdin,"String", filePrefix);fscanf		(stdin,"Number", optionOutput);if (optionOutput >= 4){	fscanf		(stdin,"String", gnuplotFormat);	fscanf		(stdin,"String", style);	fscanf		(stdin,"String", xaxis);	fscanf		(stdin,"String", yaxis);	fscanf		(stdin,"String", size);} /* ________________________________________________________________________________________________*/function ErrorOut (errString){	fprintf (stdout, "ERROR:<DIV class = 'ErrorTagSM'>\n", errString, "\n</DIV>");	return 0;}/* ________________________________________________________________________________________________*/baseAIC    = 0;baseAICc   = 0;baseBIC	   = 0;canUseAICc = 1;DB_FIELD_MAP = {};DB_FIELD_MAP [0] = "Site";DB_FIELD_MAP [1] = "Tree1Length";DB_FIELD_MAP [2] = "Tree2Length";DB_FIELD_MAP [3] = "SplitsMatch";DB_FIELD_MAP [4] = "RF";DB_FIELD_MAP [5] = "AIC";DB_FIELD_MAP [6] = "wAIC";DB_FIELD_MAP [7] = "cAIC";DB_FIELD_MAP [8] = "wcAIC";DB_FIELD_MAP [9] = "BIC";DB_FIELD_MAP [10] = "wBIC";if (optionOutput!=2){	ExecuteAFile	("../Shared/DBTools.ibf");	slacDBID 		 = _openCacheDB      (filePrefix);	if (optionOutput != 3)	{		baseAIC = 0+(_ExecuteSQL  (slacDBID,"SELECT COL_VALUE FROM SBP_SUMMARY WHERE COL_KEY = 'baseAIC'"))[0];		baseAICc = 0+(_ExecuteSQL  (slacDBID,"SELECT COL_VALUE FROM SBP_SUMMARY WHERE COL_KEY = 'baseAICc'"))[0];		baseBIC = 0+(_ExecuteSQL  (slacDBID,"SELECT COL_VALUE FROM SBP_SUMMARY WHERE COL_KEY = 'baseBIC'"))[0];		canUseAICc = 0+(_ExecuteSQL  (slacDBID,"SELECT COL_VALUE FROM SBP_SUMMARY WHERE COL_KEY = 'canUseAICc'"))[0];	}	genCodeID = (_ExecuteSQL  (slacDBID,"SELECT * FROM FILE_INFO"))[0];	ExecuteCommands ("IC_Matrix = " + (_ExecuteSQL  (slacDBID,"SELECT COL_VALUE FROM SBP_SUMMARY WHERE COL_KEY = 'bestScores'"))[0]);}if (optionOutput < 2){	generalInfo = _ExecuteSQL  (slacDBID,"SELECT * FROM SBP_TREES ORDER BY Site");	titleMatrix 	= {1,11};	titleMatrix[0]  = "Site";	titleMatrix[1]  = "Tree 1 Length (subs/site)";	titleMatrix[2]  = "Tree 2 Length (subs/site)";	titleMatrix[3]  = "Splits identity";	titleMatrix[4]  = "Robinson Foulds distance";	titleMatrix[5]  = "AIC";	titleMatrix[6]  = "AIC support";	if (optionOutput == 1)	{		titleMatrix[7]  = "c-AIC";		titleMatrix[8]  = "c-AIC support";	}	else	{		titleMatrix[7]  = "AIC<sub>c</sub>";		titleMatrix[8]  = "AIC<sub>c</sub> support";	}		titleMatrix[9]  = "BIC";	titleMatrix[10]  = "BIC support";	rowCount = Abs	   (generalInfo);	colCount = Columns (titleMatrix);	sbpInfo = {rowCount, colCount};	for (r=0; r<rowCount; r=r+1)	{		for (c=0; c<colCount; c=c+1)		{			fieldLookup = DB_FIELD_MAP [c];			if (Abs(fieldLookup))			{				sbpInfo[r][c] = (generalInfo[r])[fieldLookup]; 			}			else			{				sbpInfo[r][c] = "N/A"; 								}		}	}	if (optionOutput == 1) /* CSV */	{		fprintf (stdout, titleMatrix[0]);		for (r=1; r<colCount; r=r+1)		{			fprintf (stdout, ",", titleMatrix[r]);		}		for (r=0; r<rowCount; r=r+1)		{			fprintf (stdout, "\n", sbpInfo[r][0]);			for (c=1; c<colCount; c=c+1)			{				fprintf (stdout, ",", sbpInfo[r][c]);			}		}	}	else	{		fprintf (stdout, "<H1 CLASS = 'SuccessCap'>Detailed SBP results</H1>");		fprintf (stdout, _makeJobIDHTML (filePrefix));		fprintf (stdout, "<DIV CLASS = 'RepClassSM'>Detailed analysis results (see legend at the bottom of the page)");						fprintf (stdout, "<TABLE BORDER = '0' style = 'margin:10px'><TR class = 'TRReportT'>");		for (r=0; r<colCount; r=r+1)		{			fprintf (stdout, "<TD>", titleMatrix[r], "</TD>");		}		fprintf (stdout, "</TR>\n");		for (r=0; r<rowCount; r=r+1)		{			rowString = ""; rowString * 128;			hitCount  = 0;			trClass = "TRReport1";			for (c=0; c<5; c=c+1)			{				rowString *("<TD>" + sbpInfo[r][c] + "</TD>");							}						myIC	 = 0+sbpInfo[r][5];			myWeight = Min(myIC-IC_Matrix[0][1],10);			meColor  = (myWeight/10*255$1);			meColor  = "<TD style = 'color: black; background-color: RGB(255,"+meColor+","+meColor+");'>";			rowString * (meColor + sbpInfo[r][5] + "</TD>" + meColor + sbpInfo[r][6] + "</TD>");			hitCount = hitCount + (myIC < baseAIC);			if (canUseAICc)			{				myIC	 = 0+sbpInfo[r][7];				myWeight = Min(myIC-IC_Matrix[1][1],10);				meColor  = (myWeight/10*255$1);				meColor  = "<TD style = 'color: black; background-color: RGB(255,"+meColor+","+meColor+");'>";				rowString * (meColor + sbpInfo[r][7] + "</TD>" + meColor + sbpInfo[r][8] + "</TD>");				hitCount = hitCount + (myIC < baseAICc);			}			else			{				rowString * ("<TD>N/A</TD><TD>N/A</TD>");			}			myIC	 = 0+sbpInfo[r][9];			myWeight = Min(myIC-IC_Matrix[2][1],10);			meColor  = (myWeight/10*255$1);			meColor  = "<TD style = 'color: black; background-color: RGB(255,"+meColor+","+meColor+");'>";			rowString * (meColor + sbpInfo[r][9] + "</TD>" + meColor + sbpInfo[r][10] + "</TD>");			hitCount = hitCount + (myIC < baseBIC);			rowString * "</TR>";			rowString * 0;			fprintf (stdout, "<TR class = 'TRReport", 1+(hitCount > 0),"'>", rowString, "\n");		}		fprintf (stdout, "</TABLE>");						fscanf ("../Formats/sbp_report","Raw",sbp_Legend);		fprintf (stdout, sbp_Legend);		fprintf (stdout, "</DIV>");	}}else{	if (optionOutput == 2)	{		fprintf (stdout, "<H1 CLASS = 'SuccessCap'>Generate selection plots</H1>");		fprintf (stdout, _makeJobIDHTML (filePrefix));		fprintf (stdout, "<FORM method='POST' name = 'plotForm' enctype='multipart/form-data' action='",BASE_CGI_URL_STRING,"rungnuplot.pl' target = '_blank'>\n<input type = 'hidden' value = '",filePrefix,"' name = 'inFile'><input type = 'hidden' value = '20' name = 'task'>");		formatName = "../Formats/sbplot" + canUseAICc;		fscanf  (formatName,"Raw",sbplot);		fprintf (stdout, sbplot, "</form>");	}	else	{		if (optionOutput >= 4)		{			fprintf (stdout, "set term ", gnuplotFormat);			if (gnuplotFormat == "png")			{				fprintf (stdout, " ", size);			}			fprintf (stdout, "\nset output\nset nokey\nset xlabel '", xaxis, "'\nset ylabel '",yaxis, "'\nplot '-' lt -1 with ",style,"\n");			pv = _ExecuteSQL  (slacDBID,"SELECT "+ DB_FIELD_MAP[optionOutput-4] +" FROM SBP_TREES ORDER BY SITE");			for (k=0; k<Abs(pv); k=k+1)			{				fprintf (stdout, "\n", k+1, "\t", pv[k]);			}		}		else		{			ErrorOut ("Unsupported output format");		}	}}if (optionOutput!=2){	_closeCacheDB (slacDBID);}