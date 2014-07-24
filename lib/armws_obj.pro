PRO armws_obj, DS_OBJECT=ds_object, METRICS=metrics, VARIABLES=variables, $
  QC_ONLY=qc_only, NO_QC=no_qc, IGNORE_THESE_DQRS=ignore_these_dqrs,$
   INDEX=return_index, CROWD_SOURCE=crowd_source

IF N_ELEMENTS(metrics) EQ 0 THEN metrics = ['incorrect']
metrics = STRLOWCASE(metrics)

armfs, (ds_object->getFileList())[0], DATASTREAM=datastream

variablesCt = 0
;-- Loop over each variable in the object --;
FOREACH var_name, ds_object->getVarNames() DO BEGIN
  var_name = var_name[0] ; IDL 8.0 bug fix
  qc_var_name = 'qc_'+var_name

  ;-- Skip qc_ variables --; 
  IF STRMID(var_name,0,3) EQ 'qc_' THEN CONTINUE
 
  ;-- Check if var_name is in requested list if provided --;
  IF N_ELEMENTS(variables) GT 0 THEN BEGIN
    !NULL = WHERE(var_name EQ variables, variablesCt)
    IF variablesCt EQ 0 THEN CONTINUE
  ENDIF ; variables

  ;-- Check if var_name data is a scalar and not listed in variables. If so continue --;
  IF SIZE(ds_object->getVarData(var_name),/N_DIMENSIONS) EQ 0 $
     AND variablesCt EQ 0 THEN CONTINUE

  ;-- Get data from object --;
  data = !NULL
  IF NOT KEYWORD_SET(qc_only) THEN data = ds_object->getVarData(var_name)

  ;-- Loop over each metric and query web-service. 
  ; If requested will set data matching DQR times to missing_value --;
  ;return_index=!NULL
  FOREACH metric, metrics DO BEGIN
    armws, DATASTREAM=datastream, FIELD=var_name, DATAVALUES=data, INDEX=index, $ 
      TIME=ds_object->getTime(), METRIC=metric, IGNORE_THESE_DQRS=ignore_these_dqrs,$
      CROWD_SOURCE=crowd_source
    ;return_index=[return_index,index]

    ; If overlaping times are found set data in object 
    IF N_ELEMENTS(index) GT 0 THEN BEGIN
      IF N_ELEMENTS(data) GT 0 THEN ds_object->setVarData, var_name, data

      ; If qc variables exists trip bits and set new bit description
      !NULL = WHERE(qc_var_name EQ ds_object->getVarNames(), indexCt)
      IF indexCt GT 0 && NOT KEYWORD_SET(no_qc) THEN BEGIN
        qc_data = !NULL
        qc_data = ds_object->getVarData(qc_var_name)
        bit=MAX(bits_declared(ds_object,qc_var_name)) + 1
        IF MAX(bits_declared(ds_object,qc_var_name)) LT 0 THEN CONTINUE

        ;-- If overlapping times are found trip bits and add description --;
        IF metric EQ 'incorrect' THEN assessment='Bad' ELSE assessment='Indeterminate'
        IF N_ELEMENTS(index) GT 0 AND N_ELEMENTS(qc_data) GT 0 THEN $
          qc_data[index] = bits(qc_data[index],ADD=bit)
        ds_object->addVarAtt, qc_var_name, 'bit_'+STRTRIM(bit,2)+'_description', $
		     'DQO: Corresponding '+metric+' DQR found' 
        ds_object->addVarAtt, qc_var_name, 'bit_'+STRTRIM(bit,2)+'_assessment', $
		     assessment
	     ds_object->setVarData, qc_var_name, qc_data

      ENDIF ; indexCt
    ENDIF ; dateranges
  ENDFOREACH ; metric
  
ENDFOREACH ; var_name

END ; Procedure end





