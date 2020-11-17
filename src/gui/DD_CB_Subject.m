function DD_CB_Subject(hObject, ~, Subjects)
%
% AUTHOR: Maximilian C. M. Fischer
% COPYRIGHT (C) 2020 Maximilian C. M. Fischer
% LICENSE: EUPL v1.2
%

GD = guidata(hObject);
Index = get(hObject,'Value');
GD.Subject.Name = Subjects{Index,1};
GD.Subject.Side = Subjects{Index,2};
guidata(hObject,GD);

GD.Figure.SaveResultsHandle.Enable = 'off';
end