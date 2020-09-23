function FNA_CB_EllipsePlot(hObject, ~)
%
% AUTHOR: Maximilian C. M. Fischer
% COPYRIGHT (C) 2020 Maximilian C. M. Fischer
% LICENSE: EUPL v1.2
%

GD = guidata(hObject);
GD.Algorithm.EllipsePlot = get(hObject,'Value');
guidata(hObject,GD);
end