function M_CB_RotateWithMouse(src,~)
if strcmp(get(src,'SelectionType'),'extend')
    cameratoolbar('SetMode','orbit')
end
end