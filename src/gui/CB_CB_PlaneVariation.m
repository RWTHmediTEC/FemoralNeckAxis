function CB_CB_PlaneVariation(hObject, ~)
    GUIData = guidata(hObject);
    GUIData.FNA_Algorithm.PlaneVariaton = get(hObject,'Value');
    guidata(hObject,GUIData);
end