; docformat = 'rst'
;
;+
; This Function will convert data from the current system of units to a desired
; unit system. The current and desired units must be recognized or the converison
; will not occure.  There are some steps taken to allow multiple syntax for the 
; same units (ie 'C' is the same as "Deg C") All unit labels are case insensitive.
; 
; :Post:
;   Accepted unit labels
;     C = Celcious (will also accept: 'deg C','DegC','Degrees C.')
;     F = Farenheight
;     K = Kelvin
;     m/s = meters per second (will also accept: 'M/SEC')
;     hPa = Hectapascals
;     kPa = Kilopascals
;     mb = milibars
;     km = Kilometers
;     knots = knots speed
;     m = meters (will also accept: 'METERS ABOVE MEAN SEA LEVEL')
;     cm = centimeters
;     um = micrometers
;     nm = nanometers
;     % = percentage (will also accept: 'PERCENTAGE')
;     Deg = Degrees (ie 0 - 360 directional degrees)
;     W/M^2-NM = Watts per sqare meter per nanometer (will also accept: 'W/(M2 NM)')
;     W/M^2 = Watts per square meter (will also accept: 'W/M2')
;     mm/hr = mm per hour
;     MMOL/M3 = Milimoles per cubic meter (will require ANCDATA)
;     CUMULATIVE_MM = cumulative precipitation in mm
;     LONG_TERM_SUM_MM = long duration sum.  Typical in PWD, ie data is always summed
;       until hits 99.99, then starts over at 0. (Will require ANCDATA, mostlikey set to 99.99)
;      
;
; :Returns:
;   Will return a true/false (1/0) if the conversion was recognized.
;
; :Params:
;   data : in, required, type = scalar or array
;     The data to be converted. This data array will be modified and returned.
;   _in_unit : in, required, type = scalar string (case insensitive)
;     The current units of input data. (Example 'kPa')
;     Optionally, the units of both input and desired output seperated by "->"
;      Example: 'kPa->hPa' 
;   _out_unit : in, required/optional, type=scalar string (case insensitive)
;     The desired units of returned data. (Example 'hPa')
;     Option to leave undefind.  If not set will use the second case of _in_units
; 
;
; :Keywords:
;   ANCDATA : in, optional, type = scalar or array numeric
;     Additional data required for unit conversion if needed.  Only a one conversion 
;     currently needs additional data.  Data must match time step of input data.
;   ANC_IN_UNIT : in, optinal, type = scalar string
;     Units of ANCDATA. Required if ANCDATA provided.  Used to test units type 
;     for ANCDATA to determine if a conversion is needed.
;    
;  :Examples:
;    IDL> temp=findgen(5)
;    IDL> print, convert_units(temp,'c','f')
;       1
;    IDL> print, temp
;      32.0000      33.8000      35.6000      37.4000      39.2000
;
;
;    IDL> temp=findgen(5)
;    IDL> print, convert_units(temp,'c->f')
;       1
;    IDL> print, temp
;      32.0000      33.8000      35.6000      37.4000      39.2000
;
;
;    IDL> vapor_pressure=[0.82,0.825,0.821,0.829,0.839] 
;    IDL> temp=[16.68,16.59,16.47,16.4,16.29]
;    IDL> print, convert_units(vapor_pressure,'kPa','mmol/m3',ANCDATA=temp,ANC_IN_UNIT='c')
;       1
;    IDL> print, vapor_pressure
;      340.921      343.107      341.585      344.996      349.291
;
;  :Author: Ken Kehoe, ARM Data Quality Office, University of Oklahoma
;  :History: Created on 10/20/2010
;  :Version: $Id:$
;
;-
FUNCTION convert_units, data, _in_unit, _out_unit, $
	ANCDATA=ancdata, ANC_IN_UNIT=anc_in_unit

converted=1B

;-- Return data if _in_unit is empty string --;
IF (_in_unit EQ '') OR N_ELEMENTS(_in_unit) EQ 0 THEN RETURN, converted

;-- Return if in or out unit is unitless --;
IF STRUPCASE(_in_unit) EQ 'UNITLESS' OR STRUPCASE(_out_unit) EQ 'UNITLESS' THEN RETURN, converted
IF STRUPCASE(_in_unit) EQ '1' OR STRUPCASE(_out_unit) EQ '1' THEN RETURN, converted

in_unit = STRUPCASE(STRTRIM(_in_unit,2))
IF(N_ELEMENTS(_out_unit) GT 0) THEN BEGIN
	out_unit = STRUPCASE(STRTRIM(_out_unit,2))
