function CB_CB_EllipsePlot(hObject, ~)
    GUIData = guidata(hObject);
    GUIData.Algorithm3.EllipsePlot = get(hObject,'Value');
    guidata(hObject,GUIData);
end