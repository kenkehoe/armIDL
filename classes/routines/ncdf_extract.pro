;+
; To extract variable data and attributes
;
; @author Tri Noensie
; @history September 2010
; @requires Pre-compiled: NETCDF_DATA, NCDFFILES, NCDFVAR, NCDFATT
;			first_file_with_var, first_file_with_gblatt,
;			check_overlap, find_overlap
;-

;+
; @param OBJ {in} {required} {type= NETCDF_DATA object}
;			The NETCDF_DATA object to be processed
;			
; @keyword NOTIME {in} {optional}
;			The flag to exclude time
;			
; @keyword GBLATTS {in} {optional}
;			The flag signifying global attributes are being queried
;-
PRO NCDF_EXTRACT, obj, NOTIME = notime, GBLATTS = flag_gblatts
	; Algorithm
	; 	-Check for the dimension lengths to determine if a change in length 
	;		occurs for other dimensions other than 'time'
	;	-Variable Data Extraction process
	;		-Check if the variable(s) exist(s) within the selected netcdf files
	;		-Extract all attributes of the variable
	;		-Extract data of the variable from the selected netcdf files process
	;			-Check if the variable in the current netcdf file overlaps the next file
	;			-Extract data
	;			-Transpose data for variables with multiple dimensions to 
	;				correctly concatenate data
	;			-Regenerate data for time length of 1 due to IDL array degeneration
	;	-Extract time data
	;		-Check if time in the current netcdf file overlaps the next file
	;	-Extract Global Attributes
	
	
	;-- Get list of files to read --;
	files = obj.getPath()+PATH_SEP()+obj.getFileList()

	;***************************************************;
	;************  Variable Data Extraction  ***********;
	;***************************************************;
	foreach var_name, obj.getVarNames() do begin

		;--Changed logic to use the last file in the list and not the first--;
		;file_with_var = first_file_with_var(var_name, files)
		file_with_var = last_file_with_var(var_name, files)

		;*** Variable was not found in any of the files ***
		if file_with_var LT 0 then begin
			obj.setVarData, var_name, !NULL
			continue ; Skip to the next variable to be extracted
		endif ; file_with_var

		; Extracting attribute data from the first netCDF file
		; that contains the current variable
		ncdf_id = ncdf_open(files[file_with_var], /NOWRITE)		
		var_id = ncdf_varid(ncdf_id, var_name)
		n_atts = (ncdf_varinq(ncdf_id,var_id)).Natts
		n_dims = (ncdf_inquire(ncdf_id)).nDims

		if n_atts GT 0 then begin
			;Iterate through all the attributes within the specific variable and extract
			for att_ndx = 0, n_atts-1 do begin
				att_name = ncdf_attname(ncdf_id, var_id, att_ndx)
				ncdf_attget, ncdf_id, var_id, att_name, att_value

				;Retrieving attribute value data type
				;Then convert to string if value is type CHAR
				type = (ncdf_attinq(ncdf_id, var_id, att_name)).dataType
				if(type EQ 'CHAR') then begin
					att_value = string(att_value)
					;IDL automatically changes "\n" to internal line feed in 
					att_value = STRJOIN(STRSPLIT(att_value,STRING(10B),/EXTRACT,/regex),'\n')
					att_value = STRJOIN(STRSPLIT(att_value,STRING(9B), /EXTRACT,/regex),'\t')
					att_value = STRJOIN(STRSPLIT(att_value,STRING(13B),/EXTRACT,/regex),'\r')
					att_value = STRJOIN(STRSPLIT(att_value,STRING(12B),/EXTRACT,/regex),'\f')
				endif ; type

				obj.addVarAtt, var_name, att_name, att_value
			endfor ; att_ndx
		endif ; n_atts

		; Get an array of the dimension names	
		dimension_array = []  ; Default is an empty array
		IF((ncdf_varinq(ncdf_id,var_id)).Ndims GT 0) THEN BEGIN
			foreach dim_id, (ncdf_varinq(ncdf_id,var_id)).Dim do begin
				ncdf_diminq, ncdf_id, dim_id[0],dim_string, dim_length	
				dimension_array = [dimension_array,dim_string]
			endforeach
		ENDIF ; number of dimensions if
		; Transpose array for multi-dimension arrays
		dimension_array = reverse(dimension_array) 
		; Set dimensions in object
		obj.setVarDims, var_name, dimension_array

		ncdf_close, ncdf_id

		for file_ndx = 0, n_elements(files)-1 do begin

			time_offset_dummy=!NULL;-- Theisen 12.5.2013 - Corrupt descriptor in 118

			ncdf_id = ncdf_open(files[file_ndx], /NOWRITE)
			var_id = ncdf_varid(ncdf_id, var_name)

         NCDF_CONTROL,ncdf_id,/NOVERBOSE
			time_id=ncdf_varid(ncdf_id,'time_offset')
			IF time_id GE 0 THEN ncdf_varget,ncdf_id,time_id,time_offset_dummy
         NCDF_CONTROL,ncdf_id,/VERBOSE

			; Variable was not found in the current netCDF file
			; The variable in object will be inserted with
			; NaN with the size of time length
			if var_id LT 0 then begin

				; qc variables will be given -1 in the object
				if strmid(var_name,0,3) EQ 'qc_' then begin
					error_value = -1

				; regular variables will be a FLOAT NaN in the object
				endif else error_value = !VALUES.F_NAN
				
				ncdf_diminq, ncdf_id, 0, time_string, time_length
				obj.setVarData, var_name, replicate(error_value, time_length), /concat
				ncdf_close, ncdf_id
				continue
			endif ; var_id


			;Time overlapping files algorithm
			;Separate processing when overlapping files occur for the current variable 
			;Partial data is retrieved to ensure no overlapping data
			;The default processing is skipped
