FUNCTION call_ws, QUERY=query,RESPONSE_CODE=response_code, RESPONSE_HEADER=rspHeader

;-- Set default value --;
response=[]

; Make the request and save the response into a string array.   
oUrl = OBJ_NEW('IDLnetUrl')

; Set URL info ;
oUrl->SetProperty, VERBOSE = 1, CONNECT_TIMEOUT = 10, TIMEOUT = 60, $
  URL_SCHEME = 'http', URL_HOSTNAME='www.archive.arm.gov', $
  URL_PATH='dqrws/ARMDQR',URL_QUERY=query

CATCH, errVal
IF errVal NE 0 THEN BEGIN
  CATCH, /CANCEL
ENDIF ELSE BEGIN
  response = oUrl->Get(/STRING_ARRAY)
ENDELSE
oUrl->GetProperty, RESPONSE_CODE=response_code,RESPONSE_HEADER=rspHeader

OBJ_DESTROY, oUrl

RETURN, response

END; function end


PRO armws, DATASTREAM=_datastream, FIELD=field, STARTDATE=startdate, ENDDATE=enddate, $
  DATERANGES=dateranges, DATAVALUES=data, TIME=time, INDEX = index, IDLJULDAY=idljulday,$
  BASETIME_TIMEOFFSET=basetime_timeoffset,RESPONSE_CODE=response_code, METRIC=metric, $
  VERBOSE=verbose, IGNORE_THESE_DQRS=ignore_these_dqrs,CROWD_SOURCE=crowd_source,$
  RESPONSE_HEADER=rspHeader

;CATCH, errVal
;IF errVal NE 0 THEN BEGIN
;  CATCH, /CANCEL
;  RETURN
;ENDIF

IF N_ELEMENTS(idljulday) EQ 0 AND N_ELEMENTS(basetime_timeoffset) EQ 0 THEN idljulday=1
dateranges=!NULL

ARMFS, _datastream, DATASTREAM=datastream

query='datastream='+datastream
query=query+'&varname='+field
query=query+'&timeformat=armtime'
query=query+'&dqrfields=starttime,endtime'
IF N_ELEMENTS(ignore_these_dqrs) GT 0 THEN query=query+',dqrid' 
query=query+'&responsetype=delimited'
IF N_ELEMENTS(metric) EQ 0 THEN metric='incorrect'
query=query+'&searchmetric='+metric
IF N_ELEMENTS(startdate) GT 0 THEN BEGIN
  sd=STREGEX(STRTRIM(startdate,2),'([0-9]{4})([0-9]{2})([0-9]{2})',/EXTRACT,/SUBEX) 
  sd=ROUND((JULDAY(sd[2],sd[3],sd[1],0,0,0)-JULDAY(1,1,1970,0,0,0))*24D*60D*60D)
  query=query+'&startdate='+STRTRIM(sd,2)
ENDIF ; startdate
IF N_ELEMENTS(enddate) GT 0 THEN BEGIN
  ed=STREGEX(STRTRIM(startdate,2),'([0-9]{4})([0-9]{2})([0-9]{2})',/EXTRACT,/SUBEX) 
  ed=ROUND((JULDAY(ed[2],ed[3],ed[1],23,59,59)-JULDAY(1,1,1970,0,0,0))*24D*60D*60D)
  query=query+'&enddate='+STRTRIM(ed,2)
ENDIF ; enddate

;-- Get web service response -;
response=call_ws(QUERY=query, RESPONSE_CODE=response_code,RESPONSE_HEADER=rspHeader)

