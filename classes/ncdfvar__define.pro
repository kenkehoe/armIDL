
;+
; Data structure to hold the values of a netCDF variable and its attributes
; 
; @Author Tri Noensie
; @history August 2010
;-

;+
; Class constructor
;			
; <p> Note: This method cannot be called. It is done automatically 
;			when the object is first created </p>
;			
; @keyword NAME {in} {optional} {type= string}
;			Name of variable
;			
; @keyword DATA {in} {optional} {type= dependent upon variable}
;			Variable data
;			
; @returns 1B for success
;-	
FUNCTION NCDFVAR::init, NAME = name, DATA = data
	if keyword_set(name) then self.name = name 
	if keyword_set(data) then self.data = ptr_new(data)
	self.attributes = hash()
	self.dimensions = list()
	return, 1B
END


;+
; Set the variable name
;			
; @param NAME {in} {required} {type= string}
;			Variable name
;-
PRO NCDFVAR::setName, name
	self.name = name
END


;+
; Adds new attribute (only if it doesn't exist)
;			<br /> Nothing will happen if the attribute already exists
;			
; @param ATT_NAME {in} {required} {type= string}
;			Attribute name
;			
; @param VALUE {in} {required} {type= dependent upon the attribute}
;			Attribute value	
;-
PRO NCDFVAR::addAtt, att_name, value
	if not self.hasAtt(att_name) then self.setAtt, att_name, value
END


;+
; Set Attribute
;			<br />Adds new attribute if it doesn't exists
;			<br />Replaces the value if the attribute exists
;			
; @param ATT_NAME {in} {required} {type= string}
;			Attribute name
;			
; @param VALUE {in} {required} {type= dependent upon the attribute}
;			Attribute value
;-
PRO NCDFVAR::setAtt, att_name, value
	(self.attributes)[att_name] = value
END


;+
; Removes an attribute
;			
; @param ATT_NAME {in} {required} {type= string}
;			Attribute name
;-
PRO NCDFVAR::removeAtt, att_name
	if self.hasAtt(att_name) then (self.attributes).remove, att_name
END


;+
; Setting variable data or concatenating current variable data with new data
;			
; @param DATA {in} {required} {type= Dependent upon variable}
;			Variable Data
;			
; @keyword CONCAT {in} {optional} {type= Boolean}
;			Flag for the method to concatenate current data with new data
;-
PRO NCDFVAR::setData, data, CONCAT = concat
	;Algorithm
	;	-Check if the pointer is valid
	;		-If pointer is valid:
	;			-Concatenate data if specified
	;			-If not, release heap and set new data
	;		-If pointer is not valid: set new data
	
	if ptr_valid(self.data) then begin 
		if keyword_set(concat) then *self.data = [*self.data,data] $
		else begin
			ptr_free, self.data
			self.data = ptr_new(data)
		endelse
	endif else self.data = ptr_new(data)
END


;+
; Returns variable name
; 
; @returns Return type: string
;-
FUNCTION NCDFVAR::getName
	return, self.name
END


;+
; Returns HASH of attributes 
;			
; @returns Return type: HASH
;-
FUNCTION NCDFVAR::getAtts
	return, self.attributes
END


;+
; Returns a list of attribute names
;			
; @returns Return type: string array
;-
FUNCTION NCDFVAR::getAttNames
	return, ((self.attributes).Keys()).toArray()
END


;+
; Returns attribute value
;			
; @param ATT_NAME {in} {required} {type= string}
;			Attribute name
;	
; @returns Return type: dependent upon the attribute
;			<br /> Returns NULL, if an error occurs at retrieving data.
;-
FUNCTION NCDFVAR::getAttValue, att_name
	if self.hasAtt(att_name) then begin
		return, (self.attributes)[att_name]
	endif else return, !NULL
END


;+
; Returns data of variable
;			
; @returns Returns data (type: array- dependent upon variable)
;			<br /> Returns NULL if data does not exist
;-
FUNCTION NCDFVAR::getData
	if ptr_valid(self.data) then begin
		return, *self.data
	endif else return, !NULL
END


;+ 
; Searches for the existence of the attribute
;			
; @param ATT_NAME {in} {required} {type= string}
;			Attribute Name
;			
; @returns Return type: boolean
;-
FUNCTION NCDFVAR::hasAtt, att_name
	return, (self.attributes).hasKey(att_name)
END


;+
; Returns the number of attributes
;			
; @returns Return type: integer
;-
FUNCTION NCDFVAR::n_atts
	return, n_elements(self.attributes)
END


;+
; Returns the number of dimensions
;			
; @returns Return type: integer
;-
FUNCTION NCDFVAR::n_dimensions
	return, n_elements(self.dimensions) 
END

;+
; Returns array of dimensions
;			
; @returns Return type: String array
;-
FUNCTION NCDFVAR::getDimensions
	return, (self.dimensions).ToArray()
END

;+
; Set Dimensions
;			<br />Adds new dimension if it doesn't exists
;			<br />Replaces the value if exists
;			
; @param VALUE {in} {required} {type = scalar string or string array or list}
;			Dimension value
;-
PRO NCDFVAR::setDimensions, values
	IF(n_elements(values) GT 0) THEN BEGIN
		self.dimensions=list()
		(self.dimensions).add, values, /EXTRACT
	ENDIF 
END

;+
; Prints the fields of the variable
;			<br /> Use the IDL 'print' command 
;			and pass in the object to invoke this method
;-
FUNCTION NCDFVAR::_overloadPrint
	print,  '****************************'
	if strlen(self.name) GT 0 then begin
		print, 'Variable: ', self.name 
	endif else print, 'Variable name has not been set'

	if self.n_dimensions() GT 0 then begin
		print, 'Dimensions: ','['+strjoin((self.dimensions).ToArray(),',')+']'
	endif
	
	if ptr_valid(self.data) then begin
		print, 'Number of data: ', strtrim(n_elements(*self.data),2) 
	endif else print, 'Variable data has not been set'
	
	if self.n_atts() GT 0 then begin
		print, 'Attributes:'
		;foreach value, self.attributes, name do print, ' ', name, ' = ', strtrim(value[0],2)
		foreach value, self.attributes, name do print, ' ', name, ' = ', strtrim(value,2)
	endif
	return, ''
END


;+
; @hidden
;-
PRO NCDFVAR::cleanup
	if ptr_valid(self.data) then ptr_free, self.data
END


;+
; @hidden
; The structure definition for the class
;			
; @field NAME 
;			Name of the variable
;			
; @field ATTRIBUTES 
;			Hash of attributes of the variable
;			
; @field DATA
;			Array of data of the variable
;-
PRO NCDFVAR__define
	struct= {	NCDFVAR, $
				INHERITS IDL_Object, $
				name: '', $
				attributes: hash(), $
				data: ptr_new(), $
				dimensions: list() $
			}
END