ENDIF ELSE BEGIN
	result = STRSPLIT(in_unit,'->',/EXTRACT)
	in_unit=STRUPCASE(result[0])
	out_unit=STRUPCASE(result[1])
ENDELSE
;-- Return data if units are the same --;
IF(in_unit EQ out_unit) THEN RETURN, converted

;-- Return data if NULL --;
IF(N_ELEMENTS(data) EQ 0) THEN RETURN, converted

;-- Constants --;
stefan=5.670400E-8
K_offset=273.15
missValInd = -9999.0

;-- Return data if all missing value indicator --;
!NULL = WHERE(FINITE(data) EQ 1, ctNaN)
IF(ctNaN EQ 0) THEN RETURN, converted
indexMiss= WHERE(data LE missValInd+0.001,ctMissing,/NULL)
IF(ctMissing EQ N_ELEMENTS(data)) THEN RETURN, converted

;-- Replace -9999 with NaN --;
dataType = SIZE(data,/TYPE)
data = FIX(data,TYPE=SIZE(!VALUES.F_NAN,/TYPE))
data[indexMiss] = !VALUES.F_NAN
IF(N_ELEMENTS(ancdata) GT 0) THEN BEGIN
	ancdataType=SIZE(ancdata,/TYPE)
	ancdata = FIX(ancdata,TYPE=SIZE(!VALUES.F_NAN,/TYPE))
	ancMiss= WHERE(data LE missValInd+0.001,/NULL)
	ancdata[ancMiss]= !VALUES.F_NAN
ENDIF ;  ancdata IF

;-- Check for inconsistencies and fix --;
C_array = ['deg C','DegC','Degrees C.','DEGREE C']
units_lut = HASH(STRUPCASE(C_array),MAKE_ARRAY(N_ELEMENTS(C_array),VALUE='C'))
; Last unit in hash list is the "offcial" unit used.
units_lut = units_lut + HASH('PERCENTAGE','%')
units_lut = units_lut + HASH('% RH','%')
units_lut = units_lut + HASH('METERS ABOVE MEAN SEA LEVEL','M')
units_lut = units_lut + HASH('M/SEC','METERS PER SECOND','METERS_PER_SECOND','M/S')
units_lut = units_lut + HASH('M/SEC^2','M/S^2')
units_lut = units_lut + HASH('W/M2','W/M^2')
units_lut = units_lut + HASH('W/(M2 NM)','W/M^2-NM')
units_lut = units_lut + HASH('MMOL/M^3','MMOL/M3')
units_lut = units_lut + HASH('G/M3','G/M^3')
units_lut = units_lut + HASH('DEG F','F')
units_lut = units_lut + HASH('DEGF','F')
units_lut = units_lut + HASH('DEG K','K')
units_lut = units_lut + HASH('MILLIMETERS','MM')
units_lut = units_lut + HASH('DEGREES','DEG')
units_lut = units_lut + HASH('DEGREE','DEG')
units_lut = units_lut + HASH('KTS','KNOTS')
IF(units_lut.HasKey(in_unit)) THEN in_unit=units_lut[in_unit]
IF(units_lut.HasKey(out_unit)) THEN out_unit=units_lut[out_unit]

