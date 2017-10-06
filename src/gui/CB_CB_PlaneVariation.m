function CB_CB_PlaneVariation(hObject, ~)
    GUIData = guidata(hObject);
    GUIData.Algorithm3.PlaneVariaton = get(hObject,'Value');
    guidata(hObject,GUIData);
end