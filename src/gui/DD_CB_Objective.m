function DD_CB_Objective(hObject, ~)
%
% AUTHOR: Maximilian C. M. Fischer
% COPYRIGHT (C) 2020 Maximilian C. M. Fischer
% LICENSE: EUPL v1.2
%

GD = guidata(hObject);
GD.FNA_Algorithm.Objective = hObject.String{hObject.Value};
guidata(hObject,GD);

set(GD.Results.B_H_SaveResults,'Enable','off')
end