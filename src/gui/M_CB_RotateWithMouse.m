function M_CB_RotateWithMouse(src,~)
%
% AUTHOR: Maximilian C. M. Fischer
% COPYRIGHT (C) 2020-2023 Maximilian C. M. Fischer
% LICENSE: EUPL v1.2
%

if strcmp(get(src,'SelectionType'),'extend')
    cameratoolbar('SetMode','orbit')
end
end