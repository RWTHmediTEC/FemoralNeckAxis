function FNA_CB_StepSize(hObject, ~)
%
% AUTHOR: Maximilian C. M. Fischer
% COPYRIGHT (C) 2020 Maximilian C. M. Fischer
% LICENSE: EUPL v1.2
%

GD = guidata(hObject);
Index = get(hObject,'Value');
GD.Algorithm.StepSize = Index;
guidata(hObject,GD);
end