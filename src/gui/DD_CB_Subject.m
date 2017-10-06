function DD_CB_Subject(hObject, ~, Subjects)
    GUIData = guidata(hObject);
    Index = get(hObject,'Value');
    GUIData.Subject.Name = Subjects{Index};
    guidata(hObject,GUIData);
    
    set(GUIData.Results.B_H_SaveResults,'Enable','off')
end