;-- Parse response --;
starttime=[]
endtime=[]
count=0
IF N_ELEMENTS(response) GT 0 THEN !NULL=STRSPLIT(response,'|',COUNT=count)
IF TOTAL(count) GT 0 THEN BEGIN
  FOR ii=0, N_ELEMENTS(response)-1 DO BEGIN
    rs = STRSPLIT(response[ii],'|',/EXTRACT)
    IF rs[0] EQ 'null' OR rs[0] EQ '' THEN rs[0]='0'
    IF rs[1] EQ 'null' OR rs[1] EQ '' THEN BEGIN
      rs = DOUBLE([rs[0],(JULDAY(1,1,3001,0,0,0) - JULDAY(1,1,1970,0,0,0))*60D*60D*24D])
    ENDIF ; rs[1]

    ;-- Check if DQR matches the exclude DQRs --;
    IF N_ELEMENTS(ignore_these_dqrs) GT 0 THEN BEGIN
      IF (WHERE(rs[2] EQ ignore_these_dqrs))[0] NE -1 THEN CONTINUE
    ENDIF; 

    rs = DOUBLE(rs[0:1])
    starttime=[starttime,JULDAY(1,1,1970,0,0,rs[0])]
    endtime=[endtime,JULDAY(1,1,1970,0,0,rs[1])]
  ENDFOR ; ii
ENDIF ; response 

;-- Call Crowd Source database if asked --;
IF KEYWORD_SET(crowd_source) THEN BEGIN
  result = sqlite_get(DATASTREAM=datastream,FIELD=field)
  IF N_ELEMENTS(result) GT 0 THEN BEGIN
    starttime = [starttime,REFORM(result[0,*])]
    endtime = [endtime,REFORM(result[1,*])]
  ENDIF ; result
ENDIF; crowd_source

;-- If no time ranges return --;
IF N_ELEMENTS(starttime) EQ 0 THEN RETURN

IF KEYWORD_SET(verbose) THEN BEGIN
  print_statement = '----- Start time - End Time ------ for '+datastream+':'+field+':'+metric
  IF KEYWORD_SET(crowd_source) THEN print_statement = print_statement+':crowd_source'
  PRINT, print_statement
  FOR ii=0, N_ELEMENTS(starttime)-1 DO $
    PRINT, SYSTIME(0,ROUND((starttime[ii] - JULDAY(1,1,1970,0,0,0))*60D*60D*24D,/L64))+' - '+SYSTIME(0,ROUND((endtime[ii] - JULDAY(1,1,1970,0,0,0))*60D*60D*24D,/L64))
  PRINT, '------------------------------'
  PRINT
ENDIF ; verbose

;-- Sort the times by cronological order --;
ind=SORT(starttime)
starttime=starttime[ind]
endtime=endtime[ind]

;--Set bad data to NaN or -9999 if not type FLOAT or DOUBLE --;
IF N_ELEMENTS(data) GT 0 OR N_ELEMENTS(time) GT 0 THEN BEGIN

  CASE SIZE(data,/TNAME) OF
    'BYTE' : BEGIN
      data=FIX(data) 
      nan_type = -9999
    END ; 
    'INT': nan_type = -9999
    'LONG' : nan_type = -9999L
    'FLOAT' : nan_type=!VALUES.F_NAN 
    'DOUBLE' : nan_type=!VALUES.D_NAN
    'UINT' : nan_type = 0U - 1U
    'ULONG' : nan_type = 0UL - 1UL
    'LONG64' : nan_type = -9999LL
    'ULONG64' : nan_type = 0ULL - 1ULL
    'COMPLEX' : nan_type = COMPLEX(!VALUES.F_NAN,!VALUES.F_NAN)
    'DCOMPLEX' : nan_type = DCOMPLEX(!VALUES.D_NAN,!VALUES.D_NAN)
    ELSE: nan_type=FIX(-9999,TYPE=SIZE(data,/TYPE))
  ENDCASE 

  index = []
  FOR ii=0, N_ELEMENTS(starttime)-1 DO $
    index = [index,WHERE(time GE starttime[ii] AND time LE endtime[ii], /NULL)]
  IF N_ELEMENTS(index) GT 0 THEN index = index[UNIQ(index, SORT(index))]
  IF N_ELEMENTS(data) GT 0 THEN data[index]=nan_type

ENDIF ; data & time

IF ARG_PRESENT(dateranges) THEN dateranges=[[starttime],[endtime]] 


END ; procedure end

