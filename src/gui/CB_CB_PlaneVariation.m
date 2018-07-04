function CB_CB_PlaneVariation(hObject, ~)
    GUIData = guidata(hObject);
    GUIData.ANA_Algorithm.PlaneVariaton = get(hObject,'Value');
    guidata(hObject,GUIData);
end