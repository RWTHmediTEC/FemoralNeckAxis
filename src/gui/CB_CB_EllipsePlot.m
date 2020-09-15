function CB_CB_EllipsePlot(hObject, ~)
    GUIData = guidata(hObject);
    GUIData.FNA_Algorithm.EllipsePlot = get(hObject,'Value');
    guidata(hObject,GUIData);
end