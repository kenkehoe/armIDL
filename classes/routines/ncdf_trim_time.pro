PRO ncdf_trim_time,obj,_date_start,_date_end

IF NOT OBJ_VALID(obj) THEN RETURN

regex = '(^[0-9]{4})([0-9]{2})([0-9]{2})\.{0,1}([0-9]{0,2})([0-9]{0,2})([0-9]{0,2})'
dd = STREGEX(_date_start,regex,/SUBEXP,/EXTRACT)
IF dd[4] EQ '' THEN date_start = JULDAY(dd[2],dd[3],dd[1],0,0,0) ELSE $
  date_start = JULDAY(dd[2],dd[3],dd[1],dd[4],dd[5],dd[6])
dd = STREGEX(_date_end,regex,/SUBEXP,/EXTRACT)
IF dd[4] EQ '' THEN date_end = JULDAY(dd[2],dd[3],dd[1],23,59,59) ELSE $
  date_end = JULDAY(dd[2],dd[3],dd[1],dd[4],dd[5],dd[6])

;-- Get indexes in time matching date range --;
time = obj->getTime()
time_index = WHERE(time GE date_start AND time LE date_end, indexCt)
IF indexCt EQ 0 THEN BEGIN
  OBJ_DESTROY, obj
  RETURN
ENDIF ; indexCt

;-- Subset time and replace in object --;
time = time[time_index]
obj->setTime, time
;-- Reorder files to put "run date" file first for metadata processing --;
files = obj->getFileList()
armfs, files, YYYYMMDD=dates
index = WHERE(dates EQ _date_end, /NULL,COMPLEMENT=comp,NCOMPLEMENT=compCt)
IF compCt GT 0 THEN obj->setFiles, [files[index],files[comp]]

;-- Loop over all fields and subset time index in arrays --;
FOREACH field, obj->getVarNames() DO BEGIN

  IF SIZE(obj->getVarData(field),/N_DIMENSIONS) EQ 0 THEN CONTINUE
  !NULL = WHERE(obj->getVarDims(field) EQ 'time',indexCt)
  IF indexCt EQ 0 THEN CONTINUE

  data = obj->getVarData(field)
  data = data[time_index,*,*,*,*,*]
  obj->setVarData, field, data  

ENDFOREACH ; field

RETURN

END ; Procedure End
