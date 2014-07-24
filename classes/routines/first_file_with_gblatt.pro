;+
; Locates the first netCDF files within 'file_list'
;			to contain the passed in global attribute
;
; @requires Must be at the location of the netCDF file before using the routine
;						
; @param ATTRIBUTE {in} {required} {type= string}
;			The global attribute name
; 
; @param FILE_LIST {in} {required} {type= string array}
;			The array of netCDF filenames
;			
; @returns Return type: integer (The index within file_list)
;			<br /> Returns -1 if the global attribute was not found within file_list
;-
FUNCTION FIRST_FILE_WITH_GBLATT, attribute, file_list
	
	for ndx = 0, n_elements(file_list)-1 do begin
		file_id = ncdf_open(file_list[ndx], /NOWRITE)

		; comparing through all of the global variables in the file
		for att_id=0, (ncdf_inquire(file_id)).ngatts - 1 do begin
			if(attribute EQ ncdf_attname(file_id, att_id, /GLOBAL)) then begin
				ncdf_close, file_id
				return, ndx
			endif ; attribute if
		endfor ; att_id for

		ncdf_close, file_id
	endfor
	
	;Global Attribute not found in file_list
	return, -1
END
