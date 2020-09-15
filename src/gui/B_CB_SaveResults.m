function GD = B_CB_SaveResults(hObject, GD)
if ishandle(hObject); GD = guidata(hObject); end

if isfield(GD.Results, 'PlaneRotMat')
    FNAxis = GD.Results.FNA;
    FNA_TFM = GD.Subject.TFM;
    save('FNA_Results.mat', 'FNAxis', 'FNA_TFM')
    disp('Results saved.')
else
    uiwait(errordlg('There are no results to save'));
end

if isfield(GD.Results, 'B_H_SaveResults')
    set(GD.Results.B_H_SaveResults,'Enable','off')
end

if ishandle(hObject); guidata(hObject,GD); end
end