;+
; Locates the first netCDF files within 'file_list'
;			to contain the passed in variable
;
; @requires Must be at the location of the netCDF file before using the routine
;						
; @param VARIABLE {in} {required} {type= string}
;			The variable name
; 
; @param FILE_LIST {in} {required} {type= string array}
;			The array of netCDF filenames
;			
; @returns Return type: integer (The index within file_list)
;			<br /> Returns -1 if the variable was not found within file_list
;-
FUNCTION LAST_FILE_WITH_VAR, variable, file_list
	
	for ndx = 0, n_elements(file_list)-1 do begin
      index=N_ELEMENTS(file_list)-1-ndx
		file_id = ncdf_open(file_list[index], /NOWRITE)
		
		; comparing through all of the variables in the file
		for var_ndx = 0, (ncdf_inquire(file_id)).nvars-1 do begin
			if variable EQ (ncdf_varinq(file_id,var_ndx)).name then begin
				ncdf_close, file_id
				return, index
			endif
		endfor
		
		ncdf_close, file_id
	endfor
	
	;Variable not found in file_list
	return, -1
END
