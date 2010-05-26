
function AOhelp::Init, objname, objdescr
    self._objname       = objname
    self._objdescr      = objdescr
    self._leafs         = obj_new('IDL_Container')
    self._methods_help  = obj_new('IDL_Container')
    self->setHowDoTheyCallMe, 'ee'
    return, 1
end

pro AOhelp::setHowDoTheyCallMe, leaf_call
    self._objcall = leaf_call
end

function AOhelp::howDoTheyCallMe
    return, self._objcall
end


function AOhelp::fmthelp, syntax, descr, indent, style=style, root=root
    if n_elements(style) ne 0 then usestyle=style else usestyle='method'
    case usestyle of
        'leaf'   : begin & spacer='***' & col2pos=50  & end
        'method' : begin & spacer='---' & col2pos=60  & end
    endcase 
    if keyword_set(root) then begin
        cmd1="("+root+"->"+self->howDoTheyCallMe()+")->"+syntax
    endif else begin
        cmd1=strjoin([ indent gt 0 ? replicate(spacer,indent) : "", " ", syntax])
    endelse
    cmd2=strjoin( [": ", descr])
    cmd = strjoin(replicate(" ", 130))
    strput, cmd, cmd1, 0
    strput, cmd, cmd2, col2pos
    return, cmd
end

pro AOhelp::printhelp, syntax, descr, indent, style=style
    stringa = self->AOhelp::fmthelp(syntax, descr, indent, style=style)
    print, stringa
end

function AOhelp::cmdlist,root=root
    if not keyword_set(root) then root="ee"
    cmdlista = ['']
    if obj_valid(self._methods_help) then begin
        for i=0L, self._methods_help->Count()-1 do begin
            meth_help = self._methods_help->Get(pos=i)
            cmdlista = [temporary(cmdlista), self->AOhelp::fmthelp(meth_help->syntax(), meth_help->descr(), 0, root=root)]
        endfor
    endif

    ; go down in tree
    if obj_valid(self._leafs) then begin
        for i=0L, self._leafs->Count()-1 do begin
            cmdlista = [temporary(cmdlista), (self._leafs->Get(pos=i))->AOhelp::cmdlist(root="("+root+"->"+self->howDoTheyCallMe()+")")]
        endfor
    endif
    return, cmdlista
end

pro AOhelp::info
    help, self, /object
end

pro AOhelp::help, keyword, indent=indent
    
    if n_params() eq 1 and (test_type(keyword, /string) eq 0 ) then begin
        lista = self->cmdlist()
        matched = where(stregex(lista, keyword, /bool) eq 1, cnt)
        if cnt gt 0 then print, lista[matched]
        return
    endif

    if n_elements(indent) eq 0 then indent=1
    
    ;cmd1=strjoin([ '*** ', self._objname,' ***'])
    ;cmd2=strjoin( [": ", self._objdescr])
    ;cmd = strjoin(replicate(" ", 130))
    ;strput, cmd, cmd1, 0
    ;strput, cmd, cmd2, 50
    ;print, cmd
    self->AOhelp::printhelp, self._objname, self._objdescr, indent, style='leaf'
    ; print methods description
    if obj_valid(self._methods_help) then begin
        for i=0L, self._methods_help->Count()-1 do begin
            meth_help = self._methods_help->Get(pos=i)
            self->AOhelp::printhelp, meth_help->syntax(), meth_help->descr(), indent 
        endfor
    endif

    ; go down in tree
    if obj_valid(self._leafs) then begin
        for i=0L, self._leafs->Count()-1 do begin
            (self._leafs->Get(pos=i))->AOhelp::help, indent=indent+1
        endfor
    endif
end

pro AOhelp::addMethodHelp, syntax, description
    tmp = obj_new('AOmethodhelp', syntax, description) 
    self._methods_help->add, tmp
end

pro AOhelp::addleaf, leaf, leaf_call
    ;leaf->setHowDoTheyCallMe, "("+self->howDoTheyCallMe()+")->"+leaf_call+"()"
    leaf->setHowDoTheyCallMe, leaf_call+"()"
    if obj_isa(leaf, 'AOhelp') then self._leafs->add, leaf
end

pro AOhelp::Cleanup
    obj_destroy, self._leafs
    obj_destroy, self._methods_help
end

pro AOhelp__define
    struct = { AOhelp,               $
        _objname  :       "",        $
        _objdescr :       "",        $
        _objcall  :       "",        $
        _leafs :          obj_new(), $
        _methods_help:    obj_new()  $
    }
end