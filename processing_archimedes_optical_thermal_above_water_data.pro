; NAME:
;   Processing_Archimedes_Optical_Thermal_Above_Water_Data.pro
;
; PURPOSE:
;   IDL code to process optical data collected collected on the Archimedes yacht, from Level 2 to Level 3
;
; CATEGORY:
;   Optical data processing
;
; CALLING SEQUENCE:
;   Processing_Archimedes_Optical_Thermal_Above_Water_Data
;
; INPUTS:
;   Level 2 optical and thermal data (outputted from SatCON software), and path to data
;
; OUTPUTS:
;   Level 3 optical and thermal data
;
; MODIFICATION HISTORY:
; Bob Brewin 02/10/2019
; Bob Brewin 13/12/2019
; Bob Brewin 13/02/2020
; Bob Brewin 20/02/2020
; Bob Brewin 30/04/2020
; Bob Brewin 20/06/2020
; Bob Brewin 28/09/2020

pro Processing_Archimedes_Optical_Thermal_Above_Water_Data

;;;Define File path where Level 2 data is stored (output from SatCON)
   file_data_path_input   = '/Volumes/BOB_EXT_HD/Archimedes/Archimedes/Level_2/'
   file_data_path_outputa = '/Volumes/BOB_EXT_HD/Archimedes/Archimedes/Level_3/'
   ;;;Find the files   
      P_2018 = FIND_ALL_DIR(file_data_path_input+'2018')
      P_2018 = P_2018(1:n_elements(P_2018)-1)
      P_2019 = FIND_ALL_DIR(file_data_path_input+'2019')
      P_2019 = P_2019(1:n_elements(P_2019)-1)
      P_2020 = FIND_ALL_DIR(file_data_path_input+'2020')
      P_2020 = P_2020(1:n_elements(P_2020)-1)
      Year_link  = STRMID([P_2018,P_2019,P_2020], 50, 4)
      Day_link   = STRMID([P_2018,P_2019,P_2020], 56, 3) 
      Day_link  = Day_link(251:n_elements(Day_link)-1)
      Year_link = Year_link(251:n_elements(Year_link)-1)

;;;Loop through days
for ilq = 0, n_elements(Day_link)-1 do begin 

  file_data_path        = file_data_path_input+Year_link(ilq)+'/'+Day_link(ilq)+'/'
  file_data_path_output = file_data_path_outputa+Year_link(ilq)+'/'+Day_link(ilq)+'/'
  
;;;Search filepath for filenames
  Filenames = FILE_SEARCH(''+file_data_path+'*.dat')
  
;;;Extract the YEAR, SDY and TIME (HHMMSS) from all the filenames NB THIS NEEDS TO BE ADJUSTED TO EXTRACT FILENAME FROM PATH
  Path_Length = STRLEN(file_data_path)               ;;;Finds length of the string
  Year_FILE   = STRMID(Filenames,Path_Length,2)      ;;;Extracts Year from filename
  SDY_FILE    = STRMID(Filenames,Path_Length+2,3)    ;;;Extracts day of year (SDY) from filename
  TIME_FILE_H = STRMID(Filenames,Path_Length+5,2)    ;;;Extracts Hour of Day (GMT)
  TIME_FILE_1 = float(TIME_FILE_H)                   ;;;Converts Hour to float
  SDY_FILE_1  = float(SDY_FILE)                      ;;;Converts SDY to float
  SDY_STRING  = SDY_FILE(0)                          ;;;Extracts day of year (SDY) (singal number for the day)
  
;;;Compute the number of files in each of the hour bins. There should be 9 (6 optical, 1 thermal, 1 location, 1 navigation)
   ;;;Re-bin YEAR, SDY and TIME to only 1 of the 6 required
   TIME_FILE_2   = fltarr(n_elements(Year_FILE))
   INDEX_NUM_T   = fltarr(n_elements(Year_FILE)) 
   TIMEFILE_TEST = long(''+SDY_FILE+''+TIME_FILE_H+'')
   cnt = 0
   for id = 0l, n_elements(Year_FILE)-1 do begin
   ;;;Determine how many files have the same time
     as = where(TIMEFILE_TEST eq TIMEFILE_TEST(id), cnti)
     INDEX_NUM_T(id) = cnti  
     if cnt eq 0 then begin
       TIME_FILE_2(id) = TIME_FILE_1(id)
     endif
     if cnt eq 1 then begin
       if abs(TIME_FILE_1(id) - TIME_FILE_1(id-1)) lt 0.0001 then TIME_FILE_2(id) = -999.
       if abs(TIME_FILE_1(id) - TIME_FILE_1(id-1)) gt 0.0001 then TIME_FILE_2(id) = TIME_FILE_1(id)
     endif
     cnt = 1
   endfor

;;;Remove files where the number of files is less than 9 (i.e. missing 1 or more of the 6 optical, 1 thermal, 1 location, 1 navigation files)
   index        = where(INDEX_NUM_T eq 9.0)
   Year_FILE    = Year_FILE(index)
   SDY_FILE     = SDY_FILE(index)
   SDY_FILE_1   = SDY_FILE_1(index)
   TIME_FILE_H  = TIME_FILE_H(index)
   TIME_FILE_2  = TIME_FILE_2(index)
   
