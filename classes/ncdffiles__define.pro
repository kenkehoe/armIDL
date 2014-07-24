
;+
; Data structure to hold the netCDF filenames and location 
;			
; @Author Tri Noensie
; @history September 2010
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
FUNCTION NCDFFILES::init, FILES = files, PATH = path, DATE_START = date_start, DATE_END = date_end
	self.files = list()
	if keyword_set(files) then self.setFiles, files
	if keyword_set(path) then self.path = path
	if keyword_set(date_start) then self.date_start = date_start
	if keyword_set(date_end) then self.date_end = date_end
	return, 1B
END


;+
; Set array of netCDF filenames
;			<br /> If an array is already set, then it will be
;			cleared first before inserting the new array
;
; @param FILES {in} {required} {type= string array}
;-
PRO NCDFFILES::setFiles, files
	if self.n_files() GT 0 then (self.files).remove,/ALL
	(self.files).Add, files, /EXTRACT
END


;+
; Adds a single netCDF filename at specific index or at the end of the array
;			
; @param FILE {in} {required} {type= string}
;			Filename
;			
; @param INDEX {in} {optional} {type= integer}
;			Inserts the file at the specified index
;-
PRO NCDFFILES::addFile, file, index
	if (n_params() EQ 2) then begin
		if (index GE 0) AND (index LE self.n_files()-1) then begin
			(self.files).Add, file, index
		endif
	endif else (self.files).Add, file
END


;+
; Removes a netCDF filename at a particular index
;			
; @param INDEX {in} {required} {type= integer}
;			The index in array of netCDF filenames
;-
PRO NCDFFILES::removeFile, index
	if (index GE 0) AND (index LE self.n_files()-1) then begin
		(self.files).Remove, index
	endif
END


;+
; Set the path to the netCDF files
;			
; @param PATH {in} {required} {type= string}
;-
PRO NCDFFILES::setPath, path
	self.path = path
END


;+
; Set Date Start
;			
; @param DATE {in} {required} {type= string/integer}
;-
PRO NCDFFILES::setDateStart, date
	self.date_start = date
END

;+
; Set Date End
;			
; @param DATE {in} {required} {type= string/integer}
;-
PRO NCDFFILES::setDateEnd, date
	self.date_end = date
END


;+
; Returns list of netCDF filenames
;			
; @returns Return type: string Array
;-
FUNCTION NCDFFILES::getFileList
	return, (self.files).toArray()
END


;+
; Returns a single netCDF filename
;			
; @param INDEX {in} {required} {type= integer}
;			Valid numbers: 0 - (array size-1)
;			
; @returns Return type: string
;			<br /> Returns NULL, if an error occurs at retrieving data.
;-
FUNCTION NCDFFILES::getFile, index
	if (index GE 0) AND (index LE self.n_files()-1) then begin
		return, (self.files)[index]
	endif else return, !NULL
END


;+
; Returns the path to the netCDF files
;
; @returns Return type: string
;-
FUNCTION NCDFFILES::getPath
	return, self.path
END


;+
; Returns the date of the first netCDF file
;
; @returns Return type: string
;-
FUNCTION NCDFFILES::getDateStart
	return, self.date_start
END


;+
; Returns the date of the last netCDF file
; 
; @returns Return type: string
;-
FUNCTION NCDFFILES::getDateEnd
	return, self.date_end
END


;+
; Returns the number of netCDF files
;			
; @returns Return type: integer
;-
FUNCTION NCDFFILES::n_files
	return, n_elements(self.files)
END


;+
; Displays all the fields in NCDFFILES object
;			<br /> Use the IDL 'print' command 
;			and pass in the object to invoke this method
;-
FUNCTION NCDFFILES::_overloadPrint
	print, 'Number of files: ', self.n_files()
	
	if (strlen(self.path) gt 0) then begin
		print, 'Path: ', self.path 
	endif else print, 'The path is not set'
	
	if (strlen(self.date_start) gt 0) then begin
		print, 'Start Date: ', self.date_start 
	endif else print, 'Start date is not set'

	if (strlen(self.date_end) gt 0) then begin
		print, 'End Date: ', self.date_end
	endif else print, 'End date is not set'
	return, ''
END


;+
; @hidden
; The structure definition for the class 
;			
; @field FILES
;			A list of netCDF filenames
;			
; @field DATE_START
;			The date of the first netCDF file
;			
; @field DATE_END
;			The Date of the last netCDF file
;			
; @field PATH
;			The path to the netCDF files
;-
PRO NCDFFILES__define
	struct= {	NCDFFILES, $
				INHERITS IDL_Object, $
				files: list(), $
				date_start: '', $
				date_end: '', $
				path: '' $
			}
END