; docformat = 'rst'
;+
;  Function to determine which bits have been declaired in qc_ field.
; 
; :Params:
;   ds_object : in, required, type=object
;     object holding the variable and attribute information describing the bits.
;
;   field : in, required, type=string
;     scalar string of desired variable listed within ds_object
;
;  :Returns: Long integer array of bits declared with variable attribute or
;    scalar of next free bit number if RET_NEXT_FREE flag set
;
;  :Keywords:
;    ASSESSMENT : out, optional, type=string array
;      The string array of assessment values for each bit
;
;    DESCRIPTION : out, optional, type=string array
;      The string array of description values for each bit
;
;    COMMENT : out, optional, type=string array
;      The string array of comment values for each bit. If no comment bit is set
;      value is null string.
;
;    RET_NEXT_FREE : in, optional, type=flag
;      Flag indicating the returned value shoul be a scaler number of the 
;      next free bit for adding a test
;
;  :Examples:
;    IDL> bits = bits_declared(ds_object,'qc_mean_temp')
;    IDL> print, bits
;    1  2  3  4
; 
; :Author: Ken Kehoe, ARM Data Quality Office, University of Oklahoma
; :History: Created = May 26, 2010
; :Version: $Id: bits_declared.pro 48755 2013-10-28 17:20:59Z kehoe $
;-
FUNCTION bits_declared, ds_object, field,ASSESSMENT=assessment,$
  DESCRIPTION=description,COMMENT=comment,RET_NEXT_FREE=ret_next_free

bits_set = !NULL
assessment = !NULL
description = !NULL
comment = !NULL
FOREACH att_name, ds_object->getVarAttNames(field) DO BEGIN
  IF NOT STREGEX(att_name,'^.+_[0-9]{1,2}_description$',/boolean) THEN CONTINUE
  str_split = STREGEX(att_name,'^(.+)_([0-9]{1,2})_(description)$',/SUBEXPR,/EXTRACT)
  count = N_ELEMENTS(str_split)
  bit=LONG(str_split[count-2])
  IF ARG_PRESENT(assessment) THEN $
     assessment=[assessment,ds_object.getVarAttValue(field,'bit_'+STRTRIM(bit,2)+'_assessment')]
  IF ARG_PRESENT(description) THEN $
    description=[description,ds_object->getVarAttValue(field,att_name)]
  IF ARG_PRESENT(comment) THEN BEGIN
    value = ds_object.getVarAttValue(field,'bit_'+STRTRIM(bit,2)+'_comment')
    IF N_ELEMENTS(value) EQ 0 THEN value = ''
    comment=[comment,value]
  ENDIF ; comment
  bits_set=[bits_set,bit]
ENDFOREACH ; att_name FOREACH

;-- If requested calculate next free bit and only return the single number --;
IF KEYWORD_SET(ret_next_free) THEN BEGIN
  IF N_ELEMENTS(bits_set) EQ 0 THEN BEGIN
    bits_set = 1L
  ENDIF ELSE BEGIN
    bits_set = MAX(bits_set)+1L
  ENDELSE ; bits_set
ENDIF ; ret_next_free

;-- Return zero if no bits set --;
IF N_ELEMENTS(bits_set) EQ 0 THEN bits_set=0

RETURN, bits_set

END 