;			if(file_ndx LT n_elements(files)-1) then begin
;				if check_overlap(files[file_ndx], files[file_ndx+1]) then begin
;					obj.overlapHandler_var, find_overlap(files[file_ndx], $
;						files[file_ndx+1]), files[file_ndx], ndx
;					ncdf_close, ncdf_id
;					continue
;				endif 
;			endif

			;Special instructions for variables with 1 or more dimensions
			nDims = (ncdf_varinq(ncdf_id,var_id)).ndims

			;*** default variable data extraction (retrieves all values) ***;
			data_read = !NULL ;  Reset variable to NULL to fix strange IDL error
			ncdf_varget, ncdf_id, var_id, data_read

			if nDims GT 0 then begin
				; IDL Issue: IDL Array degeneration 
				; A variable with 'time' Length of 1 will degenerate 
				; EX: var[3,3,1] => var[3,3]  OR  var[3,1] => var[3] OR var[1] => var
				; Regenerate the single time length into the array for correct 
				; array concatenation
				data_read_dims = []
				FOREACH dimNum, ((ncdf_varinq(ncdf_id,var_id)).Dim) DO BEGIN
					NCDF_DIMINQ, ncdf_id, dimNum[0],dim_string, dim_length
					data_read_dims = [data_read_dims,dim_length]
				ENDFOREACH ; dimNum
				data_read = REFORM(data_read, data_read_dims)

				; Transpose the data that has been read
				; IDL reads netCDF file with 'time' as the last array orientation
				;'time' needs to be on the first array orientation to properly concatenate data
				IF nDims GT 1 THEN data_read = TRANSPOSE(data_read)

			endif ; nDims

			;-- Add data to object.  Only concatinate if contains time dimension
			dim_id = ((ncdf_varinq(ncdf_id,var_id)).Dim)[-1]
			ncdf_diminq, ncdf_id, dim_id,dim_string, dim_length
         ;Theisen 6/12/14.... Changed to concatenate if any time dimension
			if (ncdf_varinq(ncdf_id,var_id)).Ndims GT 0 && STRMATCH(dim_string,'*time*') THEN BEGIN

				;-- Check if non-time dimension length changes.  Return with error if true.
				curr_sz = size(obj.getVarData(var_name),/dimensions)
				new_sz =  size(data_read,/dimensions)
				if n_elements(curr_sz) gt 1 then begin
					curr_ttl = total(curr_sz[1:-1],/INTEGER)
					new_ttl = total(new_sz[1:-1],/INTEGER)
					IF(curr_ttl NE new_ttl) THEN BEGIN
						print & print, strjoin(make_array(50,/STRING,VALUE='*'))
						print, 'ERROR: The non-time length dimension for "', var_name, $
							'" has changed!! ';, first_lengths[dim_ndx], '  =>', check_length
						print, 'Skipping File: ', files[file_ndx]
						print, strjoin(make_array(50,/STRING,VALUE='*')) & print
					
						; Clear the object then assign it -1 to signify an error
						;obj.cleanup	& obj = -1
						;ncdf_close, ncdf_id
						;return
						CASE SIZE(data,/TYPE) OF
							2 : data_na = -9999
							3 : data_na = -9999L
							5 : data_na = !VALUES.D_NAN
							ELSE : data_na = !VALUES.F_NAN
						ENDCASE ; data_type CASE
						IF N_ELEMENTS(time_offset_dummy) GT 0 THEN $
							dummy=N_ELEMENTS(time_offset_dummy) $
							Else dummy=1 
						IF N_ELEMENTS(curr_sz) EQ 1 THEN $
							data_read=MAKE_ARRAY([dummy],VALUE=data_na) $
								ELSE data_read=MAKE_ARRAY([dummy,curr_sz[1:-1]],VALUE=data_na)
					ENDIF ; curr_ttl
				endif ; curr_sz

				obj.setVarData, var_name, data_read, /concat
			ENDIF ELSE BEGIN
				obj.setVarData, var_name, data_read
			ENDELSE ; ndims gt 0
			ncdf_close, ncdf_id
		endfor ; fle_ndx

	endforeach ; var_name
	
	;***************************************************;
	;**************  Time Data Extraction  *************;
	;***************************************************;	
	if not keyword_set(notime) then begin
		for file_ndx = 0, n_elements(files)-1 do begin
			
			;Time overlapping files algorithm
			;Separate processing when overlapping files occur for the current variable 
			;Partial data is retrieved to ensure no overlapping data
			;The default processing is skipped
