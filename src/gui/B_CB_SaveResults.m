function GD = B_CB_SaveResults(hObject, GD)
if ishandle(hObject); GD = guidata(hObject); end

if isfield(GD.Results, 'PlaneRotMat')
    ANATFM = GD.Subject.TFM;
    ANA = GD.Results.ANA;
    % load(GD.Subject.PathMAT)
    % save(GD.Subject.PathMAT, 'ANATFM', 'CEA', '-append')
    % disp('Results saved.')
    disp('Save function is not working at the moment')
else
    uiwait(errordlg('There are no results to save'));
end

if isfield(GD.Results, 'B_H_SaveResults')
    set(GD.Results.B_H_SaveResults,'Enable','off')
end

if ishandle(hObject); guidata(hObject,GD); end
end