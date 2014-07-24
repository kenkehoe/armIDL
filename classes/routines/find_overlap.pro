;+
; Locates the first instance where the time of the first netCDF file
;			is at an earlier time than the second netCDF
;			
; @requires Must be at the location of the netCDF file before using the routine
;						
; @param FILE1 {in} {required} {type= string}
;			The filename of the earlier netCDF file
;			
; @param FILE2 {in} {required} {type= string}
;			The filename of the later netCDF file
;			
; @returns The array index for time in the first netCDF file
;-
FUNCTION FIND_OVERLAP, file1, file2
	
	;Extracting time from first file
	;Then convert it to IDL format
	id = ncdf_open(file1)
	ncdf_varget, id, 0, base_time
	ncdf_varget, id, 1, time_offset
	time = julday(1,1,1970,0,0,(base_time + time_offset))
	
	;Extracting the starting time of the second file
	second_split = strsplit(file2, '.', /EXTRACT)
	hour2 = long(strmid(second_split[3], 0, 2))
	min2 = long(strmid(second_split[3], 2, 2))
	sec2 = double(strmid(second_split[3], 4, 2))
	
	stop_ndx = 0
	
	;Locate the first instance where the time of the first file
	; is at an earlier time than the second
	;All instances after are the overlapping times
	;Starting from the very last 'time' value based on the first file
	for ndx = n_elements(time)-1, 0, -1 do begin
		caldat, time[ndx], month, day, year, hour1, min1, sec1
		
		if(hour1 LT hour2) then begin
			stop_ndx = ndx
			break
		endif else if(hour1 EQ hour2) then begin
			
			if(min1 LT min2) then begin
				stop_ndx = ndx
				break
			endif else if(min1 EQ min2) then begin
				
				if(sec1 LT sec2) then begin
					stop_ndx = ndx
					break
				endif
				
			endif
		endif
	endfor
	
	ncdf_close, id
	return, stop_ndx
END