;			if(file_ndx LT n_elements(files)-1) then begin
;				if check_overlap(files[file_ndx], files[file_ndx+1]) then begin
;					obj.overlapHandler_Time, find_overlap(file_ndx, file_ndx+1), file_ndx
;					continue
;				endif 
;			endif
			
			;Default processing (retrieves all values)
			ncdf_id = NCDF_OPEN(files[file_ndx], /NOWRITE)
			time_offset = !NULL ;  Reset variable to NULL to fix strange IDL error
			base_time = 0D
			; Check if time_offset is set, else use time variable
			time_name = 'time_offset'
			units_name = 'base_time'
         NCDF_CONTROL,ncdf_id,/NOVERBOSE
			time_name_test = NCDF_VARID(ncdf_id, time_name)
			units_name_test = NCDF_VARID(ncdf_id, units_name)
			IF time_name_test GE 0 AND units_name_test GE 0 THEN BEGIN
				NCDF_VARGET, ncdf_id, 'base_time', base_time
			ENDIF ELSE BEGIN 
				time_name = 'time'
				units_name = time_name
			ENDELSE ; time_offset
			NCDF_ATTGET, ncdf_id, units_name, 'units', time_units
			NCDF_VARGET, ncdf_id, time_name, time_offset
			time_offset = base_time + time_offset
         NCDF_CONTROL,ncdf_id,/VERBOSE

			; Extract start time from attribute
			t_val = ((STREGEX(time_units,'^[a-z ]+([0-9]+)-([0-9]+)-([0-9]+).([0-9]+):([0-9]+):([0-9.]+).([-0-9]{0,3}:{0,1}[0-9]{0,2})',/EXTRACT,/SUBEXPR))[1:-1])

			t_month = FLOAT(t_val[1])
			t_day = FLOAT(t_val[2])
			t_year = FLOAT(t_val[0])
			t_hour = FLOAT(t_val[3])
			t_minute = FLOAT(t_val[4])
			t_second = FLOAT(t_val[5])

			; Check for timezone offset
			t_offset_temp = STRSPLIT(t_val[6],':',/EXTRACT)

			IF N_ELEMENTS(t_offset_temp) LT 2 THEN t_offset_temp=['0','00']  
			t_offset = ABS(FLOAT(t_offset_temp[0])) + FLOAT(t_offset_temp(1))/60.
			IF t_offset_temp[0] LT 0 THEN t_offset = -1D * t_offset

			; Issue with IDL: Array Degeneration.  Need to reset to array if length 1
			; Ex: var[1] => var as a scalar 
			dimNum = (NCDF_VARINQ(ncdf_id,NCDF_VARID(ncdf_id, time_name))).Dim
			NCDF_DIMINQ, ncdf_id, dimNum[0],dim_string, dim_length	
			time_offset=REFORM(time_offset,dim_length)

			; Check the units for time step and adjust array values as needed
			; Hash to convert all string options to the standard value
			t_hash = HASH()
			arr = ['s','second','sec']
			t_hash = t_hash + HASH(arr,MAKE_ARRAY(N_ELEMENTS(arr),VALUE='seconds'))
			arr = ['minute','min']
			t_hash = t_hash + HASH(arr,MAKE_ARRAY(N_ELEMENTS(arr),VALUE='minutes'))
			arr = ['hour','hr','h']
			t_hash = t_hash + HASH(arr,MAKE_ARRAY(N_ELEMENTS(arr),VALUE='hours'))
			arr = ['day','d']
			t_hash = t_hash + HASH(arr,MAKE_ARRAY(N_ELEMENTS(arr),VALUE='days'))
			arr = ['month']
			t_hash = t_hash + HASH(arr,MAKE_ARRAY(N_ELEMENTS(arr),VALUE='months'))
			arr = ['year']
			t_hash = t_hash + HASH(arr,MAKE_ARRAY(N_ELEMENTS(arr),VALUE='years'))

			t_unit = (STRSPLIT(STRING(time_units),/EXTRACT))[0]
			IF t_hash.HasKey(t_unit) THEN t_unit=t_hash[t_unit]
			CASE 1 OF
				t_unit EQ 'seconds': BEGIN
					jultime = JULDAY(t_month,t_day,t_year,t_hour,t_minute,t_second + time_offset)
				END 
				t_unit EQ 'minutes': BEGIN
					jultime = JULDAY(t_month,t_day,t_year,t_hour,t_minute + time_offset,t_second)
				END
				t_unit EQ 'hours': BEGIN
					jultime = JULDAY(t_month,t_day,t_year,t_hour + time_offset,t_minute,t_second)
				END
				t_unit EQ 'days': BEGIN
					jultime = JULDAY(t_month,t_day,t_year,t_hour,t_minute,t_second) + time_offset
				END
