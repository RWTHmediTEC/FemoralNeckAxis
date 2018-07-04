function CB_CB_EllipsePlot(hObject, ~)
    GUIData = guidata(hObject);
    GUIData.ANA_Algorithm.EllipsePlot = get(hObject,'Value');
    guidata(hObject,GUIData);
end