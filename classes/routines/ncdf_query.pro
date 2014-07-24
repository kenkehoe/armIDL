;+
; Retrieves a set of netCDF files and variables to examine
;			
; @Author Tri Noensie
; @history September 2010
; @requires Pre-compiled: NETCDF_DATA, NCDFFILES, NCDFVAR, 
;			NCDFATT, NCDF_EXTRACT, DATA_FILE_LIST
;			
; @examples
;			<dl>
;				<dt> For regular routine call: </dt>
;				<dd> IDL> files_object = ncdf_query('sgpsirsE7.b1', '20090609', '20090630', 
;							'down_long_hemisp_shaded_std') </dd> <br />
;			
;				<dt> For special routine call (exclude TIME):
;					(Any other keywords will apply here) </dt>
;				<dd> IDL> files_object = ncdf_query('sgpsirsE7.b1', '20090609', '20090630', 
;					'down_long_hemisp_shaded_std', /NOTIME) </dd>
;
;				<dd> IDL> files_object = ncdf_query('sgpsirsE7.b1', '20090609.101020', 
;					20090630.230000D, 'down_long_hemisp_shaded_std', /QC </dd>
;			</dl>
;-


;+
;			
; @returns An object reference of type: NETCDF_DATA
;			<br /> Returns !NULL if there was an error
;		
; @param _DATASTREAM {in} {required} {type= string}
;			Datastream to be examined
;			
; @param _DATE_START{in} {required} {type= integer, double, string}
;			Start date selection.  Accepts YYYYMMDD or YYYYMMDD.HHMMSS formats. 
;             Will read in data files that are GE to date or date.time.
;             Due to precision, if date is entered as decimal number, use double precision.
;			
; @param _DATE_END {in} {required} {type= integer} 
;			End date selection. Accepts YYYYMMDD or YYYYMMDD.HHMMSS formats. 
;             Will read in data files that are LE to date or date.time.
;             Due to precision, if date is entered as decimal number, use double precision.
;			
; @param _VARIABLES {in} {required} {type= string array}
;			Variables to be examined
;			
; @param _GBLATTS {in} {optional} {type= string array}
;			Global attributes to be examined
;				
; @keyword PATH_START {in} {optional} {type= string}
;			Changing the starting directory. 
;			The directory hierarchy after the chosen path must be in this format:
;				site/datastream/netCDF files
;
; @keyword FULL_PATH {in} {optional} {type= string}
;			Full path to data directory 
;			
; @keyword NOTIME {in} {optional} 
;			Flag this to exclude 'base_time' and 'time_offset'
;
; @keyword GET_ALL_GBLATTS {in} {optional} 
;			Flag this to read in all global attributes listed in first netCDF file
;
; @keyword GET_ALL_VARIABLES {in} {optional} 
;			Flag this to read in all variables listed in first netCDF file. 
;			This will override varaibles parameter and ignore QC flag.
;			
; @keyword QC {in} {optional}
;			Flag this to include qc fields.  Also accepts true/false integers
;
; @keyword STRIDE {in} {optional}
;			Stride size to use while reading data. Data between stride values will
;			not be read.
;
; @keyword RETURN_TRIMMED_TIME {in} {optional}
;			Flag to indicate data for date prior and date after should be read in
;           and data will be trimmed to UTC day. Used for converting from local time to 
;           UTC time.
;-
FUNCTION NCDF_QUERY, $
	_datastream, $
	_date_start, $
	_date_end, $
	_variables, $
	_gblatts, $
	PATH_START = path_start, $
	FULL_PATH = full_path, $
	NOTIME = notime, $
	QC = qc, $
	GET_ALL_GBLATTS = get_all_gblatts,$
	GET_ALL_VARIABLES = get_all_variables, $
	STRIDE=stride, $
	RETURN_TRIMMED_TIME=return_trimmed_time

	;bit-by-bit copy, due to pass by reference
	datastream = _datastream
	variables = _variables
	IF (N_ELEMENTS(_gblatts) GT 0) THEN gblatts = _gblatts

    ;-- Convert date for processing --;
	type = SIZE(_date_start,/TYPE)
	IF type GE 4 AND type LE 5 THEN BEGIN
		IF _date_start - LONG(_date_start) GT 0.0 THEN BEGIN
			date_start = STRING(_date_start, FORMAT='(F15.6)')
	    ENDIF ELSE date_start = STRING(_date_start, FORMAT='(I8)')
	ENDIF ELSE BEGIN
		date_start = STRTRIM(_date_start,2)
	ENDELSE ; type
	type = SIZE(_date_end,/TYPE)
	IF type GE 4 AND type LE 5 THEN BEGIN
		IF _date_end - LONG(_date_end) GT 0.0 THEN BEGIN
			date_end = STRING(_date_end, FORMAT='(F15.6)')
	    ENDIF ELSE date_end = STRING(_date_end, FORMAT='(I8)')
	ENDIF ELSE BEGIN
		date_end = STRTRIM(_date_end,2)
	ENDELSE ; type
	;date_start = STRTRIM(_date_start,2)
	;date_end = STRTRIM(_date_end,2)

	;***************************************************;
	;**************  Directory Selection  **************;
	;***************************************************;
	path = !NULL
	IF N_ELEMENTS(path_start) GT 0 THEN BEGIN
		path = path_start
	ENDIF ELSE BEGIN
		IF GETENV('DQO_DATASTREAM_DATA') NE '' THEN $
			path = GETENV('DQO_DATASTREAM_DATA') ELSE $
			path = GETENV('DATASTREAM_DATA')
	ENDELSE ; path_start
	IF N_ELEMENTS(path) EQ 0 THEN path = PATH_SEP()+STRJOIN(['data','datastream'],PATH_SEP())

	; Add site and datastream to path	
	path = STRJOIN([path,STRMID(datastream, 0, 3),datastream], PATH_SEP())

	; Set full path if given
	IF N_ELEMENTS(full_path) GT 0 THEN path = full_path

	; Return NULL if no files found	
	IF (FILE_SEARCH(path+PATH_SEP()+['*.cdf','*.nc'],/NOSORT))[0] EQ ''  THEN RETURN, !NULL

	;***************************************************;
	;*****************  Date Selection  ****************;
	;***************************************************;
	IF(date_start gt date_end) THEN BEGIN
		PRINT & PRINT, 'ERROR: The dates selected clashed'
		RETURN, !NULL 
	ENDIF

	;Initialize and set the 'files' in the data field of the NETCDF_DATA object	
	ncdf_files = data_file_list(date_start,date_end, DATASTREAM=datastream, $
		PATH=path, RETURN_TRIMMED_TIME=return_trimmed_time)

	; Return NULL if no data files found 	
	IF ncdf_files[0] EQ '' THEN RETURN, !NULL

    ;Check if netCDF file is corrupt or contains no time data
	ncdf_files = is_ncdf_file(path+PATH_SEP()+ncdf_files, /HAS_TIME, $
		/FILTER_LIST, REMOVED_FILES=removed_files)
    IF N_ELEMENTS(removed_files) GT 0 THEN PRINT, '***** SKIPPING FILE *****:'+removed_files
    IF N_ELEMENTS(ncdf_files) EQ 0 THEN RETURN, !NULL
    ncdf_files = FILE_BASENAME(ncdf_files)

	first_date = STRSPLIT(ncdf_files[0],'.',/EXTRACT)
	last_date = STRSPLIT(ncdf_files[-1],'.',/EXTRACT)
	return_data = netcdf_data(DATE_START = first_date[2], DATE_END = last_date[2])
	return_data.setPath, path
	return_data.setFiles, ncdf_files

	
	; Initialize Variables(fields) into the object
	;Extracting variables with their qc variables
	; If requested read all variables in the file
	IF KEYWORD_SET(get_all_variables) THEN $
	    variables = ncdf_fields(ncdf_files[0], FULL_PATH=path)

	IF KEYWORD_SET(qc) EQ 1 AND KEYWORD_SET(get_all_variables) EQ 0 THEN $
		variables = [variables, 'qc_'+variables]	
	FOREACH variable, variables DO return_data.addVar, variable[0], ncdfvar(name = variable)

	; Initialize Global Attributes into the object
	IF N_ELEMENTS(_gblatts) GT 0 THEN foreach attribute, gblatts DO $
		return_data.addGblAtt, attribute[0], !NULL

	;-- If requested get all global attributes --; 
	IF N_ELEMENTS(get_all_gblatts) GT 0 THEN BEGIN
		gblatts = ncdf_global_atts(ncdf_files[0],FULL_PATH=path)
		IF gblatts[0] NE '' THEN FOREACH attribute, gblatts DO $
			return_data.addGblAtt, attribute[0], !NULL
	ENDIF ; get_all_gblatts	

	IF N_ELEMENTS(stride) GT 0 THEN $
		ncdf_extract_stride,return_data,NOTIME=notime,GBLATTS=gblatts,STRIDE=stride $
	ELSE ncdf_extract,return_data,NOTIME=notime,GBLATTS=gblatts

	;-- Trim data in object if requested --;
	IF KEYWORD_SET(return_trimmed_time) THEN ncdf_trim_time, return_data, date_start, date_end

	;-- Return data --;
	RETURN, return_data
	
END
