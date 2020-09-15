function DD_CB_StepSize(hObject, ~)
    GUIData = guidata(hObject);
    Index = get(hObject,'Value');
    GUIData.FNA_Algorithm.StepSize = Index;
    guidata(hObject,GUIData);
end