; What does a partial month mean? This may not do what you want! 
				t_unit EQ 'months': BEGIN
					jultime = JULDAY(t_month,t_day,t_year,t_hour,t_minute,t_second)
					jultime = jultime + DOUBLE(time_offset)/365.242198781D/12D
				END
; What does a partial year mean? This may not do what you want! 
				t_unit EQ 'years': BEGIN
					jultime = JULDAY(t_month,t_day,t_year,t_hour,t_minute,t_second)
					jultime = jultime + DOUBLE(time_offset)/365.242198781D
;					t_years = t_year + time_offset
;					jultime = JULDAY(t_month,t_day,t_years,t_hour,t_minute,t_second)
;					n_days = JULDAY(12,31,t_years,0,0,0) - JULDAY(1,0,t_years,0,0,0)
;					jultime = jultime + (time_offset-DOUBLE(FLOOR(time_offset)))*n_days
				END
				ELSE: BEGIN
					jultime = JULDAY(t_month,t_day,t_year,t_hour,t_minute,t_second + time_offset)
				END ; CASE ELSE END
			ENDCASE ; t_unit

			; If timezone offset is not 0 adjust
			IF t_offset NE 0.0 THEN jultime = jultime + JULDAY(1L,1L,-4713L,12L+t_offset,0L,0L)

			; Set time in object
			obj.setTime, jultime, /concat
			NCDF_CLOSE, ncdf_id
		ENDFOR ; file_ndx
	ENDIF ; not notime
	;***************************************************;
	;*******  Global Attribute Value extraction  *******;
	;***************************************************;
	if keyword_set(flag_gblatts) then begin
		
		foreach gblatt, obj.getGblAttNames() do begin
			gblatt = gblatt[0]
			; Extracting global attribute data from the first netCDF file
			; that contains the current global attribute
			file_with_gblATT = first_file_with_gblATT(gblatt, files)
			
			;Global Attribute was not found in any of the files
			if file_with_gblATT LT 0 then begin
				;print & print, 'ERROR: ', gblatt, ' was not found within selected dates'
				;print, 'The value of this global attribute in the object will be a NULL'
				
				obj.setGblatt, gblatt, !NULL 	; NULL is assigned to the variable in the object
				continue						; Skip to the next variable to be extracted
			endif ; file_with_gblATT

			ncdf_id = ncdf_open(files[file_with_gblATT], /NOWRITE)
			ncdf_attget, ncdf_id, gblatt, gblatt_value, /GLOBAL

			;Retrieve global attribute value data type
			;Then convert to string if value is type CHAR
			type = (ncdf_attinq(ncdf_id, gblatt, /GLOBAL)).dataType
			if(type EQ 'CHAR') then begin
				gblatt_value = string(gblatt_value)
				;IDL automatically changes "\n" to internal line feed in ASCII = string(10B)
				;Return to orginal "\n"
				gblatt_value = STRJOIN(STRSPLIT(gblatt_value,STRING(10B),/EXTRACT,/regex),'\n')
				gblatt_value = STRJOIN(STRSPLIT(gblatt_value,STRING(9B), /EXTRACT,/regex),'\t')
				gblatt_value = STRJOIN(STRSPLIT(gblatt_value,STRING(13B),/EXTRACT,/regex),'\r')
				gblatt_value = STRJOIN(STRSPLIT(gblatt_value,STRING(12B),/EXTRACT,/regex),'\f')
			endif ; type

			obj.setGblatt, gblatt, gblatt_value
			ncdf_close, ncdf_id
		endforeach ; gblatt
	endif ; flag_gblatts

END ; procedure end
