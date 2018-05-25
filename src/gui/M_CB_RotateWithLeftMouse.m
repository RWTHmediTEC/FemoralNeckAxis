function M_CB_RotateWithLeftMouse(src,~)
if strcmp(get(src,'SelectionType'),'extend')
    cameratoolbar('SetMode','orbit')
end
end