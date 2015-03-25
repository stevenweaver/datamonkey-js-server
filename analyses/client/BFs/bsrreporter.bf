ExecuteAFile("../Shared/HyPhyGlobals.ibf");ExecuteAFile("../Shared/GrabBag.bf");fscanf		(stdin,"String", filePrefix);fscanf		(stdin,"Number", optionOutput);/* ________________________________________________________________________________________________*/function ErrorOut (errString){	fprintf (stdout, "ERROR:<DIV class = 'ErrorTagSM'>\n", errString, "\n</DIV>");	return 0;}/* ________________________________________________________________________________________________*/if (optionOutput!=2){	ExecuteAFile	("../Shared/DBTools.ibf");	slacDBID 		 = _openCacheDB      (filePrefix);	pv = 0.05;	ExecuteAFile 			("../Shared/OutputsBSR.bf");	tableKeys = Rows		(BSR_ResultTable);}if (optionOutput < 2){	bsrInfo 		= _ExecuteSQL  (slacDBID,"SELECT * FROM BSR_RESULTS ORDER BY pvalue");	titleMatrix 	= {1,11};		rowCount  = Abs	   		(bsrInfo);	colCount  = Abs	        (BSR_ResultTable);	headers	  = Rows		(BSR_ResultTable);		colMap	  = {1,11}["_MATRIX_ELEMENT_COLUMN_"];	if (optionOutput == 1) /* CSV */	{		titleMatrix[0]  = "Branch";		titleMatrix[1]  = "Mean omega";		titleMatrix[2]  = "omega1";		titleMatrix[3]  = "p1";		titleMatrix[4]  = "omega2";		titleMatrix[5]  = "p2";		titleMatrix[6]  = "omega3";		titleMatrix[7]  = "p3";		titleMatrix[8]  = "LRT";		titleMatrix[9]  = "p-value";		titleMatrix[10]  = "Corrected p-value";		fprintf (stdout, Join (",", titleMatrix), "\n");				for (r=0; r<rowCount; r=r+1)		{			matrixInfo = {1,colCount};			for (c = 0; c < colCount; c+=1)			{				matrixInfo[c] = (bsrInfo[r])[headers[colMap[c]]];			}			fprintf (stdout, Join (",", matrixInfo), "\n");		}	}	else	{		titleMatrix[0]  = "Branch";		titleMatrix[1]  = "Mean &omega;";		titleMatrix[2]  = "&omega;<sup>-</sup>";		titleMatrix[3]  = "Pr[&omega;=&omega;<sup>-</sup>]";		titleMatrix[4]  = "&omega;<sup>N</sup>";		titleMatrix[5]  = "Pr[&omega;=&omega;<sup>N</sup>]";		titleMatrix[6]  = "&omega;<sup>+</sup>";		titleMatrix[7]  = "Pr[&omega;=&omega;<sup>+</sup>]";		titleMatrix[8]  = "LRT";		titleMatrix[9]  = "p-value";		titleMatrix[10]  = "Corrected p-value";	fprintf (stdout, "<script type='text/javascript' src='http://www.datamonkey.org/wz_tooltip.js'></script>\n<H1 CLASS = 'SuccessCap'>Detailed Branch-site REL results</H1>");		fprintf (stdout, _makeJobIDHTML (filePrefix));		fprintf (stdout, "<DIV CLASS = 'RepClassSM'>");				fprintf (stdout, "<b>Inferred branch-specific distributions of site-wise &omega; and LRT test results for evidence of episodic diversifying selection (EDS).</b> <div class = 'HelpfulTips'>Branches are sorted in the order of decreasing level of support for EDS. </div><p/> <TABLE BORDER = '0' style = 'margin:10px'><TR class = 'TRReportT' style = 'font-size:11px';><TD>");		fprintf (stdout, Join ("</TD><TD>", titleMatrix), "</TD></TR>\n");		for (r=0; r<rowCount; r=r+1)		{			trClass = "TRReportNT";						if (0 + (bsrInfo[r])["holmpvalue"] <= 0.05)			{				trClass = "TRReportPS";						}						matrixInfo = {1,colCount};			matrixInfo[0] = printALongString((bsrInfo[r])[headers[colMap[0]]],12);			for (c = 1; c < colCount; c+=1)			{				matrixInfo[c] = normalizeNumber((bsrInfo[r])[headers[colMap[c]]]);			}			fprintf (stdout, "<TR class = '",trClass,"' style = 'font-size:10px;'><TD>",Join ("</TD><TD>", matrixInfo),"</TD></TR>\n");		}				fprintf (stdout, "</TABLE>");						fscanf ("../Formats/bsr_report","Raw",fel_Legend);		fprintf (stdout, fel_Legend);		fprintf (stdout, "</DIV>");	}}if (optionOutput!=2){	_closeCacheDB (slacDBID);}function normalizeNumber (n){	n = 0+n;	if (n > 0 && n < 0.0001)	{		return "&lt;0.0001";	}	return Format (n,4,2);}