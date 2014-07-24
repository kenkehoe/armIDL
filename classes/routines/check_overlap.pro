;+
; To check if there is a time overlap between two netCDF files
;
; @requires Must be at the location of the netCDF file before opening it
; 
; @param NCDF_FIRST {in} {required} {type= string}
;			The first netCDF filename with the earlier starting time
;			
;			
; @param NCDF_SECOND {in} {required} {type= string}
;			The second netCDF filename with the later starting time
;			<br /> IMPORTANT: NCDF_SECOND MUST BE THE FILE WITH THE LATER TIME
;			
; @returns Returns a boolean type (true/false) signifying overlapping
;			<br />Return type: boolean (true/false)
;-
FUNCTION CHECK_OVERLAP, ncdf_first, ncdf_second
	;algorithm
	;	-Check the time string from the filename of the 2 files for equivalence
	;	-Extract base_time and time_offset from the 1st file and convert it to IDL format
	;	-Extract hour, min, and sec from the extracted time
	;	-Split the time string from the filename of the 2nd file to extract hour,min,sec
	;	-Starting from the last index of the time array of the first file (reverse iteration),
	;		compare the hour,min,sec with the hour,min,sec of the 2nd file
	
	
	first_split = strsplit(ncdf_first, '.', /extract)
	second_split = strsplit(ncdf_second, '.', /extract)
	
	if (first_split[2] EQ second_split[2]) then begin
		
		;Extracting the dimension length
		ncdf_id1 = ncdf_open(ncdf_first, /NOWRITE)
		ncdf_diminq, ncdf_id1, 0, name, time_size
		
		;Extracting time of the first file and covert it to IDL format
		ncdf_varget, ncdf_id1, 0, base_time
		ncdf_varget, ncdf_id1, 1, time_offset
		time = JULDAY(1,1,1970,0,0,(base_time + time_offset))
		caldat, time[time_size-1], month, day, year, hour1, min1, sec1
		
		;Extracting the starting time of the second file
		hour2 = long(strmid(second_split[3], 0, 2))
		min2 = long(strmid(second_split[3], 2, 2))
		sec2 = double(strmid(second_split[3], 4, 2))
		
		;Comparisons for overlapping
		if (hour1 GT hour2) then begin
			ncdf_close, ncdf_id1
			return, 1
		endif else if (hour1 EQ hour2) then begin
			
			if(min1 GT min2) then begin
				ncdf_close, ncdf_id1
				return, 1
			endif else if (min1 EQ min2) then begin
				
				if(sec1 GE sec2) then begin
					ncdf_close, ncdf_id1
					return, 1
				endif
				
			endif 
		endif 
		
		ncdf_close, ncdf_id1
	endif
	return, 0
END