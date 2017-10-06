function DD_CB_StepSize(hObject, ~)
    GUIData = guidata(hObject);
    Index = get(hObject,'Value');
    GUIData.Algorithm3.StepSize = Index;
    guidata(hObject,GUIData);
end