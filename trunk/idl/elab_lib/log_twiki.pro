pro log_twiki, aodataset, ref_star=ref_star, TEXT = TEXT, VALID = VALID
    if not keyword_set(ref_star) then ref_star='???'

    objref =  aodataset->Get(/all)

    hdr =  "| *TrackNo* | *RefStar* | *Mag* | *El* | *Wind* | *DIMM/OL* | *Rec* | *bin* | *#mod* | *freq* "+$
           "| *gain* | *mod* | *nph* | *AntiDrift* | *SR* | *filter* | *exp* | *#frames* | *disturb* | *SN* "+$
           "| *notes* "+$
           "| "

    print, hdr
    TEXT = hdr

    idlstring = "["
    VALID = ['']

    for i=0, aodataset->Count()-1 do begin
        ee = getaoelab(objref[i])
        if obj_valid(ee) eq 0 then begin
            message, objref[i] + ' skipped because it lacks required data', /info
            continue
        endif

        if ee->meas_type() ne 'LOOP' then begin
            ;message, objref[i] + ' skipped because meas type is '+ee->meas_type(), /info
            continue
        endif

        instr = obj_valid(ee->irtc()) ? ee->irtc() : ee->pisces()

		gaintemp = [-1., -1., -1.]
        if obj_valid(ee->control()) then begin
        	gg = (ee->control())->gain()
        	ngains = n_elements(rem_dup(gg))
			if ngains gt 1 then begin
				ggidx = where(gg-shift(gg,1) ne 0)
        		if ggidx[0] ne -1 then gaintemp[0] = gg[ggidx]
        	endif else gaintemp[0]=gg[0]
        endif
        ;if obj_valid(instr) then begin
        ;   case round( instr->lambda()*1e9) of
        ;        1070: band = 'J'
        ;        1600: band = 'H'
        ;        else: band = '?'
        ;    endcase
        ;endif else begin
        ;    band = '?'
        ;endelse
        if ee->operation_mode() eq 'RR' then begin
        	if obj_valid(ee->disturb()) then disturb='ON' else disturb='OFF'
            if disturb eq 'OFF' then print, 'WARNING: DISTURB IS OFF!!'
        endif else disturb='ONSKY'

		if obj_valid(ee->frames()) then ad_status = (ee->frames())->antidrift_status() ? 'ON':'OFF'

        sn_fname = 'NO'
        if obj_valid(ee->slopes_null()) then begin
            bname = file_basename((ee->slopes_null())->fname())
            if stregex( bname, '[0-9]*_[0-9]*.fits') eq 0 then sn_fname = strmid(bname, 9, 6 )
            if stregex( bname, '[0-9]*_[0-9]*_[0-9]*.fits') eq 0 then sn_fname = strmid(bname, 9, 10 )
        endif

        VALID = [VALID, ee->tracknum()]
        str = string(format='(%"| %s | %s | %4.1f | %d | %d | %5.2f %5.2f | %s | %d | %d | %d | %4.1f  %4.1f  %4.1f | %d | %d | %s | %6.1f | %s | %d | %d | %s | %s | %s |")', $
            ee->tracknum(), $
            ref_star, $
            ee->mag(), $
            obj_valid(ee->tel()) ? round( (ee->tel())->el() ) : -1 , $
            obj_valid(ee->tel()) ? round( (ee->tel())->extern_wind_speed() ) : -1 , $
            obj_valid(ee->tel()) ?  (ee->tel())->dimm_seeing() : -1 , $
            obj_valid(ee->olmodes()) ?  (ee->olmodes())->seeing() : -1 , $
            obj_valid(ee->modal_rec()) ? strmid(file_basename((ee->modal_rec())->fname()), 13, 6 ) : ' ', $
            obj_valid(ee->wfs_status()) ? ((ee->wfs_status())->ccd39())->binning() : -1, $
            obj_valid(ee->modal_rec()) ? round((ee->modal_rec())->nmodes()) : -1, $
            obj_valid(ee->wfs_status()) ?  round(((ee->wfs_status())->ccd39())->framerate()) : -1, $
            gaintemp[0], gaintemp[1] , gaintemp[2], $
            obj_valid(ee->wfs_status()) ? round( (ee->wfs_status())->modulation() ) : -1, $
            obj_valid(ee->frames()) ? round((ee->frames())->nphsub_per_int_av()) : -1, $
            obj_valid(ee->frames()) ? ad_status : -1, $
            obj_valid(instr) ?  instr->sr_se()*100 : -1, $
            obj_valid(instr) ? instr->filter_name() : '?' , $
            obj_valid(instr) ? round( instr->exptime()*1e3) : -1 , $
    		obj_valid(instr) ? instr->nframes() : -1 , $
			disturb,  $
            sn_fname, $
            ee->isOK(cause=cause) eq 1L ? "" :  cause $
        )

        print, str
        TEXT = [TEXT, str]

        if i ne 0 then idlstring += ","
        idlstring += "'"+ee->tracknum()+"'"
        ee->free
    endfor
    aodataset->free

    idlstring +="]"
    print, 'IDL string:  ' +idlstring
    if n_elements(VALID) gt 1 then VALID = VALID[1:*]
end
