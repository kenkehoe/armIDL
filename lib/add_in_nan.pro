; docformat = 'rst'

;+
;  Function to add NAN to data when a gap in data is detected.  This can be used
;  with plotting routines to not connect the data points with a line when data
;  is missing.
;
;  :Params:
;    time : in, required, type = 1-D Array
;      Time array in IDL time format  
;    data : in, required, type = 1-D Array
;      Data array to be modified  
;
;  :Returns:  Data array with NAN(or -9999 depending on data type) inserted at 
;             locations where the time step is larger than the minimum limit.
;
;  :Keywords:
;    NEW_TIME : out, optional, type = 1-D Array
;      New time array with missing value (NAN or -1) inserted at point where
;      time step is larger than minimum limit.
;    MAKE_NAN : in, optional, type = flag
;      IF set will convert all -9999 data to NaN.  Will convert integers to floats
;      to allow setting NaN values, but will preserver Double types.
;    MULTI_FACTOR : in, optional, type = scalar
;      Multiplication factor for use in determining minimum time step.
;      The time step is calculated from the mode of the time difference distribution.
;      MULTI_FACTOR is the multiplicaiton factor of the mode.
;      Default = 2.0 
;    MAX_TIME_DIFF : in, optional, type = scalar
;      Units = seconds
;      The maximum time difference to use in mode of the time difference distribution.
;    MISSING_VALUE : in, optional, type = scalar
;      Default = -9998.
;      The missing value indicator value.  This function will search for any value 
;      equal to this value and set to NaN.  Only used if MAKE_NAN flag is set.  
;
;  :Examples:
;          ; use 'time' array to look for gaps in data.  The minimum time difference<br />
;          ; will be calculated from the mode of the difference in 'time' and multiplied<br />
;          ; by 2.  The data array 'pol_voltage' is returned with NAN's added at <br />
;          ; data gaps.  'time' is not modfied.<br />

;     IDL> pol_voltage = add_in_nan(time, pol_voltage, MULTI_FACTOR=4)<br />
;          ; Same process is done on 'scope_temp' but 'time' is modifed and retured<br />
;          ; with keyword option.<br />
;     IDL> scope_temp = add_in_nan(time, scope_temp, NEW_TIME=time, MULTI_FACTOR=4)<br />
;
;
; :Author: Ken Kehoe, ARM Data Quality Office, University of Oklahoma
; :History: Created on July 12, 2010
; :Version: $Id: add_in_nan.pro 55512 2014-07-14 19:44:53Z kehoe $
; 
;-
FUNCTION add_in_nan, time, data, $
	NEW_TIME=return_time, $
	MULTI_FACTOR=_multi_factor, $
	MAX_TIME_DIFF = max_time_diff,$
	MAKE_NAN=make_nan, $
	MISSING_VALUE=missing_value,$
  DAILY_NUM_SAMP=daily_num_samp, $
  TIME_FILL_NAN=time_fill_nan

IF N_ELEMENTS(data) EQ 0 OR N_ELEMENTS(time) EQ 0 THEN RETURN,!NULL

;-- Convert -9999 data into NAN if requested
IF KEYWORD_SET(make_nan) THEN BEGIN
	IF N_ELEMENTS(missing_value) EQ 0 THEN missing_value = -9999.
	IF SIZE(data,/TYPE) EQ 5 THEN BEGIN
		data[WHERE(data EQ DOUBLE(missing_value),/NULL)]=!VALUES.D_NAN
	ENDIF ELSE BEGIN
		data=FLOAT(data)
		data[WHERE(data EQ FLOAT(missing_value),/NULL)]=!VALUES.F_NAN
	ENDELSE
ENDIF ; make_nan
exp_diff = !NULL

;-- Set return time if requested --;
IF ARG_PRESENT(return_time) THEN return_time = time

;-- Check number of time elements --;
IF N_ELEMENTS(time) LE 1 || TOTAL(FINITE(time)) LE 1 THEN RETURN, data

;-- Check if data and time have same dimensions. If not return --;
IF SIZE(data,/N_DIMENSIONS) LT 1 THEN RETURN, data
IF (SIZE(data,/DIMENSIONS))[0] NE SIZE(time,/DIMENSIONS) THEN RETURN, data

;-- Set default multiple factor if not given --;
IF N_ELEMENTS(_multi_factor) EQ 0 THEN multi_factor = 2L ELSE multi_factor = LONG(_multi_factor)

;-- Look for instances of not available data --;
time_diff = ABS(TS_DIFF(time,1,/DOUBLE)) ; Calculate difference
time_diff = time_diff[0:-2] ; Remove last value that is set to 0 by TS_DIFF()
time_diff = ROUND(time_diff*60D*60D*24D*10D) ; Convert time_diff into deciseconds
IF exp_diff EQ !NULL AND N_ELEMENTS(max_time_diff) THEN BEGIN
  exp_diff = LONG(max_time_diff) * 10L ; Convert seconds into deciseconds
ENDIF ; exp_diff
IF exp_diff EQ !NULL AND N_ELEMENTS(daily_num_samp) GT 0 THEN BEGIN
  exp_diff = (24L*60L*60L*10L)/LONG(daily_num_samp) ;Convert #/day into deciseconds