do_nothing = 'do_nothing'
;-- Perform Conversion or output error --;
CASE 1 OF
	(in_unit EQ out_unit): do_nothing = do_nothing
	(in_unit EQ 'C') AND (out_unit EQ 'K'): data = data + K_offset
	(in_unit EQ 'K') AND (out_unit EQ 'C'): data = data - K_offset
	(in_unit EQ 'C') AND (out_unit EQ 'F'): data = data*9.0/5.0 + 32.0
	(in_unit EQ 'F') AND (out_unit EQ 'C'): data = (data - 32.0)*5.0/9.0
	(in_unit EQ 'F') AND (out_unit EQ 'K'): data = (data - 32.0)*5.0/9.0 + K_offset
	(in_unit EQ 'K') AND (out_unit EQ 'F'): data = (data - K_offset)*9.0/5.0 + 32.0
	(in_unit EQ 'HPA') AND (out_unit EQ 'KPA'): data = data/10.0
	(in_unit EQ 'KPA') AND (out_unit EQ 'HPA'): data = data*10.0
	(in_unit EQ 'KPA') AND (out_unit EQ 'MB'): data = data*10.0
	(in_unit EQ 'HPA') AND (out_unit EQ 'MB'): do_nothing = do_nothing
	(in_unit EQ 'MB') AND (out_unit EQ 'HPA'): do_nothing = do_nothing
	(in_unit EQ 'FRACTION') AND (out_unit EQ '%'): data = data*100.0
	(in_unit EQ '%') AND (out_unit EQ 'FRACTION'): data = data/100.0
	(in_unit EQ 'K') AND (out_unit EQ 'IRR'): data = stefan*data^4
	(in_unit EQ 'K') AND (out_unit EQ 'W/M^2'): data = stefan*data^4
	(in_unit EQ 'W/M^2') AND (out_unit EQ 'K'): data = (data/stefan)^(1./4.)
	(in_unit EQ 'C') AND (out_unit EQ 'IRR'): data = stefan*(data+K_offset)^4
	(in_unit EQ 'MM') AND (out_unit EQ 'CM'): data = data/10.0
	(in_unit EQ 'M') AND (out_unit EQ 'CM'): data = data/100.0
	(in_unit EQ 'CM') AND (out_unit EQ 'MM'): data = data*10.0
	(in_unit EQ 'KM') AND (out_unit EQ 'M'): data = data*1000.0
	(in_unit EQ 'UM') AND (out_unit EQ 'NM'): data = data/1000.0
	(in_unit EQ 'NM') AND (out_unit EQ 'UM'): data = data*1000.0
	(in_unit EQ 'M') AND (out_unit EQ 'KM'): data = data/1000.0
	(in_unit EQ 'M/S') AND (out_unit EQ 'KNOTS'): data = data*1.94384
	(in_unit EQ 'KNOTS') AND (out_unit EQ 'M/S'): data = data*0.51444444
	(in_unit EQ 'MM/HR') AND (out_unit EQ 'CUMULATIVE_MM'): data=TOTAL(data/60.,/CUMULATIVE,/NAN)
	(in_unit EQ 'MM/HR') AND (out_unit EQ 'MM'): data = data/60.0
	(in_unit EQ 'MM') AND (out_unit EQ 'MM/HR'): data = data*60.0
	(in_unit EQ 'MM') AND (out_unit EQ 'CUMULATIVE_MM'): data=TOTAL(data,/CUMULATIVE,/NAN)
	(in_unit EQ 'KPA') AND (out_unit EQ 'MMOL/M3'): BEGIN
		ancdata_copy = ancdata
		result = convert_units(ancdata_copy,anc_in_unit,'C')
		data = data * 120499.06/(ancdata_copy + K_offset)
	END ; KPA -> MMOL/M3
	(in_unit EQ 'HPA') AND (out_unit EQ 'MMOL/M3'): BEGIN
		ancdata_copy = ancdata
		result = convert_units(ancdata_copy,anc_in_unit,'C')
		data = (data/10.0) * 120499.06/(ancdata_copy + K_offset)
	END ; KPA -> MMOL/M3
	(in_unit EQ 'LONG_TERM_SUM_MM') AND (out_unit EQ 'CUMULATIVE_MM'): BEGIN
		IF(N_ELEMENTS(data) GT 1) THEN BEGIN
			missing_index = WHERE(FINITE(data) EQ 0,missing_indexCt)
			avail_index = WHERE(FINITE(data) EQ 1,indexCt)

			index = WHERE(TS_DIFF(data[avail_index],1) GT 0, indexCt)
			IF(indexCt GT 0) THEN BEGIN

				data = -1.0* TS_DIFF(data[avail_index],1) + 0.0
				index = WHERE(data LT 0, indexCt)
				IF(indexCt GT 0) THEN data[index] = ancdata - ABS(data[index])
				data = TOTAL(data,/CUMULATIVE)
				IF(missing_indexCt GT 0) THEN $
				FOREACH ii, missing_index DO data = [data[0:ii-1],!VALUES.F_NAN,data[ii:-1]]

			ENDIF ELSE data = data - MIN(data,/NAN)
		ENDIF 
	END ; 'LONG_TERM_SUM_MM' -> 'CUMULATIVE_MM'
		
	ELSE: BEGIN 
		converted=0B
		PRINT & PRINT, '***********************************'
		PRINT, 'convert_units.pro: Unable to make converion: '+in_unit+' to '+out_unit
		PRINT, '***********************************'
	END
ENDCASE
data[indexMiss] = missValInd
data=FIX(data,TYPE=dataType)

IF(N_ELEMENTS(ancdata) GT 0) THEN BEGIN
	ancdata[ancMiss] = missValInd
	ancdata=FIX(ancdata,TYPE=ancdataType)
ENDIF ;  ancdata IF

RETURN, converted

END; Function End
