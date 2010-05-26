
function aomultiton_im::Init
    self._tag_list = ptr_new([''])
    self._obj_list = obj_new('IDL_Container')
    return, 1
end

function aomultiton_im::getobj, fname
    if fname eq "" then return, obj_new()

    tags = *self._tag_list
    pos = where(tags eq fname, cnt)
    if cnt ne 0 then begin
        obj = self._obj_list->Get(pos=pos)
        if obj_valid(obj) then return, obj
    endif

    oo = obj_new('AOintmat', fname)
    if not obj_valid(oo) then return, obj_new()

    ptr_free, self._tag_list
    self._tag_list = ptr_new([fname, tags])
    self._obj_list->add, oo, pos=0
    return, self._obj_list->Get(pos=0)
end

pro aomultiton_im__define
    struct = { aomultiton_im, $
        _tag_list   : ptr_new() ,$
        _obj_list   : obj_new()  $
    }
end

function getintmat, tag
    defsysv, "!aomultiton_im", EXISTS=exists
    if not exists then begin
        aomultiton_im = obj_new('aomultiton_im')
        defsysv, "!aomultiton_im", aomultiton_im
    endif
    return, !aomultiton_im->getobj(tag)
end