ENDIF ; exp_diff
IF exp_diff EQ !NULL THEN BEGIN
   histo = HISTOGRAM(time_diff,/NAN,BINSIZE=1L,NBINS=24L*60L*60L*10L,LOCATIONS=locations)
   !NULL = MAX(histo,maxIndex)
   exp_diff = locations[maxIndex]
   exp_diff = exp_diff
ENDIF ; exp_diff
index = WHERE(time_diff GE exp_diff*multi_factor, missCt)

;-- If no cases found return --;
IF missCt EQ 0 THEN RETURN, data

;-- Create fill value --;
CASE SIZE(time,/TYPE) OF
	2 : time_na = -9999
	3 : time_na = -9999L
	4 : time_na = !VALUES.F_NAN
	ELSE : time_na = !VALUES.D_NAN
ENDCASE ; time_type CASE

CASE SIZE(data,/TYPE) OF 
	1 : data_na = -1B ; Max unsigned byte (8-bit) value
	2 : data_na = -9999
	3 : data_na = -9999L
	4 : data_na = !VALUES.F_NAN
	5 : data_na = !VALUES.D_NAN
	12 : data_na = -1U ; Max unsigned 16-bit integer
	13 : data_na = -1UL ; Max unsigned 32-bit integer
	14 : data_na = -9999LL
	15 : data_na = -1ULL ; Max unsigned 64-bit integer
	ELSE : data_na = !VALUES.F_NAN
ENDCASE ; data_type CASE

;-- Determine the size of the higher dimensions --;
fill_data_dims = SIZE(data,/DIMENSIONS)
fill_data_dims[0] = 1

;-- Fill in data upto first not available period --;
new_time = time[0:index[0]]
new_data = data[0:index[0],*,*,*] 

time_fill = time_na
data_fill=MAKE_ARRAY(fill_data_dims,VALUE=data_na)

;-- Loop over each case inserting orginal data into new array --;
FOR ii=0L, missCt-2L DO BEGIN
  IF NOT KEYWORD_SET(time_fill_nan) THEN BEGIN
    time_fill = new_time[-1]+JULDAY(1,1,-4713,12,0,exp_diff/10L)
    IF time_fill GE time[index[ii]+1L] THEN $
      time_fill = time[index[ii]+1L] - JULDAY(1,1,-4713,12,0,exp_diff/10L)
  ENDIF ; time_fill_nan
	new_time = [new_time, time_fill, time[index[ii]+1L:index[ii+1L]]]
	new_data = [new_data, data_fill, data[index[ii]+1L:index[ii+1L],*,*,*]]
ENDFOR ; ii FOR

;-- Fill in remainder of data --;
final_data = data[index[-1]+1L:-1,*,*,*]
IF NOT KEYWORD_SET(time_fill_nan) THEN BEGIN
  time_fill = new_time[-1]+JULDAY(1,1,-4713,12,0,exp_diff/10L)
  IF time_fill GE time[index[ii]+1L] THEN $
    time_fill = time[index[ii]+1L] - JULDAY(1,1,-4713,12,0,exp_diff/10L)
ENDIF ; time_fill_nan
new_data = [new_data, data_fill, final_data]
new_time = [new_time, time_fill, time[index[-1]+1L:-1]]

;-- Ken attempted to make this program faster for large datasets and cases
; where there are lots of missing insertions. Still a work in progress. Please 
; leave this here commented out.

;;-- Create new array of size plus added missing values --;
;new_time_len = N_ELEMENTS(time)+missCt
;new_time = MAKE_ARRAY(new_time_len,VALUE=time_na)
;data_size = SIZE(data,/DIMENSIONS)
;data_size[0] = new_time_len
;new_data = MAKE_ARRAY(data_size,VALUE=data_na)
;
;; Set values of first new time and data array 
;new_time[0] = time[0:index[0]]
;new_data[0:index[0],*,*,*] = data[0:index[0],*,*,*]
;
;; Loop over second to last periods inserting data
;IF missCt GT 1 THEN BEGIN
;  FOR ii=1,N_ELEMENTS(index)-1 DO BEGIN
;    ; Look for last value of finite data to get end of previous period
;    ind2 = (WHERE(FINITE(new_time) EQ 1,ind2Ct))[-1] + 2L
;    IF ind2Ct GT 0 THEN BEGIN
;      indexes = LINDGEN(index[ii]-index[ii-1])+ind2
;      new_time[indexes] = time[index[ii-1]+1:index[ii]]
;      new_data[indexes,*,*,*] = data[index[ii-1]+1:index[ii],*,*,*]
;    ENDIF ; indCt
;  ENDFOR ; ii
;ENDIF ; missing_time_index
;
;
;; Add last data and time segments to new time/data arrays ;
;ind2 = (WHERE(FINITE(new_time) EQ 1,ind2Ct))[-1] +2L
;IF ind2Ct GT 0 THEN BEGIN
;  indexes = LINDGEN(N_ELEMENTS(time)-1L-index[-1])+ind2
;  new_time[indexes] = time[index[-1]+1:-1]
;  new_data[indexes,*,*,*] = data[index[-1]+1:-1,*,*,*]
;ENDIF ; indCt

;-- If returning new time set to array --;
IF ARG_PRESENT(return_time) THEN BEGIN
  ; Return time to correct type --;
  new_time=FIX(new_time,TYPE=SIZE(time_na,/TYPE))
  return_time = new_time
ENDIF ; return_time

RETURN, new_data ; Return data

END ; Procedure End
