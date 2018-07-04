function DD_CB_PlaneVariationRange(hObject, ~)
    GD = guidata(hObject);
    Index = get(hObject,'Value');
    GD.ANA_Algorithm.PlaneVariationRange = Index;
    guidata(hObject,GD);
end