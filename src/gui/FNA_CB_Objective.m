function FNA_CB_Objective(hObject, ~)
%
% AUTHOR: Maximilian C. M. Fischer
% COPYRIGHT (C) 2020-2023 Maximilian C. M. Fischer
% LICENSE: EUPL v1.2
%

GD = guidata(hObject);
GD.Algorithm.Objective = hObject.String{hObject.Value};
guidata(hObject,GD);

GD.Figure.SaveResultsHandle.Enable = 'off';
end