;;;Extract only the information for a single file per hour 
   index         = where(TIME_FILE_2 ne -999.)
   Year_FILE_SDY = Year_FILE(index)
   SDY_FILE_SDY  = SDY_FILE(index)
   TIME_FILE_SDY = TIME_FILE_H(index)
      
 ;;;Create matrix to put all RRS data for each day into (141 wavelegnths 3.5 nm + compass, pitch, roll and the time  hence 145), then arbitary 100000 to shove data into)
      XXX_Length = 239                                    ;;;This number is based on the number of wavelengths in the data (see SatCON file) plus additional variables recorded. 
      YYY_Length = 100000                                   ;;;This number is arbitary but need to be more than the maximium data collected in a day
      MATRIX_RRS = fltarr([XXX_Length,YYY_Length]) -999.   ;;;;Call -999 as missing bins  
      MATRIX_LT  = fltarr([XXX_Length,YYY_Length]) -999.   ;;;;Call -999 as missing bins  
      MATRIX_LI  = fltarr([XXX_Length,YYY_Length]) -999.   ;;;;Call -999 as missing bins  
      MATRIX_ES  = fltarr([XXX_Length,YYY_Length]) -999.   ;;;;Call -999 as missing bins  
      count1     = 0.                                      ;;;This is an index to appropriately bin the Rrs data into

   ;;;PROCESS HYPERSAS
      ;;(1) LOOP THROUGH ALL FILES
      for id = 0l, n_elements(Year_FILE_SDY)-1 do begin
         ;;;DARKCOUNTS FILENAME
            filename_HED0622a        = ''+file_data_path+''+Year_FILE_SDY(id)+''+SDY_FILE_SDY(id)+''+TIME_FILE_SDY(id)+'-HED0622a.dat'       ;;;DARKCOUNTS ES
            filename_HLD0457a        = ''+file_data_path+''+Year_FILE_SDY(id)+''+SDY_FILE_SDY(id)+''+TIME_FILE_SDY(id)+'-HLD0457a.dat'       ;;;DARKCOUNTS LI
            filename_HLD0455a        = ''+file_data_path+''+Year_FILE_SDY(id)+''+SDY_FILE_SDY(id)+''+TIME_FILE_SDY(id)+'-HLD0455a.dat'       ;;;DARKCOUNTS LT
         ;;;RAW DATA  FILENAME
            filename_HSE0622a        = ''+file_data_path+''+Year_FILE_SDY(id)+''+SDY_FILE_SDY(id)+''+TIME_FILE_SDY(id)+'-HSE0622a.dat'       ;;;ES
            filename_HSL0457a        = ''+file_data_path+''+Year_FILE_SDY(id)+''+SDY_FILE_SDY(id)+''+TIME_FILE_SDY(id)+'-HSL0457a.dat'       ;;;LI
            filename_HSL0455a        = ''+file_data_path+''+Year_FILE_SDY(id)+''+SDY_FILE_SDY(id)+''+TIME_FILE_SDY(id)+'-HSL0455a.dat'       ;;;LT
            filename_SATNAV0008A     = ''+file_data_path+''+Year_FILE_SDY(id)+''+SDY_FILE_SDY(id)+''+TIME_FILE_SDY(id)+'-SATNAV0008A.dat'    ;;;MOTION.NAV    
            filename_GPRMC_WithMode  = ''+file_data_path+''+Year_FILE_SDY(id)+''+SDY_FILE_SDY(id)+''+TIME_FILE_SDY(id)+'-GPRMC_WithMode.dat' ;;;LOCATION  
            filename_Pyrometer       = ''+file_data_path+''+Year_FILE_SDY(id)+''+SDY_FILE_SDY(id)+''+TIME_FILE_SDY(id)+'-Pyrometer.dat'      ;;;Thermal (SST0 

         ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;ES-START;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;   
         ;;;ES DARK COUNT
            ;;;Check if there is any dark count data (greater than 5 rows) if not there is no ES data available
            ES_DARK_rows = File_Lines(filename_HED0622a)
            if ES_DARK_rows gt 5 then begin
              ;;;Extract Header information
              OPENR, lun, filename_HED0622a, /GET_LUN
              header = STRARR(5)
              
              READF,lun,header
              ;;;Get wavelengths from Header
              header_WAV = STRSPLIT(header(3),'' + STRING(9B) + '',  /EXTRACT, /PRESERVE_NULL)
              Wavelengths_HED258D = fltarr(n_elements(header_WAV))
              for ia = 0, n_elements(header_WAV)-1 do begin
                if ia gt 3 and ia lt 153 then begin
                  Wavelengths_HED258D(ia) = float(STRMID(header_WAV(ia), 3,6))
                endif else begin
                  Wavelengths_HED258D(ia) = -999
                endelse
              endfor
              FREE_LUN, lun
              WAVE_HED258D = Wavelengths_HED258D
              ;;GET DATA DARKS
              DATA_HED258D         = READ_ASCII(filename_HED0622a, DATA_START=5, DELIMITER=' ')
              Wavelengths_HED258D  = Wavelengths_HED258D(4:144)
              ES_DARK              = DATA_HED258D.field001(4:144,*)
              ;;;Get time from file
              OPENR, lun, filename_HED0622a, /GET_LUN
              header = STRARR(5)
              READF,lun,header
              colm = 1
              rows = n_elements(ES_DARK(0,*))
              ST_data = STRARR([colm, rows])
              READF, lun, ST_data
              free_lun, lun
              ST_data    = REFORM(ST_data, N_ELEMENTS(ST_data))
              ;;ASSIGN VARIABLES WANTED FROM NOMAD IN STRING FORMAT
              TIME_FILE  = STRARR(rows)
              ;;READ VARIABLES INTO STRING FORMAT (NOTE THAT THE NUMBER REPRESENTS THE ROW NUMBER IN THE FILE)
              for ii = 0, rows-1 do begin
                S = STRSPLIT(ST_data(ii),'' + STRING(9B) + '',  /EXTRACT, /PRESERVE_NULL)
                TIME_FILE(ii)           = S(178)
              endfor
              HH_FILE = float(STRMID(TIME_FILE, 0,2))
              MM_FILE = float(STRMID(TIME_FILE, 3,2))
              SS_FILE = float(STRMID(TIME_FILE, 6,5))
              ;;;CONVERT TIME TO DECIMAL HOUR
              TIME_FILE_DEC = HH_FILE + (((SS_FILE/60.)+ MM_FILE)/60.)
              ;;;COMPLETE DARKCOUNTS ES
              TIME_HED258D = TIME_FILE_DEC
              DATA_HED258D = ES_DARK
              WAVE_HED258D = Wavelengths_HED258D
              ;;;ES DATA;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              ES_rows = File_Lines(filename_HSE0622a)
              if ES_rows gt 5 then begin
              OPENR, lun, filename_HSE0622a, /GET_LUN
              header = STRARR(5)
              READF,lun,header
              ;;;Get wavelengths from Header
              header_WAV = STRSPLIT(header(3),'' + STRING(9B) + '',  /EXTRACT, /PRESERVE_NULL)
              Wavelengths_HSE258D = fltarr(n_elements(header_WAV))
              for ia = 0, n_elements(header_WAV)-1 do begin
                if ia gt 3 and ia lt 153 then begin
                  Wavelengths_HSE258D(ia) = float(STRMID(header_WAV(ia), 3,6))
               endif else begin
                  Wavelengths_HSE258D(ia) = -999
                endelse
              endfor
              FREE_LUN, lun 
              ;;;Get data from file
              DATA_HSE258D         = READ_ASCII(filename_HSE0622a, DATA_START=5, DELIMITER='' + STRING(9B) + '')
              Wavelengths_HSE258D  = Wavelengths_HSE258D(4:144)
              ES_RAW               = DATA_HSE258D.field001(4:144,*)
              ;;;Get time from file
              OPENR, lun, filename_HSE0622a, /GET_LUN
              header = STRARR(5)
              READF,lun,header
              colm = 1
              rows = n_elements(ES_RAW(0,*))
              ST_data = STRARR([colm, rows])
              READF, lun, ST_data
              free_lun, lun
              ST_data    = REFORM(ST_data, N_ELEMENTS(ST_data))
              ;;ASSIGN VARIABLES WANTED FROM NOMAD IN STRING FORMAT
              TIME_FILE  = STRARR(rows)
              ;;READ VARIABLES INTO STRING FORMAT (NOTE THAT THE NUMBER REPRESENTS THE ROW NUMBER IN THE FILE)
              for ii = 0, rows-1 do begin
                S = STRSPLIT(ST_data(ii),'' + STRING(9B) + '',  /EXTRACT, /PRESERVE_NULL)
                TIME_FILE(ii)           = S(178)
              endfor
              HH_FILE = float(STRMID(TIME_FILE, 0,2))
              MM_FILE = float(STRMID(TIME_FILE, 3,2))
              SS_FILE = float(STRMID(TIME_FILE, 6,5))
              ;;;CONVERT TIME TO DECIMAL HOUR
              TIME_FILE_DEC = HH_FILE + (((SS_FILE/60.)+ MM_FILE)/60.)
              ;;;COMPLETE DARKCOUNTS ES
              TIME_HSE258D = TIME_FILE_DEC
              DATA_HSE258D = ES_RAW
              WAVE_HSE258D = Wavelengths_HSE258D
              ;;;SUBTRACT DARKCOUNTS FROM ES DATA
              ;;;Create an ES-darkcount matrix the same as ES-raw matrix, interpolated to the same time
              ;;;IF ONLY 1 dark count then
              num_dark_count = n_elements(DATA_HED258D(0,*))
              ;;;Create an LI-darkcount matrix the same as LI-raw matrix, interpolated to the same time
              DATA_HED258D_INTERPOL = fltarr([n_elements(DATA_HSE258D(*,0)),n_elements(DATA_HSE258D(0,*))])
              if num_dark_count gt 1 then begin
                for ib = 0, n_elements(DATA_HSE258D(*,0))-1 do begin
                  DATA_HED258D_INTERPOL(ib,*) =  INTERPOL(DATA_HED258D(ib,*),TIME_HED258D,TIME_HSE258D)
                endfor
              endif else begin
                for ib = 0, n_elements(DATA_HSE258D(*,0))-1 do begin
                  DATA_HED258D_INTERPOL(ib,*) =  DATA_HED258D(ib)
                endfor
              endelse
              ;;;Subtract the ES-darkcount matrix from the ES-raw matrix
              DATA_ES = DATA_HSE258D - DATA_HED258D_INTERPOL
              ;;;COMPLETE
              DATA_ES = DATA_ES
              TIME_ES = TIME_HSE258D
              WAVE_ES = WAVE_HSE258D
            endif
            endif else begin
              DATA_ES = -999.
              TIME_ES = -999.
              WAVE_ES = -999.
            endelse
            
         ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;ES-FINISH;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;      
         
         ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;LI-START;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
         ;;;;Check if there is any dark count data (greater than 5 rows) if not there is no ES data available
         LI_DARK_rows = File_Lines(filename_HLD0457a)
         if LI_DARK_rows gt 5 then begin    
         ;;;DARKCOUNTS LI
            OPENR, lun, filename_HLD0457a, /GET_LUN
            header = STRARR(5)
            READF,lun,header
            ;;;Get wavelengths from Header
            header_WAV = STRSPLIT(header(3),'' + STRING(9B) + '',  /EXTRACT, /PRESERVE_NULL)
            Wavelengths_HLD222D = fltarr(n_elements(header_WAV))
            for ia = 0, n_elements(header_WAV)-1 do begin
              if ia gt 3 and ia lt 141 then begin
                Wavelengths_HLD222D(ia) = float(STRMID(header_WAV(ia), 3,6))
              endif else begin
                Wavelengths_HLD222D(ia) = -999
              endelse
            endfor      
            FREE_LUN, lun
            ;;;Get data from file
            DATA_HLD222D         = READ_ASCII(filename_HLD0457a, DATA_START=5, DELIMITER='' + STRING(9B) + '')
            Wavelengths_HLD222D  = Wavelengths_HLD222D(4:140)
            LI_DARK              = DATA_HLD222D.field001(4:140,*)
            ;;;Get time from file
            OPENR, lun, filename_HLD0457a, /GET_LUN
            header = STRARR(5)
            READF,lun,header
            colm = 1
            rows = n_elements(LI_DARK(0,*))
            ST_data = STRARR([colm, rows])
            READF, lun, ST_data
            free_lun, lun
            ST_data    = REFORM(ST_data, N_ELEMENTS(ST_data))
            ;;ASSIGN VARIABLES WANTED FROM NOMAD IN STRING FORMAT
            TIME_FILE  = STRARR(rows)
            ;;READ VARIABLES INTO STRING FORMAT (NOTE THAT THE NUMBER REPRESENTS THE ROW NUMBER IN THE FILE)
            for ii = 0, rows-1 do begin
              S = STRSPLIT(ST_data(ii),'' + STRING(9B) + '',  /EXTRACT, /PRESERVE_NULL)
              TIME_FILE(ii) = S(148)
            endfor
            HH_FILE = float(STRMID(TIME_FILE, 0,2))
            MM_FILE = float(STRMID(TIME_FILE, 3,2))
            SS_FILE = float(STRMID(TIME_FILE, 6,5))
            ;;;CONVERT TIME TO DECIMAL HOUR
            TIME_FILE_DEC = HH_FILE + (((SS_FILE/60.)+ MM_FILE)/60.)
            ;;;COMPLETE DARKCOUNTS ES
            TIME_HLD222D = TIME_FILE_DEC
            DATA_HLD222D = LI_DARK
            WAVE_HLD222D = Wavelengths_HLD222D
         ;;;LI DATA
            LI_rows = File_Lines(filename_HSL0457a)
            if LI_rows gt 5 then begin
            OPENR, lun, filename_HSL0457a, /GET_LUN
            header = STRARR(5)
            READF,lun,header
            ;;;Get wavelengths from Header
            header_WAV = STRSPLIT(header(3),'' + STRING(9B) + '',  /EXTRACT, /PRESERVE_NULL)
            Wavelengths_HSL222D = fltarr(n_elements(header_WAV))
            for ia = 0, n_elements(header_WAV)-1 do begin
              if ia gt 3 and ia lt 141 then begin
                Wavelengths_HSL222D(ia) = float(STRMID(header_WAV(ia), 3,6))
              endif else begin
                Wavelengths_HSL222D(ia) = -999
              endelse
            endfor
            FREE_LUN, lun
            ;;;Get data from file
            DATA_HSL222D         = READ_ASCII(filename_HSL0457a, DATA_START=5, DELIMITER='' + STRING(9B) + '')
            Wavelengths_HSL222D  = Wavelengths_HSL222D(4:140)
            LI_RAW               = DATA_HSL222D.field001(4:140,*)
            ;;;Get time from file
            OPENR, lun, filename_HSL0457a, /GET_LUN
            header = STRARR(5)
            READF,lun,header
            colm = 1
            rows = n_elements(LI_RAW(0,*))
            ST_data = STRARR([colm, rows])
            READF, lun, ST_data
            free_lun, lun
            ST_data    = REFORM(ST_data, N_ELEMENTS(ST_data))
            ;;ASSIGN VARIABLES WANTED FROM NOMAD IN STRING FORMAT
            TIME_FILE  = STRARR(rows)
            ;;READ VARIABLES INTO STRING FORMAT (NOTE THAT THE NUMBER REPRESENTS THE ROW NUMBER IN THE FILE)
            for ii = 0, rows-1 do begin
              S = STRSPLIT(ST_data(ii),'' + STRING(9B) + '',  /EXTRACT, /PRESERVE_NULL)
              TIME_FILE(ii)           = S(148)
            endfor
            HH_FILE = float(STRMID(TIME_FILE, 0,2))
            MM_FILE = float(STRMID(TIME_FILE, 3,2))
            SS_FILE = float(STRMID(TIME_FILE, 6,5))
            ;;;CONVERT TIME TO DECIMAL HOUR
            TIME_FILE_DEC = HH_FILE + (((SS_FILE/60.)+ MM_FILE)/60.)
            ;;;COMPLETE DARKCOUNTS ES
            TIME_HSL222D = TIME_FILE_DEC
            DATA_HSL222D = LI_RAW
            WAVE_HSL222D = Wavelengths_HSL222D      
         ;;;SUBTRACT DARKCOUNTS FROM LI DATA 
            ;;;IF ONLY 1 dark count then
            num_dark_count = n_elements(DATA_HLD222D(0,*))
            ;;;Create an LI-darkcount matrix the same as LI-raw matrix, interpolated to the same time
            DATA_HLD222D_INTERPOL = fltarr([n_elements(DATA_HSL222D(*,0)),n_elements(DATA_HSL222D(0,*))])
            if num_dark_count gt 1 then begin
               for ib = 0, n_elements(DATA_HSL222D(*,0))-1 do begin
                  DATA_HLD222D_INTERPOL(ib,*) =  INTERPOL(DATA_HLD222D(ib,*),TIME_HLD222D,TIME_HSL222D)
               endfor
            endif else begin
               for ib = 0, n_elements(DATA_HSL222D(*,0))-1 do begin
                  DATA_HLD222D_INTERPOL(ib,*) =  DATA_HLD222D(ib)
               endfor
            endelse
            ;;;Subtract the LI-darkcount matrix from the LI-raw matrix
            DATA_LI = DATA_HSL222D - DATA_HLD222D_INTERPOL
            ;;;COMPLETE
            DATA_LI = DATA_LI
            TIME_LI = TIME_HSL222D
            WAVE_LI = WAVE_HSL222D
            endif
         endif else begin
            DATA_LI = -999
            TIME_LI = -999
            WAVE_LI = -999
         endelse

         ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;LI-FINISH;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;      

         ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;LT-START;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;      
         ;;;DARKCOUNTS LT
         ;;;;Check if there is any dark count data (greater than 5 rows) if not there is no ES data available
         LT_DARK_rows = File_Lines(filename_HLD0455a)
         if LT_DARK_rows gt 5 then begin
            OPENR, lun, filename_HLD0455a, /GET_LUN
            header = STRARR(5)
            READF,lun,header
            ;;;Get wavelengths from Header
            header_WAV = STRSPLIT(header(3),'' + STRING(9B) + '',  /EXTRACT, /PRESERVE_NULL)
            Wavelengths_HLD223D = fltarr(n_elements(header_WAV))
            for ia = 0, n_elements(header_WAV)-1 do begin
              if ia gt 3 and ia lt 141 then begin
                Wavelengths_HLD223D(ia) = float(STRMID(header_WAV(ia), 3,6))
              endif else begin
                Wavelengths_HLD223D(ia) = -999
              endelse
            endfor
            FREE_LUN, lun
            ;;;Get data from file
             DATA_HLD223D         = READ_ASCII(filename_HLD0455a, DATA_START=5, DELTMITER='' + STRING(9B) + '')
            Wavelengths_HLD223D  = Wavelengths_HLD223D(4:140)
            LT_DARK              = DATA_HLD223D.field001(4:140,*)
            ;;;Get time from file
            OPENR, lun, filename_HLD0455a, /GET_LUN
            header = STRARR(5)
            READF,lun,header
            colm = 1
            rows = n_elements(LT_DARK(0,*))
            ST_data = STRARR([colm, rows])
            READF, lun, ST_data
            free_lun, lun
            ST_data    = REFORM(ST_data, N_ELEMENTS(ST_data))
            ;;ASSIGN VARIABLES WANTED FROM NOMAD IN STRING FORMAT
            TIME_FILE  = STRARR(rows)
            ;;READ VARIABLES INTO STRING FORMAT (NOTE THAT THE NUMBER REPRESENTS THE ROW NUMBER IN THE FILE)
            for ii = 0, rows-1 do begin
              S = STRSPLIT(ST_data(ii),'' + STRING(9B) + '',  /EXTRACT, /PRESERVE_NULL)
              TIME_FILE(ii) = S(148)
            endfor
            HH_FILE = float(STRMID(TIME_FILE, 0,2))
            MM_FILE = float(STRMID(TIME_FILE, 3,2))
            SS_FILE = float(STRMID(TIME_FILE, 6,5))
            ;;;CONVERT TIME TO DECIMAL HOUR
            TIME_FILE_DEC = HH_FILE + (((SS_FILE/60.)+ MM_FILE)/60.)
            ;;;COMPLETE DARKCOUNTS ES
            TIME_HLD223D = TIME_FILE_DEC
            DATA_HLD223D = LT_DARK
            WAVE_HLD223D = Wavelengths_HLD223D
         ;;;LT DATA
            LT_rows = File_Lines(filename_HSL0455a)
            if LT_rows gt 5 then begin
            OPENR, lun, filename_HSL0455a, /GET_LUN
            header = STRARR(5)
            READF,lun,header
            ;;;Get wavelengths from Header
            header_WAV = STRSPLIT(header(3),'' + STRING(9B) + '',  /EXTRACT)
            Wavelengths_HSL223D = fltarr(n_elements(header_WAV))
            for ia = 0, n_elements(header_WAV)-1 do begin
              if ia gt 3 and ia lt 141 then begin
                Wavelengths_HSL223D(ia) = float(STRMID(header_WAV(ia), 3,6))
              endif else begin
                Wavelengths_HSL223D(ia) = -999
              endelse
            endfor
            FREE_LUN, lun
            ;;;Get data from file
            DATA_HSL223D         = READ_ASCII(filename_HSL0455a, DATA_START=5, DELTMITER='' + STRING(9B) + '')      
            Wavelengths_HSL223D  = Wavelengths_HSL223D(4:140)
            LT_RAW               = DATA_HSL223D.field001(4:140,*)
            ;;;Get time from file
            OPENR, lun, filename_HSL0455a, /GET_LUN
            header = STRARR(5)
            READF,lun,header
            colm = 1
            rows = n_elements(LT_RAW(0,*))
            ST_data = STRARR([colm, rows])
            READF, lun, ST_data
            free_lun, lun
            ST_data    = REFORM(ST_data, N_ELEMENTS(ST_data))
            ;;ASSIGN VARIABLES WANTED FROM NOMAD IN STRING FORMAT
            TIME_FILE  = STRARR(rows)
            ;;READ VARIABLES INTO STRING FORMAT (NOTE THAT THE NUMBER REPRESENTS THE ROW NUMBER IN THE FILE)
            for ii = 0, rows-1 do begin
              S = STRSPLIT(ST_data(ii),'' + STRING(9B) + '',  /EXTRACT, /PRESERVE_NULL)
              TIME_FILE(ii)           = S(148)
            endfor
            HH_FILE = float(STRMID(TIME_FILE, 0,2))
            MM_FILE = float(STRMID(TIME_FILE, 3,2))
            SS_FILE = float(STRMID(TIME_FILE, 6,5))
            ;;;CONVERT TIME TO DECIMAL HOUR
            TIME_FILE_DEC = HH_FILE + (((SS_FILE/60.)+ MM_FILE)/60.)
            ;;;COMPLETE DARKCOUNTS ES
            TIME_HSL223D = TIME_FILE_DEC
            DATA_HSL223D = LT_RAW
            WAVE_HSL223D = Wavelengths_HSL223D      
         ;;;SUBTRACT DARKCOUNTS FROM LT DATA 
            ;;;Create an LT-darkcount matrix the same as LT-raw matrix, interpolated to the same time     
            ;;;IF ONLY 1 dark count then
            num_dark_count = n_elements(DATA_HLD223D(0,*))
            ;;;Create an LI-darkcount matrix the same as LI-raw matrix, interpolated to the same time
            DATA_HLD223D_INTERPOL = fltarr([n_elements(DATA_HSL223D(*,0)),n_elements(DATA_HSL223D(0,*))])      
            if num_dark_count gt 1 then begin
               for ib = 0, n_elements(DATA_HSL223D(*,0))-1 do begin
                  DATA_HLD223D_INTERPOL(ib,*) =  INTERPOL(DATA_HLD223D(ib,*),TIME_HLD223D,TIME_HSL223D)
               endfor
            endif else begin
                for ib = 0, n_elements(DATA_HSL223D(*,0))-1 do begin
                  DATA_HLD223D_INTERPOL(ib,*) =  DATA_HLD223D(ib)
               endfor
            endelse
            ;;;Subtract the LT-darkcount matrix from the LT-raw matrix
            DATA_LT = DATA_HSL223D - DATA_HLD223D_INTERPOL
            ;;;COMPLETE
            DATA_LT = DATA_LT
            TIME_LT = TIME_HSL223D
            WAVE_LT = WAVE_HSL223D
            endif
          endif else begin
            DATA_LT = -999
            TIME_LT = -999
            WAVE_LT = -999
          endelse
         ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;LI-FINISH;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;      

         ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;THS-START;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;      
            SAT_rows = File_Lines(filename_SATNAV0008A) - 5.
            if SAT_rows gt 0 then begin
              OPENR, lun, filename_SATNAV0008A, /GET_LUN
              header = STRARR(5)
              READF,lun,header
              ;;;Get wavelengths from Header
              header_WAV = STRSPLIT(header(3),'' + STRING(9B) + '',  /EXTRACT)
              free_lun, lun
              ;;;Get data from file
              DATA_SATTHS0035 = READ_ASCII(filename_SATNAV0008A, MISSING_VALUE= !Values.F_NAN, DATA_START=5, DELTMITER=STRING(9B))
              ;;;Get time from file
              OPENR, lun, filename_SATNAV0008A, /GET_LUN
              header = STRARR(5)
              READF,lun,header
              colm = 1
              rows = File_Lines(filename_SATNAV0008A)-5  ;;-5 for header)
              ST_data = STRARR([colm, rows])
              READF, lun, ST_data
              free_lun, lun
              ST_data    = REFORM(ST_data, N_ELEMENTS(ST_data))
              ;;ASSIGN VARIABLES WANTED FROM NOMAD IN STRING FORMAT
              TIME_FILE  = STRARR(rows)
              INDEX           = STRARR(rows)
              HEADING_M       = STRARR(rows)
              PITCH           = STRARR(rows)
              ROLL            = STRARR(rows)
              HEADING         = STRARR(rows)
              AZIMUTH_        = STRARR(rows)
              ELEVATION       = STRARR(rows)
              POINTING        = STRARR(rows)
              HUMIDITY        = STRARR(rows)
              VOLT            = STRARR(rows)
              TEMP_INT        = STRARR(rows)
              ISO8601_INT     = STRARR(rows)
              FW_             = STRARR(rows)
              DATETAG         = STRARR(rows)
              TIMETAG2        = STRARR(rows)
              ;;READ VARIABLES INTO STRING FORMAT (NOTE THAT THE NUMBER REPRESENTS THE ROW NUMBER IN THE FILE)
              for ii = 0, rows-1 do begin
                S = STRSPLIT(ST_data(ii), '' + STRING(9B) + '', /EXTRACT, /PRESERVE_NULL)
                INDEX(ii)           = S(0)
                HEADING_M(ii)       = S(1)
                PITCH(ii)           = S(2)
                ROLL(ii)            = S(3)
                HEADING(ii)         = S(4)
                AZIMUTH_(ii)        = S(5)
                ELEVATION(ii)       = S(6)
                POINTING(ii)        = S(7)
                HUMIDITY(ii)        = S(8)
                VOLT(ii)            = S(9)
                TEMP_INT(ii)        = S(10)
                ISO8601_INT(ii)     = S(11)
                FW_(ii)             = S(12)
                DATETAG(ii)         = S(13)
                TIMETAG2(ii)        = S(14)
              endfor
              HEADING         = float(HEADING)
              AZIMUTH_        = float(AZIMUTH_)
              ELEVATION       = float(ELEVATION)
              POINTING        = float(POINTING)
              HUMIDITY        = float(HUMIDITY)
              VOLT            = float(VOLT)
              TEMP_INT        = float(TEMP_INT)
              ANGLE_SENSOR_AZ = abs((HEADING+POINTING)-AZIMUTH_)
              TIME_FILE = TIMETAG2
              HH_FILE = float(STRMID(TIME_FILE, 0,2))      
              MM_FILE = float(STRMID(TIME_FILE, 3,2))
              SS_FILE = float(STRMID(TIME_FILE, 6,5))
              ;;;CONVERT TIME TO DECIMAL HOUR
              TIME_FILE_DEC = HH_FILE + (((SS_FILE/60.)+ MM_FILE)/60.)
              TIME_THS    = TIME_FILE_DEC
            endif else begin
                HEADING         = -999
                AZIMUTH_        = -999
                ELEVATION       = -999
                POINTING        = -999
                HUMIDITY        = -999
                VOLT            = -999
                TEMP_INT        = -999
                ANGLE_SENSOR_AZ = -999
                TIME_FILE_DEC   = -999
                TIME_THS        = -999
            endelse
         ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;THS-FINISH;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;     

         ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;GPS-START;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
         GPS_rows = File_Lines(filename_GPRMC_WithMode) - 5.
         if GPS_rows gt 0 then begin
           OPENR, lun, filename_GPRMC_WithMode, /GET_LUN
           header = STRARR(5)
           READF,lun,header
           ;;;Get wavelengths from Header
           header_WAV = STRSPLIT(header(3),'' + STRING(9B) + '',  /EXTRACT)
           free_lun, lun
           ;;;Get data from file
           DATA_SATTHS0035 = READ_ASCII(filename_GPRMC_WithMode, MISSING_VALUE= !Values.F_NAN, DATA_START=5, DELTMITER=STRING(9B))
           ;;;Get time from file
           OPENR, lun, filename_GPRMC_WithMode, /GET_LUN
           header = STRARR(5)
           READF,lun,header
           colm = 1
           rows = File_Lines(filename_GPRMC_WithMode)-5  ;;-5 for header)
           ST_data = STRARR([colm, rows])
           READF, lun, ST_data
           free_lun, lun
           ST_data    = REFORM(ST_data, N_ELEMENTS(ST_data))
           ;;ASSIGN VARIABLES WANTED FROM NOMAD IN STRING FORMAT
           INDEX           = STRARR(rows)
           UTCPOS          = STRARR(rows)
           STATUS          = STRARR(rows)
           LATPOS          = STRARR(rows)
           LATHEMI         = STRARR(rows)
           LONPOS          = STRARR(rows)
           LONHEMI         = STRARR(rows)
           SPEED           = STRARR(rows)
           COURSE          = STRARR(rows)
           DATE_           = STRARR(rows)
           MAGVAR          = STRARR(rows) 
           MAGHEMI         = STRARR(rows) 
           NMEA_CHECKSUM   = STRARR(rows) 
           DATETAG         = STRARR(rows)
           TIMETAG2        = STRARR(rows)
           ;;READ VARIABLES INTO STRING FORMAT (NOTE THAT THE NUMBER REPRESENTS THE ROW NUMBER IN THE FILE)
           for ii = 0, rows-1 do begin
             S = STRSPLIT(ST_data(ii), '' + STRING(9B) + '', /EXTRACT, /PRESERVE_NULL)
             INDEX(ii)           = S(0)
             UTCPOS(ii)          = S(1)
             STATUS(ii)          = S(2)
             LATPOS(ii)          = S(3)
             LATHEMI(ii)         = S(4)
             LONPOS(ii)          = S(5)
             LONHEMI(ii)         = S(6)
             SPEED(ii)           = S(7)
             COURSE(ii)          = S(8)
             DATE_(ii)           = S(9)
             MAGVAR(ii)          = S(10)
             MAGHEMI(ii)         = S(11)
             NMEA_CHECKSUM(ii)   = S(12)
             DATETAG(ii)         = S(13)
             TIMETAG2(ii)        = S(14)
           endfor
           ;;TIME
           TIME_FILE = TIMETAG2
           HH_FILE   = float(STRMID(TIME_FILE, 0,2))
           MM_FILE   = float(STRMID(TIME_FILE, 3,2))
           SS_FILE   = float(STRMID(TIME_FILE, 6,5))
           YEAR_FILE = float(STRMID(DATETAG, 0,4))
           SDY_FILE  = float(STRMID(DATETAG, 5,3))
           ;;;CONVERT TIME TO DECIMAL HOUR
           TIME_FILE_DEC  = HH_FILE + (((SS_FILE/60.)+ MM_FILE)/60.)
           TIME_GPS       = TIME_FILE_DEC
           TIME_MILI_SEC  = (HH_FILE*3600000.)+(MM_FILE*60000.)+(SS_FILE*1000.)
           ;;;FIND ONLY DATA WITH POSITION
          ;;;LAT
          LAT_INPUT = STRMID(LATPOS, 0,12)
           LAT       = fltarr(n_elements(LAT_INPUT))-999.
           for ii = 0, n_elements(LAT)-1 do begin
            S = STRSPLIT(LAT_INPUT(ii),' ',  /EXTRACT)
            if n_elements(S) gt 1 then begin
               LAT_DEG = float(S(0))
               LAT_MIN = float(S(1))
               LAT_IN  = double(LAT_DEG+(LAT_MIN/60.))
               if STRMID(LATHEMI(ii), 0,1) eq 'N' then LAT_IN = LAT_IN
               if STRMID(LATHEMI(ii), 0,1) eq 'S' then LAT_IN = -LAT_IN
               LAT(ii) = LAT_IN
            endif
           endfor
           ;;;LON
           LON_INPUT = STRMID(LONPOS, 0,12)
           LON       = fltarr(n_elements(LON_INPUT))-999.
           for ii = 0, n_elements(LON)-1 do begin
           S = STRSPLIT(LON_INPUT(ii),' ',  /EXTRACT)
           if n_elements(S) gt 1 then begin
             LON_DEG = float(S(0))
             LON_MIN = float(S(1))
             LON_IN  = double(LON_DEG+(LON_MIN/60.))
             if STRMID(LONHEMI(ii), 0,1) eq 'E' then LON_IN = LON_IN
             if STRMID(LONHEMI(ii), 0,1) eq 'W' then LON_IN = -LON_IN
             LON(ii) = LON_IN
           endif
           endfor
           SOLAR_ZEN       = fltarr(n_elements(LON_INPUT))-999.
           SOLAR_AZ        = fltarr(n_elements(LON_INPUT))-999.
           for ii = 0, n_elements(LON)-1 do begin
              if LON(ii) gt -999 then begin
                 lonlat2solz,LON(ii),LAT(ii),YEAR_FILE(ii),SDY_FILE(ii),TIME_MILI_SEC(ii),solz,sola
                 SOLAR_ZEN(ii)   = solz
                 SOLAR_AZ(ii)    = sola
             endif
           endfor
           SPEED           = float(SPEED)
           COURSE          = float(COURSE)
         endif else begin
           SOLAR_ZEN       = -999.
           SOLAR_AZ        = -999.
           SPEED           = -999
           COURSE          = -999
           LAT             = -999
           LON             = -999
           TIME_GPS        = -999
         endelse
          ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;GPS-FINISH;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

         ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Pyrometer-START;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
         OPENR, lun, filename_Pyrometer, /GET_LUN
         header = STRARR(5)
         READF,lun,header
         ;;;Get wavelengths from Header
         header_WAV = STRSPLIT(header(3),'' + STRING(9B) + '',  /EXTRACT)
         free_lun, lun
         PYROM_rows = File_Lines(filename_Pyrometer)
         if PYROM_rows gt 5 then begin
            ;;;Get data from file
            DATA_SATTHS0035 = READ_ASCII(filename_Pyrometer, MISSING_VALUE= !Values.F_NAN, DATA_START=5, DELTMITER=STRING(9B))
            ;;;Get time from file
            OPENR, lun, filename_Pyrometer, /GET_LUN
            header = STRARR(5)
            READF,lun,header
            colm = 1
            rows = n_elements(DATA_SATTHS0035.field1(1,*))
            ST_data = STRARR([colm, rows])
            READF, lun, ST_data
            free_lun, lun
            ST_data    = REFORM(ST_data, N_ELEMENTS(ST_data))
            ;;ASSIGN VARIABLES WANTED FROM NOMAD IN STRING FORMAT
            INDEX           = STRARR(rows)
            SST             = STRARR(rows)
            DATETAG         = STRARR(rows)
            TIMETAG2        = STRARR(rows)
            ;;READ VARIABLES INTO STRING FORMAT (NOTE THAT THE NUMBER REPRESENTS THE ROW NUMBER IN THE FILE)
            for ii = 0, rows-1 do begin
              S = STRSPLIT(ST_data(ii), '' + STRING(9B) + '', /EXTRACT, /PRESERVE_NULL)
              INDEX(ii)           = S(0)
              SST(ii)             = S(1)
              DATETAG(ii)         = S(2)
              TIMETAG2(ii)        = S(3)
            endfor
            SST = float(SST)
            TIME_FILE = TIMETAG2
            HH_FILE = float(STRMID(TIME_FILE, 0,2))
            MM_FILE = float(STRMID(TIME_FILE, 3,2))
            SS_FILE = float(STRMID(TIME_FILE, 6,5))
            ;;;CONVERT TIME TO DECIMAL HOUR
            TIME_FILE_DEC = HH_FILE + (((SS_FILE/60.)+ MM_FILE)/60.)
            TIME_SST    = TIME_FILE_DEC
         endif else begin   
            SST           = -999.
            TIME_FILE_DEC = -999.
            TIME_SST      = -999.
         endelse
         ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Pyrometer-FINISH;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
         
            
        ;;;INTERPOLATE DATA TO A SINGLE SET OF WAVELENGTHS
            WAVELENGTHS = (findgen(446/2)*2)+350. ;;;Create an array between 306 and 756 nm 
            
            if TIME_LT(0) gt -999 then begin
              ;;;DEFINE NEW ARRAYS
              DATA_ES_INT = fltarr([n_elements(WAVELENGTHS),n_elements(DATA_ES(0,*))]) 
              DATA_LI_INT = fltarr([n_elements(WAVELENGTHS),n_elements(DATA_LI(0,*))]) 
              DATA_LT_INT = fltarr([n_elements(WAVELENGTHS),n_elements(DATA_LT(0,*))]) 
              ;;;ES
              for ib = 0, n_elements(DATA_ES(0,*))-1 do begin
                 DATA_ES_INT(*,ib) =  INTERPOL(DATA_ES(*,ib),WAVE_ES,WAVELENGTHS)
              endfor 
              ;;;LI
              for ib = 0, n_elements(DATA_LI(0,*))-1 do begin
                 DATA_LI_INT(*,ib) =  INTERPOL(DATA_LI(*,ib),WAVE_LI,WAVELENGTHS)
              endfor
              ;;;LT
              for ib = 0, n_elements(DATA_LT(0,*))-1 do begin
                 DATA_LT_INT(*,ib) =  INTERPOL(DATA_LT(*,ib),WAVE_LT,WAVELENGTHS)
              endfor    
              ;;;INTERPOLATE DATA TO LT TIME (lowest integration speed)
              TIME                   = TIME_LT
              ;;;DEFINE NEW ARRAYS
              DATA_ES_INT_2          = fltarr([n_elements(DATA_ES_INT(*,0)),n_elements(TIME)])
              DATA_LI_INT_2          = fltarr([n_elements(DATA_LI_INT(*,0)),n_elements(TIME)])
              DATA_LT_INT_2          = fltarr([n_elements(DATA_LT_INT(*,0)),n_elements(TIME)])
              ;;;ES
              for ib = 0, n_elements(DATA_ES_INT(*,0))-1 do begin
               DATA_ES_INT_2(ib,*) = INTERPOL(DATA_ES_INT(ib,*),TIME_ES,TIME)
              endfor
              ;;;LI
              for ib = 0, n_elements(DATA_LI_INT(*,0))-1 do begin
                DATA_LI_INT_2(ib,*) = INTERPOL(DATA_LI_INT(ib,*),TIME_LI,TIME)
              endfor
              ;;;LT
              DATA_LT_INT_2 = DATA_LT_INT
              
              ;;;;;;THS
              DATA_THS_HEADING   = INTERPOL(HEADING,TIME_THS,TIME)    
              DATA_THS_AZIMUTH_  = INTERPOL(AZIMUTH_,TIME_THS,TIME)          
              DATA_THS_ELEVATION = INTERPOL(ELEVATION,TIME_THS,TIME)
              DATA_THS_POINTING  = INTERPOL(POINTING,TIME_THS,TIME) 
              DATA_THS_SENSOR_AZ = INTERPOL(ANGLE_SENSOR_AZ,TIME_THS,TIME) 
              DATA_THS_HUMIDITY  = INTERPOL(HUMIDITY,TIME_THS,TIME) 
              DATA_THS_VOLT      = INTERPOL(VOLT,TIME_THS,TIME) 
              DATA_THS_TEMP_INT  = INTERPOL(TEMP_INT,TIME_THS,TIME)
              ;;;;;;GPS
              DATA_LAT           = INTERPOL(LAT,TIME_GPS,TIME)
              DATA_LON           = INTERPOL(LON,TIME_GPS,TIME)
              DATA_SPEED         = INTERPOL(SPEED,TIME_GPS,TIME)
              DATA_COURSE        = INTERPOL(COURSE,TIME_GPS,TIME)
              DATA_SOLAR_ZEN     = INTERPOL(SOLAR_ZEN,TIME_GPS,TIME)
              DATA_SOLAR_AZ      = INTERPOL(SOLAR_AZ,TIME_GPS,TIME)
              ;;;;;;SST
              DATA_SST           = INTERPOL(SST,TIME_SST,TIME)

              ;;;RENAME DATA TO COMMON FORMAT
              DATA_ES            = DATA_ES_INT_2
              DATA_LI            = DATA_LI_INT_2
              DATA_LT            = DATA_LT_INT_2
              
              ;;;;COMPUTE RRS
              ROUW = 0.028 ;;;;;Assuming Mobley (1999) Applied Optics
              RRS  = (DATA_LT - ROUW*DATA_LI)/DATA_ES
              ;;;;QUICK PLOT CHECK (see to compare with Fig. 2.3 of HyperSAT doc)
              ;;;;PLOT, WAVELENGTHS,  RRS1(*,0), PSYM = 0
  
              ;;;ADD TIME AND THS DATA TO MATRIES
              TIME               = reform(TIME, [1,n_elements(TIME)])
              DATA_THS_HEADING   = reform(DATA_THS_HEADING, [1,n_elements(DATA_THS_HEADING)])
              DATA_THS_AZIMUTH_  = reform(DATA_THS_AZIMUTH_, [1,n_elements(DATA_THS_AZIMUTH_)])
              DATA_THS_ELEVATION = reform(DATA_THS_ELEVATION, [1,n_elements(DATA_THS_ELEVATION)])
              DATA_THS_POINTING  = reform(DATA_THS_POINTING, [1,n_elements(DATA_THS_POINTING)])
              DATA_THS_SENSOR_AZ = reform(DATA_THS_SENSOR_AZ, [1,n_elements(DATA_THS_SENSOR_AZ)])
              DATA_THS_HUMIDITY  = reform(DATA_THS_HUMIDITY, [1,n_elements(DATA_THS_HUMIDITY)])
              DATA_THS_VOLT      = reform(DATA_THS_VOLT, [1,n_elements(DATA_THS_VOLT)])
              DATA_THS_TEMP_INT  = reform(DATA_THS_TEMP_INT, [1,n_elements(DATA_THS_TEMP_INT)])
              ;;;;;;GPS
              DATA_LAT           = reform(DATA_LAT, [1,n_elements(DATA_LAT)])
              DATA_LON           = reform(DATA_LON, [1,n_elements(DATA_LON)])
              DATA_SPEED         = reform(DATA_SPEED, [1,n_elements(DATA_SPEED)])
              DATA_COURSE        = reform(DATA_COURSE, [1,n_elements(DATA_COURSE)])
              DATA_SOLAR_ZEN     = reform(DATA_SOLAR_ZEN, [1,n_elements(DATA_SOLAR_ZEN)])
              DATA_SOLAR_AZ      = reform(DATA_SOLAR_AZ, [1,n_elements(DATA_SOLAR_AZ)])
              ;;;;;SST
              DATA_SST           = reform(DATA_SST, [1,n_elements(DATA_SST)])

            ;;;BRING DATA TOGETHER
            
              RRS              = [RRS,TIME,DATA_LAT,DATA_LON,DATA_SPEED,DATA_COURSE,DATA_SOLAR_ZEN,DATA_SOLAR_AZ,DATA_THS_HEADING,$
                                  DATA_THS_AZIMUTH_,DATA_THS_ELEVATION,DATA_THS_POINTING,DATA_THS_SENSOR_AZ,DATA_THS_HUMIDITY,DATA_THS_VOLT,DATA_THS_TEMP_INT,DATA_SST]
              DATA_LT          = [DATA_LT,TIME,DATA_LAT,DATA_LON,DATA_SPEED,DATA_COURSE,DATA_SOLAR_ZEN,DATA_SOLAR_AZ,DATA_THS_HEADING,$
                                  DATA_THS_AZIMUTH_,DATA_THS_ELEVATION,DATA_THS_POINTING,DATA_THS_SENSOR_AZ,DATA_THS_HUMIDITY,DATA_THS_VOLT,DATA_THS_TEMP_INT,DATA_SST]
              DATA_LI          = [DATA_LI,TIME,DATA_LAT,DATA_LON,DATA_SPEED,DATA_COURSE,DATA_SOLAR_ZEN,DATA_SOLAR_AZ,DATA_THS_HEADING,$
                                  DATA_THS_AZIMUTH_,DATA_THS_ELEVATION,DATA_THS_POINTING,DATA_THS_SENSOR_AZ,DATA_THS_HUMIDITY,DATA_THS_VOLT,DATA_THS_TEMP_INT,DATA_SST]
              DATA_ES          = [DATA_ES,TIME,DATA_LAT,DATA_LON,DATA_SPEED,DATA_COURSE,DATA_SOLAR_ZEN,DATA_SOLAR_AZ,DATA_THS_HEADING,$
                                  DATA_THS_AZIMUTH_,DATA_THS_ELEVATION,DATA_THS_POINTING,DATA_THS_SENSOR_AZ,DATA_THS_HUMIDITY,DATA_THS_VOLT,DATA_THS_TEMP_INT,DATA_SST]
            ;;;Create matrix to put all RRS data for each day into (91 wavelegnths + the time hence 92, then arbitary 100000 to shove data into)
              count2                       = count1 + (float(n_elements(TIME))-1.)
              MATRIX_RRS(*,count1:count2)  = RRS
              MATRIX_LT(*,count1:count2)   = DATA_LT
              MATRIX_LI(*,count1:count2)   = DATA_LI
              MATRIX_ES(*,count1:count2)   = DATA_ES
              ;;;Add to index to appropriately bin the Rrs data into   
              count1                       = count2 + 1.    
           endif 
      endfor

      ;;;Clear only available data
      as           = where(MATRIX_ES(0,*) ne -999., ctyi)
      if ctyi gt 0 then begin
         MATRIX_LT    = MATRIX_LT(*,as)
         MATRIX_LI    = MATRIX_LI(*,as)
         MATRIX_ES    = MATRIX_ES(*,as)
         MATRIX_RRS   = MATRIX_RRS(*,as)
         
         ;;;;New Time dimension
         TIME_NEW = (findgen(1441)*0.01666667) ;;;1 minute bins
         MATRIX_LT_NEW      = fltarr([n_elements(MATRIX_LT(*,0)),1440])
         MATRIX_LI_NEW      = fltarr([n_elements(MATRIX_LT(*,0)),1440])
         MATRIX_ES_NEW      = fltarr([n_elements(MATRIX_LT(*,0)),1440])
         MATRIX_RRS_NEW     = fltarr([n_elements(MATRIX_LT(*,0)),1440])
         MATRIX_LT_MAD_NEW  = fltarr([n_elements(MATRIX_LT(*,0)),1440])
         MATRIX_LI_MAD_NEW  = fltarr([n_elements(MATRIX_LT(*,0)),1440])
         MATRIX_ES_MAD_NEW  = fltarr([n_elements(MATRIX_LT(*,0)),1440])
         MATRIX_RRS_MAD_NEW = fltarr([n_elements(MATRIX_LT(*,0)),1440])
         N_MIN_BIN          = fltarr(1440)
         
         for id = 0, n_elements(TIME_NEW)-2 do begin
          ads = where(MATRIX_LT(223,*) ge TIME_NEW(id) and MATRIX_LT(223,*) lt TIME_NEW(id+1), cnti)
          N_MIN_BIN(id) = cnti
          if cnti gt 0 then begin
            for ik = 0, n_elements(MATRIX_LT(*,0))-1 do begin
              MATRIX_ES_NEW(ik,id)        = median(MATRIX_ES(ik,ads))
              MATRIX_LT_NEW(ik,id)        = median(MATRIX_LT(ik,ads))
              MATRIX_LI_NEW(ik,id)        = median(MATRIX_LI(ik,ads))
              MATRIX_RRS_NEW(ik,id)       = median(MATRIX_RRS(ik,ads))
              MATRIX_ES_MAD_NEW(ik,id)    = Medabsdev(MATRIX_ES(ik,ads))
              MATRIX_LT_MAD_NEW(ik,id)    = Medabsdev(MATRIX_LI(ik,ads))
              MATRIX_LI_MAD_NEW(ik,id)    = Medabsdev(MATRIX_LT(ik,ads))
              MATRIX_RRS_MAD_NEW(ik,id)   = Medabsdev(MATRIX_RRS(ik,ads))
            endfor
          endif else begin
            MATRIX_LT_NEW(*,id)      = fltarr(n_elements(MATRIX_LT(*,0)))-999
            MATRIX_LI_NEW(*,id)      = fltarr(n_elements(MATRIX_LT(*,0)))-999
            MATRIX_ES_NEW(*,id)      = fltarr(n_elements(MATRIX_LT(*,0)))-999
            MATRIX_RRS_NEW(*,id)     = fltarr(n_elements(MATRIX_LT(*,0)))-999
            MATRIX_LT_MAD_NEW(*,id)  = fltarr(n_elements(MATRIX_LT(*,0)))-999
            MATRIX_LI_MAD_NEW(*,id)  = fltarr(n_elements(MATRIX_LT(*,0)))-999
            MATRIX_ES_MAD_NEW(*,id)  = fltarr(n_elements(MATRIX_LT(*,0)))-999
            MATRIX_RRS_MAD_NEW(*,id) = fltarr(n_elements(MATRIX_LT(*,0)))-999
          endelse
        endfor
        
        MATRIX_RRS_QC = MATRIX_RRS_NEW
        ;;;;RRS
        for id = 0, n_elements(TIME_NEW)-2 do begin
          INFRA_RED = median(MATRIX_RRS_NEW(200:222,id))
           MATRIX_RRS_QC(0:222,id) = MATRIX_RRS_NEW(0:222,id) - INFRA_RED
           ;;;SUN ANGLES >0 and <60.
           if MATRIX_RRS_NEW(228,id) lt 0.0 then MATRIX_RRS_QC(0:222,id) = fltarr(n_elements(WAVELENGTHS))-999
           if MATRIX_RRS_NEW(228,id) gt 60.0 then MATRIX_RRS_QC(0:222,id) = fltarr(n_elements(WAVELENGTHS))-999
           ;;;Angle between Azimith and SAS Heading (only keep data 90 - 170 and 190 to 270)
           AZ_SAS_ANGLE = MATRIX_RRS_NEW(234,id)
           if AZ_SAS_ANGLE ge 0 and AZ_SAS_ANGLE lt 100. then MATRIX_RRS_QC(0:222,id) = fltarr(n_elements(WAVELENGTHS))-999
           if AZ_SAS_ANGLE gt 260 and AZ_SAS_ANGLE le 360. then MATRIX_RRS_QC(0:222,id) = fltarr(n_elements(WAVELENGTHS))-999
           ;;;If variance at 750 within 1 minute bin is greater than 0.02 (used as an index of high glint)
           if MATRIX_RRS_MAD_NEW(200,id) gt 0.002 then MATRIX_RRS_QC(0:222,id) = fltarr(n_elements(WAVELENGTHS))-999
        endfor
        
        as = where(MATRIX_LT_NEW(223,*) ne -999.)
        MATRIX_ES_NEW  = MATRIX_ES_NEW(*,as)
        MATRIX_LT_NEW  = MATRIX_LT_NEW(*,as)
        MATRIX_LI_NEW  = MATRIX_LI_NEW(*,as)
        MATRIX_RRS_NEW = MATRIX_RRS_NEW(*,as)
        MATRIX_RRS_QC  = MATRIX_RRS_QC(*,as)
        
        ;;;WRITE DATA FILES
        WAVELENGTHS_STR = string(WAVELENGTHS, format='(F5.1)')
        Header          = [WAVELENGTHS_STR,'TIME [DECIMAL-HOUR]','LAT [deg N]','LON [deg E]','SPEED [knots]','COURSE(True) [degrees]','Solar Zenith Angle Computed [degrees]','Solar Azimith Angle Computed [degrees]',$
                           'HEADING(SAS_TRUE) [degrees]','AZIMUTH(SUN) [degrees]','ELEVATION(SUN) [degrees]','POINTING(ROTATOR) [degrees]','SENSOR-TO-AZIMITH angle [degees]','HUMIDITY [percent]','VOLT(SUPPLY) [V]',$
                           'TEMPERATURE(INTERNAL) [deg C]','SST(PYROMETER) [deg C]']
        ;;;Rrs
        table1 = string(MATRIX_RRS_QC)
        table1 = [[Header],[table1]]
        xAsString = strtrim(table1)
        outputLine = strjoin(xAsString, ',')
        openw, lun, ''+file_data_path_output+'/Archimedes_RRS_'+SDY_STRING+'.dat', /GET_LUN
        printf, lun, outputLine
        free_lun, lun
        ;;;LI
        table1 = string(MATRIX_LI_NEW)
        table1 = [[Header],[table1]]
        xAsString = strtrim(table1)
        outputLine = strjoin(xAsString, ',')
        openw, lun, ''+file_data_path_output+'/Archimedes_LI_'+SDY_STRING+'.dat', /GET_LUN
        printf, lun, outputLine
        free_lun, lun
        ;;;LT
        table1 = string(MATRIX_LT_NEW)
        table1 = [[Header],[table1]]
        xAsString = strtrim(table1)
        outputLine = strjoin(xAsString, ',')
        openw, lun, ''+file_data_path_output+'/Archimedes_LT_'+SDY_STRING+'.dat', /GET_LUN
        printf, lun, outputLine
        free_lun, lun
        ;;;ES
        table1 = string(MATRIX_ES_NEW)
        table1 = [[Header],[table1]]
        xAsString = strtrim(table1)
        outputLine = strjoin(xAsString, ',')
        openw, lun, ''+file_data_path_output+'/Archimedes_ES_'+SDY_STRING+'.dat', /GET_LUN
        printf, lun, outputLine
        free_lun, lun
        
        ;;;IDL SAVE FILES
        save, MATRIX_RRS_QC, MATRIX_RRS_NEW, MATRIX_LT_NEW, MATRIX_LI_NEW, MATRIX_ES_NEW, WAVELENGTHS, filename = ''+file_data_path_output+'/Archimedes_'+SDY_STRING+'.sav'
        print, SDY_STRING
      endif

         ;;Clear data from memory
         MATRIX_TOT               = 0
         MATRIX_RRS               = 0
         MATRIX_LT                = 0                                     
         MATRIX_LI                = 0     
         MATRIX_ES                = 0 
         table1                   = 0          
         xAsString                = 0
         outputLine               = 0
         TIME_FOR_DAY             = 0
         SHIP_START_TIME_MATCH    = 0
         SHIP_LAT_MATCH           = 0
         SHIP_LON_MATCH           = 0
         SHIP_PRES_AT_MATCH       = 0
         SHIP_PAR_MATCH           = 0
         SHIP_WIND_DIR_IN_MATCH   = 0
         SHIP_WIND_SPEED_IN_MATCH = 0
         SHIP_ORIN_MATCH          = 0
         SHIP_SALINITY_MATCH      = 0
         SHIP_TEMP_MATCH          = 0
         SHIP_DELTA_AZ_MATCH      = 0
         SHIP_AZIMTH_MATCH        = 0
         SHIP_ZENITH_MATCH        = 0
         TIME                     = 0
         DATA_THS_COMPASS         = 0
         DATA_THS_PITCH           = 0
         DATA_THS_ROLL            = 0
         RRS                      = 0
         DATA_LT                  = 0
         DATA_LI                  = 0
         DATA_ES                  = 0
         MATRIX_RRS_QC            = 0
         MATRIX_LT_NEW            = 0
         MATRIX_LI_NEW            = 0
         MATRIX_ES_NEW            = 0
         MATRIX_RRS_NEW           = 0
   
endfor
end