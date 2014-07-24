
;+
; Data Structure to hold the information on netCDF files and its data
;			
; @Author Tri Noensie
; @history August 2010
; @requires Pre-compiled: NCDFFILES, NCDFVAR
;-


;+
; Class Constructor
;
; <p> Note: This method cannot be called. It is done automatically 
;			when the object is first created </p>
;			
; @keyword PATH {in} {optional} {type= string}
;			The path to the netCDF files
;			
; @keyword DATE_START {in} {optional} {type= string}
;			The date of the first netCDF file
;			
; @keyword DATE_END {in} {optional} {type= string}
;			The date of the last netCDF file
;			
; @returns Returns 1B for success
;-
FUNCTION NETCDF_DATA::init, PATH = path, DATE_START = date_start, DATE_END = date_end
	self.files = ncdffiles()
	self.variables = hash()
	self.dimensions = list()
	self.global_atts = hash()
	if keyword_set(path) then (self.files).setPath, path
	if keyword_set(date_start) then (self.files).setDateStart, date_start
	if keyword_set(date_end) then (self.files).setDateEnd, date_end
	return, 1B
END


;+
; Adds new variable/field (only if it doesn't exist)
;			<br />Nothing will happen if the variable already exists
;			
; @param VAR_NAME {in} {required} {type= string}
;			Variable name
;					
; @param OBJECT {in} {required} {type= NCDFVAR}
;			NCDFVAR object to be inserted
;-
PRO NETCDF_DATA::addVar, var_name, object
	if not self.hasVar(var_name[0]) then (self.variables)[var_name[0]] = object
END


;+
; Sets a variable
;			<br />Adds new variable if it doesn't exists
;			<br />Replaces the object if the variable exists
;			
; @param VAR_NAME {in} {required} {type= string}
;			Variable name
;					
; @param OBJECT {in} {required} {type= NCDFVAR}
;			NCDFVAR object to be inserted
;-
PRO NETCDF_DATA::setVar, var_name, object
	(self.variables)[var_name[0]] = object
END


;+
; Removes a variable
;
; @param VAR_NAME {in} {required} {type= string}
;			The name(s) of variable to be removed
;-
PRO NETCDF_DATA::removeVar, var_name
	if self.hasVar(var_name[0]) then (self.variables).remove, var_name[0]
END


;+
; Renames a variable
;	
; @param CURRENT_NAME {in} {required} {type= string}
;			
; @param NEW_NAME {in} {required} {type= string}
;-
PRO NETCDF_DATA::renameVar, current_name, new_name
	if self.hasVar(current_name) then begin
		(self.variables)[new_name] = (self.variables)[current_name]
		(self.variables)[new_name].setName, new_name
		(self.variables).remove, current_name
	endif
END


;+
; Set variable data
;			
; @param VAR_NAME {in} {required} {type= string}
;			Variable name
;			
; @param DATA {in} {required} {type= dependent upon the variable}
;			Variable data
;
; @keyword CONCAT {in} {optional}
;			Concatenates the current data with the passed in data
;-
PRO NETCDF_DATA::setVarData, var_name, data, CONCAT = flag
	if self.hasVar(var_name[0]) then ((self.variables)[var_name[0]]).setData, data, concat = flag
END



;+
; Adds new attribute for a particular variable (only if it doesn't exist)
;			<br/>Nothing will happen if the attribute already exists
;
; @param VAR_NAME {in} {required} {type= string}
;			Variable Name
;			
; @param ATT_NAME {in} {required} {type= string}
;			Attribute Name
;			
; @param ATT_VALUE {in} {required} {type= dependent upon the attribute}
;			Attribute Value
;- 
PRO NETCDF_DATA::addVarAtt, var_name, att_name, att_value
	if self.hasVar(var_name[0]) then ((self.variables)[var_name[0]]).addAtt, att_name, att_value
END


;+
; Sets an attribute for a particular variable
;			<br />Adds new attribute if it doesn't exists
;			<br />Replaces the value if the attribute exists
;			
; @param VAR_NAME {in} {required} {type= string}
;			Variable Name
;			
; @param ATT_NAME {in} {required} {type= string}
;			Attribute Name
;			
; @param ATT_VALUE {in} {required} {type= dependent upon the attribute}
;			Attribute Value
;-
PRO NETCDF_DATA::setVarAtt, var_name, att_name, att_value
	if self.hasVar(var_name[0]) then ((self.variables)[var_name[0]]).setAtt, att_name, att_value
END

;+
; Removes attribute from particular variable
;			
; @param VAR_NAME {in} {required} {type= string}
;			Variable name
;			
; @param ATT_NAME {in} {required} {type= string}
;			Attribute Name
;-
PRO NETCDF_DATA::removeVarAtt, var_name, att_name
	if self.hasVar(var_name[0]) then ((self.variables)[var_name[0]]).removeAtt, att_name
END


;+
; Adds new global attribute (only if it doesn't exist)
;			<br/> Nothing will happen if it already exists
;			
; @param GBLATT_NAME {in} {required} {type= string}
;			Global Attribute name
;			
; @param VALUE {in} {required} {type= dependent upon the global attribute}
;			Global attribute value
;-
PRO NETCDF_DATA::addGblAtt, gblatt_name, value
	if not self.hasGblAtt(gblatt_name) then (self.global_atts)[gblatt_name] = value
END


;+
; Sets a global attribute
;			<br />Adds new attribute if it doesn't exists
;			<br />Replaces the value if the attribute exists
;			
; @param GBLATT_NAME {in} {required} {type= string}
;			Global Attribute name
;			
; @param VALUE {in} {required} {type= dependent upon the global attribute}
;			Global attribute value
;-
PRO NETCDF_DATA::setGblAtt, gblatt_name, value
	(self.global_atts)[gblatt_name] = value
END


;+
; Removes global attribute
;
; @param GBLATT_NAME {in} {required} {type= string}
;			Global Attribute name
;-
PRO NETCDF_DATA::removeGblAtt, gblatt_name
	if self.hasGblAtt(gblatt_name) then (self.global_atts).remove, gblatt_name
END


;+
; Set array of netCDF filenames
;
; @param FILES {in} {required} {type= string array}
;-
PRO NETCDF_DATA::setFiles, files
	(self.files).setFiles, files
END


;+
; Set the path to the netCDF files
;			
; @param PATH {in} {required} {type= string}
;-
PRO NETCDF_DATA::setPath, path
	(self.files).setPath, path
END


;+
; Set Date Start
;			
; @param DATE {in} {required} {type= string/integer}
;-
PRO NETCDF_DATA::setDateStart, date
	(self.files).setDateStart, date
END


;+
; Set Date End
;			
; @param DATE {in} {required} {type= string/integer}
;-
PRO NETCDF_DATA::setDateEnd, date
	(self.files).setDateEnd, date
END


;+
; Set time
;			
; @param TIME_DATA {in} {required} {type= array of any type}
;			
; @keyword CONCAT {in} {optional}
;			The flag to concatenate the current time data and the procedure argument
;-
PRO NETCDF_DATA::setTime, time_data, CONCAT = concat
	if ptr_valid(self.time) then begin
		if keyword_set(concat) then *self.time = [*self.time, time_data] $
		else begin 
			ptr_free, self.time
			self.time = ptr_new(time_data)
		endelse
	endif else self.time = ptr_new(time_data)
END


;+
; Returns the hash of ncdfvar objects 
;			
; @returns Return type: hash
;-
FUNCTION NETCDF_DATA::getVars
	return, self.variables
END


;+
; Returns variable object
;			
; @param VAR_NAME {in} {required} {type=string}
;			Variable Name
;			
; @returns Return type: NCDFVAR object
;			<br /> Returns NULL, if an error occurs at retrieving data.
;-
FUNCTION NETCDF_DATA::getVar, var_name
	if self.hasVar(var_name[0]) then begin
		return, (self.variables)[var_name[0]]
	endif else return, !NULL
END


;+
; Returns an array of variable names
;			
; @returns Return type: string array
;-
FUNCTION NETCDF_DATA::getVarNames
	return, ((self.variables).keys()).toArray()
END
		

;+
; Returns variable data
;
; @param VAR_NAME {in} {required} {type= string}
;			Variable Name
;
; @returns Return type: array- dependent upon variable
;			<br /> Returns NULL, if an error occurs at retrieving data.
;-
FUNCTION NETCDF_DATA::getVarData, var_name
	if self.hasVar(var_name[0]) then begin
		return, ((self.variables)[var_name[0]]).getData()
	endif else return, !NULL
END


;+
; Returns hash of attributes for specified variable
;
; @param VAR_NAME {in} {required} {type= string}
;			Variable Name
;
; @returns Return type: hash
;			<br /> Returns NULL, if an error occurs at retrieving data.
;-
FUNCTION NETCDF_DATA::getVarAtts, var_name
	if self.hasVar(var_name[0]) then begin
		return, ((self.variables)[var_name[0]]).getAtts()
	endif else return, !NULL
END


;+
; Returns a list of attribute names for specified variable
;			
; @param VAR_NAME {in} {required} {type= string}
;			Variable Name
;			
; @returns Return type: string array
;			<br /> Returns NULL, if an error occurs at retrieving data.
;-
FUNCTION NETCDF_DATA::getVarAttNames, var_name
	if self.hasVar(var_name[0]) then begin
		return, ((self.variables)[var_name[0]]).getAttNames()
	endif else return, !NULL
END

 
;+
; Returns attribute value from specified variable
;
; @param VAR_NAME {in} {required} {type= string}
;			Variable name 
;
; @param ATT_NAME {in} {required} {type= string}
;			Attribute name
;			
; @returns Return type: Dependent upon attribute
;			<br /> Returns NULL, if an error occurs at retrieving data.
;-
FUNCTION NETCDF_DATA::getVarAttValue, var_name, att_name
	if self.hasVar(var_name[0]) then begin
		return, ((self.variables)[var_name[0]]).getAttValue(att_name)
	endif else return, !NULL
END
	

;+
; Returns hash of global attributes
;			
; @returns Return type: hash
;-
FUNCTION NETCDF_DATA::getGblAtts
	return, self.global_atts
END


;+
; Returns list of global attribute names
;			
; @returns Return type: string array
;-
FUNCTION NETCDF_DATA::getGblAttNames
	return, ((self.global_atts).keys()).toArray()
END


;+
; Returns global attribute value
;			
; @param GBLATT_NAME {in} {required} {type= string}
;			Global Attribute name
;			
; @returns Return type: dependent upon the global attribute
;			<br /> Returns NULL, if an error occurs at retrieving data.
;-
FUNCTION NETCDF_DATA::getGblAttValue, gblatt_name
	if self.hasGblAtt(gblatt_name) then begin
		return, (self.global_atts)[gblatt_name]
	endif else return, !NULL
END


;+
; Returns the information of the netCDF files (ncdffiles object)
;			
; @returns Return type: NCDFFILES object
;-
FUNCTION NETCDF_DATA::getFilesInfo
	return, self.files
END


;+
; Return the list of files
;			
; @returns Return type: string array
;-
FUNCTION NETCDF_DATA::getFileList
	return, (self.files).getFileList()
END


;+
; Returns the path to the netCDF files
;
; @returns Return type: string
;-
FUNCTION NETCDF_DATA::getPath
	return, (self.files).getPath()
END

;+
; Returns the date of the first netCDF file
;
; @returns Return type: string
;-
FUNCTION NETCDF_DATA::getDateStart
	return, (self.files).getDateStart()
END


;+
; Returns the date of the last netCDF file
; 
; @returns Return type: string
;-
FUNCTION NETCDF_DATA::getDateEnd
	return, (self.files).getDateEnd()
END


;+
; Returns an array of time spanning from 'DATE_START' to 'DATE_END'
; 
; @returns Return type: integer array
;			<br /> Returns NULL if it doesn't exist
;-
FUNCTION NETCDF_DATA::getTime
	if ptr_valid(self.time) then begin
		return, *self.time
	endif else return, !NULL
END


;+
; Searches the existence of the variable
;			
; @param VAR_NAME {in} {required} {type= string}
;			Variable Name
;			
; @returns Return type: boolean
;-
FUNCTION NETCDF_DATA::hasVar, var_name
	return, (self.variables).hasKey(var_name[0])
END


;+
; Searches the existence of the attribute of a particular variable
;			
; @param VAR_NAME {in} {required} {type= string}
;			Variable Name
;			
; @param ATT_NAME {in} {required} {type= string}
;			Attribute Name
;			
; @returns Return type: boolean
;-
FUNCTION NETCDF_DATA::hasVarAtt, var_name, att_name
	if self.hasVar(var_name[0]) then begin
		return, ((self.variables)[var_name[0]]).hasAtt(att_name)
	endif else return, 0
END


;+
; Searches the existence of the Global Attribute
;			
; @param GBLATT_NAME {in} {required} {type= string}
;			Global Attribute Name
;			
; @returns Return type: boolean
;-
FUNCTION NETCDF_DATA::hasGblAtt, gblatt_name
	return, (self.global_atts).hasKey(gblatt_name)
END


;+
; Returns the number of variables
;			
; @returns Return type: integer
;-
FUNCTION NETCDF_DATA::n_vars
	return, n_elements(self.variables)
END


;+
; Returns the number of attributes of a particular variable
;			
; @param VAR_NAME {in} {required} {type= string}
;			Variable Name
;			
; @returns Return type: integer 
;			<br /> Returns NULL if the variable doesn't exist
;-
FUNCTION NETCDF_DATA::n_varAtts, var_name
	if self.hasVar(var_name[0]) then begin
		return, ((self.variables)[var_name[0]]).n_atts()
	endif else return, !NULL
END


;+
; Returns the number of global attributes
;			
; @returns Return type: integer
;-
FUNCTION NETCDF_DATA::n_gblAtts
	return, n_elements(self.global_atts)
END


;+
; Returns the number of netCDF files
;			
; @returns Return type: integer
;-
FUNCTION NETCDF_DATA::n_files
	return, (self.files).n_files()
END


;+
; Set dimensions
;			
; @param VAR_NAME {in} {required} {type= string}
;			Variable name
;			
; @param DIMENSIONS {in} {required} {type= scalar string or string array}
;			Variable dimensions
;
;-
PRO NETCDF_DATA::setVarDims, var_name, dimension
	if self.hasVar(var_name[0]) then ((self.variables)[var_name[0]]).setDimensions, dimension
END

;+
; Returns the number of dimensions of particular variable
;			
; @param VAR_NAME {in} {required} {type= string}
;			Variable Name
;			
; @returns Return type: integer 
;			<br /> Returns NULL if the variable doesn't exist
;-
FUNCTION NETCDF_DATA::n_varDims, var_name
	if self.hasVar(var_name[0]) then begin
		return, ((self.variables)[var_name[0]]).n_dimensions()
	endif else return, !NULL
END

;+
; Returns dimension value from specified variable
;
; @param VAR_NAME {in} {required} {type= string}
;			Variable name 
;			
; @returns Return type: string array
;			<br /> Returns NULL, if an error occurs at retrieving data.
;-
FUNCTION NETCDF_DATA::getVarDims, var_name
	if self.hasVar(var_name[0]) then begin
		return, ((self.variables)[var_name[0]]).getDimensions()
	endif else return, !NULL
END

;+
; @hidden
; Takes care overlapping files for the variable fields
;-
PRO NETCDF_DATA::overlapHandler_var, var_name, stop_ndx, file, var_ndx
	
	fileID = ncdf_open(file)
	varID = ncdf_varid(fileID,var_name[0])
	varDim = (ncdf_varinq(fileID, varID)).nDims
	ncdf_varget, fileID, varID, data_read
	
	if(varDim EQ 1) then begin
		
		self.setVarData, var_name[0], data_read[0:stop_ndx], /concat
		
	endif else if (varDim EQ 2) then begin
		
		;Transpose the data that has been read
		;IDL reads netCDF file with 'time' as the last array orientation
		;'time' needs to be on the first array orientation to properly concatenate data
		data_read = transpose(data_read)
		
		self.setVarData, var_name[0], data_read[0:stop_ndx, *], /concat
		
	endif else if (varDim EQ 3) then begin
		
		;Transpose the data that has been read
		;IDL reads netCDF file with 'time' as the last array orientation
		;'time' needs to be on the first array orientation to properly concatenate data
		data_read = transpose(data_read)
		
		self.setVarData, var_name[0], data_read[0:stop_ndx, *, *], /concat
		
	endif else begin
		print & print, 'The variable dimesion is greater than 3'
		print, 'Solutions have not been created for this overlapping condition'
		print, 'The program will now exit' & print
		ncdf_close, id
		stop
	endelse
	
	ncdf_close, id
END 


;+
; @hidden
; Takes care overlapping files for the time field
;-
PRO NETCDF_DATA::overlapHandler_time, file, stop_ndx
	
	id = ncdf_open(file)
	
	;Convert time from the first file and convert it IDL format
	ncdf_varget, id, 0, base_time
	ncdf_varget, id, 1, time_offset
	time = julday(1,1,1970,0,0,(base_time + time_offset))
	
	self.setTime, time[0:stop_ndx], /CONCAT
	ncdf_close, id
END


;+
; Displays all the fields in NETCDF_DATA object
;			<br /> Use the IDL 'print' command 
;			and pass in the object to invoke this method
;-
FUNCTION NETCDF_DATA::_overloadPrint
	print & print, '############### NetCDF Files ###############'
	print, self.files
	print, 'Variables: '
	foreach variable_info, self.variables do print, variable_info[0]
	print, '****************************'
	print,'Global attributes: '
	;foreach value, self.global_atts, name do print, ' ', name[0], ' = ', strtrim(value[0],2)
	print, self.global_atts
	return, ''
END


;+
; @hidden
; Cleanup
;-
PRO NETCDF_DATA::cleanup
	(self.files).Cleanup
	if ptr_valid(self.time) then ptr_free, self.time
END


;+
; @hidden
; The structure definition for the class 
;			
; @field FILES
;			Holds any information regarding the netCDF files
;			
; @field VARIABLES
;			Hash of variables/fields
;			
; @field GLOBAL_ATTS
;			Hash of global attributes 
;			
; @field TIME
;			Time data in julian format
;-
PRO NETCDF_DATA__define
	struct= {	NETCDF_DATA, $
				INHERITS IDL_Object, $
				files: NCDFFILES(), $
				variables: hash(), $
				dimensions: list(), $
				global_atts: hash(), $
				time: ptr_new() $
			}
END
