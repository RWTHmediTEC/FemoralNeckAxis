function FNA_CB_PlotPlaneVariation(hObject, ~)
%
% AUTHOR: Maximilian C. M. Fischer
% COPYRIGHT (C) 2020-2023 Maximilian C. M. Fischer
% LICENSE: EUPL v1.2
%

GD = guidata(hObject);
GD.Algorithm.PlotPlaneVariation = get(hObject,'Value');
guidata(hObject,GD);
end