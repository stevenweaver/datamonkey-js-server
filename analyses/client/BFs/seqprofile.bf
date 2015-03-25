RequireVersion ("0.9920060501");

fscanf 			(stdin, "String", inFile);
DataSet ds 		= ReadDataFile (inFile);
DataSetFilter 	_DATAPANEL_DATAFILTER_ = CreateFilter (ds,1);

ExecuteAFile("../Shared/char_colors.def");
ExecuteAFile("../Shared/GrabBag.bf");
ExecuteAFile("../Shared/PostScript.bf");


_font_size  = 14;
_char_space = (_font_size*1.1)$1;
_page_w	    = 612;
_page_h     = 792;
_atom		= 5;

_selFilters		= Columns(_DATAPANEL_SELECTED_FILTERS_);

if (_selFilters > 1)
{
	fprintf (stdout, "ERROR: This plug in-needs zero or one selected data filter\n");
	return 0;
}

if (_selFilters == 1)
{
	_baseName = _DATAPANEL_SELECTED_FILTERS_[0];
}
else
{
	_baseName = _DATAPANEL_DATASET_NAME_;
}

fprintf ("/tmp/charcolors", CLEAR_FILE, _charColorList);

GetDataInfo (_charHandles, _DATAPANEL_DATAFILTER_, "CHARACTERS");
_ccount  = Columns (_charHandles);
_unit    = {1,_ccount}["1"];
GetDataInfo (_dupInfo, _DATAPANEL_DATAFILTER_);
_result_cache = {};
_maxD		  = 0;

_char_per_line  = _page_w / _char_space $ _atom * _atom;
if (_char_per_line == 0)
{
	fprintf (stdout, "\nERROR: At least ",_atom," characters must fit in a line; reduce font size in 'Character Plot' source\n");
}

fprintf (stdout,_HYPSPageHeader (_page_w,_page_h,"Character Plot for "+_baseName),
							_HYPSSetFont ("Courier",_font_size),
							"/dmx 6 array currentmatrix def\n",
							"/sshift fs 2 idiv fs add def\n",
							"/setb {0 0 0 setrgbcolor} def\n",
							"/flbx {setrgbcolor newpath 2 copy moveto 4 -1 roll exch 2 copy lineto exch 4 -1 roll 2 copy lineto 4 -1 roll exch lineto pop pop closepath fill setb} def\n",
							"/drawletter {translate scale newpath 0 0 moveto false charpath fill dmx setmatrix translate 0.4 0.4 scale newpath sshift 0 moveto  false charpath fill dmx setmatrix} def\n"
);



_dbyLine = {};

for (_idx = 0; _idx < _DATAPANEL_DATAFILTER_.sites; _idx = _idx + 1)
{
	_siteInfo = {_ccount, 2};
	_cCounter = {_ccount, 1};
	for (_sidx = 0; _sidx < _DATAPANEL_DATAFILTER_.species; _sidx = _sidx + 1)
	{
		GetDataInfo (_thisChar, _DATAPANEL_DATAFILTER_, _sidx, _dupInfo[_idx]);
		/* don't count gaps */
		if (Abs (_thisChar) != Sqrt (_ccount))
		{
			_cCounter = _cCounter + _thisChar*(1/(_unit*_thisChar)[0]);
		}
	}
	_siteInfo = _siteInfo ["_MATRIX_ELEMENT_ROW_ * _MATRIX_ELEMENT_COLUMN_ + (1-_MATRIX_ELEMENT_COLUMN_)*_cCounter[_MATRIX_ELEMENT_ROW_]"]%0;
	for (_sidx = _ccount-1; _sidx >= 0; _sidx = _sidx - 1)
	{
		if (_siteInfo[_sidx][0] == 0)
		{
			break;
		}
	}
	_result_cache[_idx] = _siteInfo[{{_sidx+1,0}}][{{_ccount-1,1}}];
	_sidx = Rows (_result_cache[_idx]);
	
	if (_sidx > _maxD)
	{
		_maxD = _sidx;
	}

	if ((_idx + 1)%_char_per_line==0)
	{
		_dbyLine [Abs(_dbyLine)] = _maxD;
		_maxD = 0;
	}	
}

_current_x 	  = 0;
_current_y	  = _page_h-2*_font_size;
_cl			  = 0;

for (_idx = 0; _idx < _DATAPANEL_DATAFILTER_.sites; _idx = _idx + 1)
{
	_cCounter = _result_cache[_idx];
	
	if (Rows(_cCounter))
	{
		for (_sidx = Rows(_cCounter)-1; _sidx >= 0; _sidx = _sidx - 1)
		{
			_siteInfo = _current_y-_font_size*(Rows(_cCounter)-1-_sidx);
			_my_c     = _charHandles[_cCounter[_sidx][1]];
			if (Abs(_charColorList[_my_c]))
			{
				fprintf (stdout, _charColorList[_my_c], " setrgbcolor\n");
			}
			fprintf (stdout, "(",_cCounter[_sidx][0],") ", _current_x, " ",_siteInfo," (",_my_c,") 1 1 ", _current_x, " ", _siteInfo, " drawletter\n");
			if (Abs(_charColorList[_my_c]))
			{
				fprintf (stdout, "setb\n");
			}
		}
	}
	else
	{
		fprintf (stdout, "( ) ", _current_x, " ",_current_y," (-) 1 1 ", _current_x, " ", _current_y, " drawletter\n");
	}
	_current_x = _current_x + _char_space;

	if ((_idx + 1)%_char_per_line==0 || _idx == _DATAPANEL_DATAFILTER_.sites-1)
	{
		_current_y = _current_y + _font_size;
		if (_idx == _DATAPANEL_DATAFILTER_.sites-1)
		{
			if (_DATAPANEL_DATAFILTER_.sites % _char_per_line == 0)
			{
				_startx = _char_per_line;
			}
			else
			{
				_startx = _DATAPANEL_DATAFILTER_.sites%_char_per_line$_atom*_atom;
			}
			_idx2 = _DATAPANEL_DATAFILTER_.sites-_DATAPANEL_DATAFILTER_.sites%_char_per_line;
		}
		else
		{
			_idx2 = _idx - _char_per_line + 1;
			_startx = _char_per_line;
		}
		fprintf (stdout, "0 ", _current_y + _font_size * 4$5, " ", (_char_space+1) * _char_per_line , " ", _current_y - _font_size$4, " 0.9 0.9 0.9 flbx\n");
		for (_idx3 = _startx; _idx3 > 0; _idx3 = _idx3 - _atom)
		{
			fprintf (stdout, "( ) 0 0 (",_idx2+_idx3,") 0.9 0.9 ", (_idx3-1) * _char_space, " ", _current_y, " drawletter\n");
		}
		_current_x = 0; 
		_current_y = _current_y - (2+_dbyLine[_cl])*_font_size;
		_cl = _cl+1;
		if (_current_y - (1+_dbyLine[_cl])*_font_size < 0)
		{
			_current_y = _page_h-2*_font_size;
			fprintf (stdout, "showpage\n");
		}
	}
}



