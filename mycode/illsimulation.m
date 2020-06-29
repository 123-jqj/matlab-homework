% --------------------����GUI��Ҫ����--------------------
function varargout = illsimulation(varargin)
    gui_Singleton = 1;
    gui_State = struct('gui_Name', mfilename, ...
        'gui_Singleton', gui_Singleton, ...
        'gui_OpeningFcn', @illsimulation_OpeningFcn, ...
        'gui_OutputFcn', @illsimulation_OutputFcn, ...
        'gui_LayoutFcn', [], ...
        'gui_Callback', []);
    if nargin && ischar(varargin{1})
        gui_State.gui_Callback = str2func(varargin{1});
    end
    if nargout
        [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
    else
        gui_mainfcn(gui_State, varargin{:});
    end
function varargout = illsimulation_OutputFcn(~, ~, handles) 
    varargout{1} = handles.output;

% --------------------GUI���ڳ�ʼ������--------------------
% --- Executes just before illsimulation is made visible.
function illsimulation_OpeningFcn(hObject, ~, handles, varargin)
    set(handles.radio_static, 'value', 1);
    set(handles.panel_static, 'Visible', 'on');
    set(handles.panel_dynamic, 'Visible', 'off');
    set(handles.panel_excel, 'Visible', 'off');
    set(handles.panel_ppt, 'Visible', 'off');
    handles.output = hObject;
    guidata(hObject, handles);


% -------------------------!GUIѡ���ȡ�����ļ�!-------------------------%
% --- Executes on button press in Button_handdata.
function Button_handdata_Callback(hObject, ~, handles)
    [Filename, Pathname] = uigetfile({'*.xls';'All Files(*.*)'},'Choose a file');
    L = length(Filename);
    if L<5
        errordlg('Wrong File','File open error')
        return
    end
    filetype = Filename(1,L-3:L);
    switch filetype
        case '.xls'
        try
            str = [ Pathname Filename];
            set(handles.fileshow,'string',str);
            h = waitbar(0,'���Եȣ����ڿ�ʼ��ȡ�ļ���');
            [data ,~, ~] = xlsread(str);
            pause(0.5);
            waitbar(1,h,'�ļ���ȡ�����');
            assignin('base', 'data', data);
            handles.data = data;    
            Tstart =1; Tend =56; data(isnan(data))=0;
            handles.pat_infected = data(Tstart:Tend,2);
            handles.pat_died = data(Tstart:Tend,4);
            handles.pat_recover = data(Tstart:Tend,5);
            handles.data = data;
            handles.true_patient = data(:,2) -data(:,4)-data(:,5);
            guidata(hObject,handles); 
            waitbar(1,h,'���ݵ��������');
            delete(h);
        catch
            disp('Excel com�ں�ռ�ã���ر�excel\���comռ�ò�������Matlab')
            return
        end
        otherwise
            errordlg('Wrong File','File open error')
            return
    end
    
% -------------------------!����1�����ٷ��滭ͼ!-------------------------%
% --- Executes on button press in Button_update.
function Button_update_Callback(hObject, ~, handles)
    % ----------������ϻ�ȡr����----------
    [xData, yData] = prepareCurveData(handles.pat_infected, handles.pat_recover);
    ft = fittype('poly1');
    [fitresult, ~] = fit(xData, yData, ft);
    r = fitresult.p1; %��ϻ�õĻ��߿����ĸ���

    % ----------������ϻ�ȡd����----------
    [xData, yData] = prepareCurveData(handles.pat_infected, handles.pat_died);
    ft = fittype('poly1');
    [fitresult, ~] = fit(xData, yData, ft);
    d = fitresult.p1; %��ϻ�õĻ��������ĸ���

    % ----------����������úͳ�ʼ��״̬----------
    S = 50e4; % S:�׸���Ⱥ����
    E = 111; % E:Ǳ���ڻ���
    I = 270; % I:��Ⱦ��
    R = 25; % R:������
    N = S + E + I + R; % N:������

    r1 = 10; % Ǳ���ڻ���ÿ��Ӵ�������
    r2 = 10; %��Ⱦ��ÿ��Ӵ�������
    p1 = 0.05; % p1:Ǳ���ڻ��߽Ӵ����Ⱦ�ĸ���
    p2 = 0.05; % p2:��Ⱦ�߽Ӵ����Ⱦ�ĸ���
    a = 0.07; % a:1/14Ǳ���ڻ��߳���֢״�ĸ���

    % ----------���������̬����----------
    axes(handles.axes_main); cla;
    Menus = [handles.Menu_r1, handles.Menu_r2]; dyparams = [r1, r2];
    for k = 1:2
        index = get(Menus(k), 'Value');
        switch index
            case 2
                dyparams(k) = 30;
            case 3
                dyparams(k) = 20;
            case 4
                dyparams(k) = 10;
            case 5
                dyparams(k) = 5;
            case 6
                dyparams(k) = 0;
        end
    end
    r1 = dyparams(1); r2 = dyparams(2);
    Menus = [handles.Menu_p1, handles.Menu_p2]; dyparams = [p1, p2];
    for k = 1:2
        index = get(Menus(k), 'Value');
        switch index
            case 2
                dyparams(k) = 0.15;
            case 3
                dyparams(k) = 0.05;
            case 4
                dyparams(k) = 0.005;
        end
    end
    p1 = dyparams(1); p2 = dyparams(2);
    % ----------����ģ�ͽ���Ԥ��----------
    Days = 100;
    for k = 1:Days
        S(k + 1) = S(k) - (r1 * p1 * E(k) * (S(k) / N(k)) + r2 * p2 * I(k) * (S(k) / N(k)));
        E(k + 1) = E(k) + (r1 * p1 * E(k) * (S(k) / N(k)) + r2 * p2 * I(k) * (S(k) / N(k))) - (E(k) * a);
        I(k + 1) = I(k) + (E(k) * a) - (I(k) * r + I(k) * d);
        R(k + 1) = R(k) + I(k) * r;
        N(k + 1) = S(k + 1) + E(k + 1) + I(k + 1) + R(k + 1);
    end

    % ----------����ģ�͵�Ԥ����----------
    x = 1:Days + 1;
    plot(x, S, x, E, '-o', x, I, '-*', x, R); grid on
    xlabel('����'); ylabel('����')
    legend('�׸���', 'Ǳ����', '��Ⱦ��', '������')

    % ----------Ԥ��������----------
    handles.XX = x;
    handles.SS = S;
    handles.II = I;
    handles.RR = R;
    handles.NN = N;
    guidata(hObject, handles)

% ----------���������----------
function Button_error_Callback(~, ~, handles)
    axes(handles.axes_main); cla;
    x = handles.XX; I = handles.II; true_patient = handles.true_patient;
    error = 0.5 * (true_patient(1:length(I)) - I');
    plot(x, true_patient(1:length(I)), '-.'); hold on;
    plot(x, I, '-*');
    errorbar(x, I, error, 'k'); grid on; hold off;
    legend('ʵ�ʸ�Ⱦ����', '�����Ⱦ����', '�����')

    
% -------------------------!����2����̬���滭ͼ!-------------------------%
% ----------�����빦��1���ƣ����ӱ����붯ͼ��ʾ��������������----------
% -------------------------!����3��Excel���ݹ۲�!-------------------------%
% --- Executes on selection change in Menu_excelpic.
function Menu_excelpic_Callback(~, ~, handles)
    axes(handles.Axes_excel)
    h2 = plot(handles.data(:, 2)); hold on; set(h2, 'Visible', 'off')
    h3 = plot(handles.data(:, 4)); set(h3, 'Visible', 'off')
    h4 = plot(handles.data(:, 5)); set(h4, 'Visible', 'off')
    h5 = plot(handles.data(:, 2) - handles.data(:, 4) - handles.data(:, 5)); set(h5, 'Visible', 'off')
    hold off; xlabel('����'); ylabel('����');
    index = get(handles.Menu_excelpic, 'Value');

    switch index
        case 2
            set(h2, 'Visible', 'on'); legend('�ۼ�ȷ������')
        case 3
            set(h3, 'Visible', 'on'); legend('�ۼ���������')
        case 4
            set(h4, 'Visible', 'on'); legend('�ۼƿ�������')
        case 5
            set(h5, 'Visible', 'on'); legend('�ִ�ȷ������')
        case 6
            set([h2, h3, h4, h5], 'Visible', 'on');
            legend('�ۼ�ȷ������', '�ۼ���������', '�ۼ���������', '�ִ�ȷ������')
    end

    
% -------------------------!����4��������ӻ���ʾ!-------------------------%
% --- Executes on selection change in Menu_ppt.
function Menu_ppt_Callback(~, ~, handles)
    axes(handles.Axes_ppt)
    index = get(handles.Menu_ppt, 'Value');
    h1 = scatter([], [], 'r', 'filled'); hold on; h2 = scatter([], [], 'g', 'filled');
    h3 = scatter([], []); hold off; h4 = text(50, 50, '', 'fontsize', 20, 'HorizontalAlignment', 'center');

    switch index
            case 2
            % ----------Excel�������鴫����ʾ----------
            N = 50e4; I = handles.data(:, 2) - handles.data(:, 4) - handles.data(:, 5); R = handles.data(:, 5);
            maxindex = find(I == max(I)); Step = 10; Decline = N / 1000;

            for k = 1:Step:length(I)
                num = round(I(k) / Decline);
                X1 = 100 * rand(1, num); Y1 = 100 * rand(1, num);
                set(h1, 'XData', X1, 'YData', Y1')
                num = round(R(k) / Decline);
                X2 = 100 * rand(1, num); Y2 = 100 * rand(1, num);
                set(h2, 'XData', X2, 'YData', Y2);
                num = round((N - I(k) - R(k)) / Decline);
                X3 = 100 * rand(1, num); Y3 = 100 * rand(1, num);
                set(h3, 'XData', X3, 'YData', Y3)
                legend([h1, h2, h3], '�ִ��Ⱦ��', '������', '�׸���')
                if abs(k -maxindex) < floor(Step / 2) + 1
                    set(h4, 'String', '����߳�'); pause(1.5);
                    set(h4, 'String', '')
                end
                pause(0.5)
            end
            set(h4, 'String', '��ʾ����')
            case 3
            % ----------�����������鴫����ʾ----------
            N = handles.NN; R = handles.RR; I = handles.II;
            maxindex = find(I == max(I)); Step = 10; Decline = max(N) / 1000;
            for k = 1:Step:length(I)
                num = round(I(k) / Decline);
                X1 = 100 * rand(1, num); Y1 = 100 * rand(1, num);
                set(h1, 'XData', X1, 'YData', Y1')
                num = round(R(k) / Decline);
                X2 = 100 * rand(1, num); Y2 = 100 * rand(1, num);
                set(h2, 'XData', X2, 'YData', Y2);
                num = round((N(k) - I(k) - R(k)) / Decline);
                X3 = 100 * rand(1, num); Y3 = 100 * rand(1, num);
                set(h3, 'XData', X3, 'YData', Y3)
                legend([h1, h2, h3], '�ִ��Ⱦ��', '������', '�׸���')
                if abs(k -maxindex) < floor(Step / 2) + 1
                    set(h4, 'String', '����߳�'); pause(1.5);
                    set(h4, 'String', '')
                end
                pause(0.5)
            end
            set(h4, 'String', '��ʾ����')
    end

% -------------------------!�˳�����ϵͳ!-------------------------%
function Button_exit_Callback(~, ~, ~)
    clc; clear; close(gcf);
% -------------------------!����Ϊϵͳ���Ĵ�����-------------------------%





% -------------------------!����Ϊϵͳ���������-------------------------%
% -------------------------!����2����̬���滭ͼ!-------------------------%
function Button_dynamic_Callback(~, ~, handles)
    % ----------������ϻ�ȡr����----------
    [xData, yData] = prepareCurveData(handles.pat_infected, handles.pat_recover);
    ft = fittype('poly1');
    [fitresult, ~] = fit(xData, yData, ft);
    r = fitresult.p1; %��ϻ�õĻ��߿����ĸ���
    % ----------������ϻ�ȡd����----------
    [xData, yData] = prepareCurveData(handles.pat_infected, handles.pat_died);
    ft = fittype('poly1');
    [fitresult, ~] = fit(xData, yData, ft);
    d = fitresult.p1; %��ϻ�õĻ��������ĸ���

    % ----------����������úͳ�ʼ��״̬----------
    S = 50e4; % S:�׸���Ⱥ����
    E = 111; % E:Ǳ���ڻ���
    I = 270; % I:��Ⱦ��
    R = 25; % R:������
    N = S + E + I + R; % N:������

    % ----------����ģ�ͽ���Ԥ��----------
    axes(handles.Axes_dynamic)
    h1 = plot(0, 0); hold on;
    h2 = plot(0, 0, '-o'); h3 = plot(0, 0, '-*'); h4 = plot([0], [0]); hold off; grid on
    h5 = title('');
    set(get(gca, 'XLabel'), 'String', '����');
    set(get(gca, 'YLabel'), 'String', '����');

    Days = 150; params = [10, 10, 0.05, 0.05];
    a = 0.07; % a:Ǳ���ڻ��߳���֢״�ĸ���
    index = get(handles.Menuparams, 'Value');

    for temp = handles.valstart:handles.valstep:handles.valend
        params(index - 1) = temp;

        for k = 1:Days
            S(k + 1) = S(k) - (params(1) * params(3) * E(k) * (S(k) / N(k)) + params(2) * params(4) * I(k) * (S(k) / N(k)));
            E(k + 1) = E(k) + (params(1) * params(3) * E(k) * (S(k) / N(k)) + params(2) * params(4) * I(k) * (S(k) / N(k))) - (E(k) * a);
            I(k + 1) = I(k) + (E(k) * a) - (I(k) * r + I(k) * d);
            R(k + 1) = R(k) + I(k) * r;
            N(k + 1) = S(k + 1) + E(k + 1) + I(k + 1) + R(k + 1);
        end

        % ----------����ģ�͵�Ԥ����----------
        x = 1:Days + 1;
        set(h1, 'XData', x, 'YData', S); set(h2, 'XData', x, 'YData', E);
        set(h3, 'XData', x, 'YData', I); set(h4, 'XData', x, 'YData', R);
        legend('�׸���', 'Ǳ����', '��Ⱦ��', '������'); set(h5, 'String', ['variable:', num2str(temp)]);
        pause(0.7)
    end

    
% -------------------------!GUI�Զ���ȡ�����ļ�!-------------------------%
% --- Executes on button press in Button_autodata.
function Button_autodata_Callback(hObject, ~, handles)
    try
        set(handles.fileshow, 'string', '����ʡ�¹�״��������.xls');
        h = waitbar(0, '���Եȣ����ڿ�ʼ��ȡ�ļ���');
        [data, ~, ~] = xlsread('.\data\����ʡ�¹�״��������.xls');
        pause(0.5);
        waitbar(1, h, '�ļ���ȡ�����');
        assignin('base', 'data', data);
        handles.data = data;
        Tstart = 1; Tend = 56; data(isnan(data)) = 0;
        handles.pat_infected = data(Tstart:Tend, 2);
        handles.pat_died = data(Tstart:Tend, 4);
        handles.pat_recover = data(Tstart:Tend, 5);
        handles.true_patient = data(:, 2) -data(:, 4) - data(:, 5);
        waitbar(1, h, '���ݵ��������');
        guidata(hObject, handles);
        delete(h);
    catch
        disp('�Զ���ȡʧ�ܣ�����ͬĿ¼�ļ��·��������ļ�->�ر�excel/���comռ��->����Matlab')
        return
    end


% -------------------------!����Ϊ������ʾ�ؼ�-------------------------%
% ----------���ܰ�ť��---------
function uibuttongroups_CreateFcn(~, ~, ~)
function uibuttongroups_SelectionChangedFcn(hObject, ~, handles)
    str = get(hObject, 'string'); %�����ź�˫���Ų��ܹ���
    H = [handles.panel_static, handles.panel_dynamic, handles.panel_excel, handles.panel_ppt];
    switch str
            case '���ٷ���'
            index = 1;
            case '��̬����'
            index = 2;
            case '������ͼ'
            index = 3;
            case '������ʾ'
            index = 4;
    end
    for k = 1:4
        set(H(k), 'Visible', 'off')
        if k == index
            set(H(k), 'Visible', 'on')
        end
    end

% ----------���ÿ��ٷ������---------
function Button_update_CreateFcn(~, ~, ~)
    % --- Executes on button press in Button_defaultstatic.
function Button_defaultstatic_Callback(~, ~, handles)
    set(handles.Menu_r1, 'Value', 4);
    set(handles.Menu_r2, 'Value', 4);
    set(handles.Menu_p1, 'Value', 3);
    set(handles.Menu_p2, 'Value', 3); axes(handles.axes_main); cla;

function Menu_r1_Callback(~, ~, ~)
function Menu_r1_CreateFcn(hObject, ~, ~)

    if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
        set(hObject, 'BackgroundColor', 'white');
    end

    set(hObject, 'String', {'r1:Ǳ���߽Ӵ���/��', 'r1=30', 'r1=20', 'r1=10', 'r1=5', 'r1=0'});

function Menu_r2_Callback(~, ~, ~)
function Menu_r2_CreateFcn(hObject, ~, ~)
    if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
        set(hObject, 'BackgroundColor', 'white');
    end
    set(hObject, 'String', {'r2:��Ⱦ�߽Ӵ���/��', 'r2=30', 'r2=20', 'r2=10', 'r2=5', 'r2=0'});

function Menu_p1_Callback(~, ~, ~)
function Menu_p1_CreateFcn(hObject, ~, ~)
    if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
        set(hObject, 'BackgroundColor', 'white');
    end
    set(hObject, 'String', {'p1:Ǳ���߽Ӵ��󷢲���', 'p1=0.15', 'p1=0.05', 'p1=0.005'})

function Menu_p2_Callback(~, ~, ~)
function Menu_p2_CreateFcn(hObject, ~, ~)
    if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
        set(hObject, 'BackgroundColor', 'white');
    end
    set(hObject, 'String', {'p2:��Ⱦ�߽Ӵ��󷢲���', 'p2=0.15', 'p2=0.05', 'p2=0.005'});

function radio_dynamic_Callback(~, ~, ~)
function edit_step_CreateFcn(hObject, ~, ~)
    if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
        set(hObject, 'BackgroundColor', 'white');
    end


% ----------���ö�̬�仯����---------
function panel_dynamic_CreateFcn(~, ~, ~)
    % --- Executes on button press in Button_defaultdynamic.
function Button_defaultdynamic_Callback(hObject, ~, handles)
    set(handles.Menuparams, 'Value', 2);
    set(handles.editstart, 'String', 1); handles.valstart = 1;
    set(handles.editend, 'String', 10); handles.valend = 10;
    set(handles.editstep, 'String', 1); handles.valstep = 1;
    guidata(hObject, handles); axes(handles.Axes_dynamic); cla;

function Menuparams_Callback(~, ~, ~)
function Menuparams_CreateFcn(hObject, ~, ~)
    if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
        set(hObject, 'BackgroundColor', 'white');
    end
    set(hObject, 'String', {'ѡ��̬���ԵĲ���', 'r1', 'r2', 'p1', 'p2'});

function text_start_CreateFcn(~, ~, ~)
function text_end_CreateFcn(~, ~, ~)
function text_step_CreateFcn(~, ~, ~)

function editstart_Callback(hObject, ~, handles)
    str = get(hObject, 'String');
    handles.valstart = str2double(str);
    guidata(hObject, handles)

function editstart_CreateFcn(hObject, ~, ~)
    if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
        set(hObject, 'BackgroundColor', 'white');
    end

function editend_Callback(hObject, ~, handles)
    str = get(hObject, 'String');
    handles.valend = str2double(str);
    guidata(hObject, handles);
function editend_CreateFcn(hObject, ~, ~)
    if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
        set(hObject, 'BackgroundColor', 'white');
    end

function editstep_Callback(hObject, ~, handles)
    str = get(hObject, 'String');
    handles.valstep = str2double(str);
    guidata(hObject, handles);
function editstep_CreateFcn(hObject, ~, ~)
    if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
        set(hObject, 'BackgroundColor', 'white');
    end

% ----------��ʾѡ��Excel����---------
function Menu_excelpic_CreateFcn(hObject, ~, ~)
    if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
        set(hObject, 'BackgroundColor', 'white');
    end
    set(hObject, 'String', {'���ݶ���', '�ۼ�ȷ������', '�ۼ���������', '�ۼƿ�������', '�ִ�ȷ������', 'ȫ����ʾ'})

% ----------��ʾ���鶯̬���ӻ�---------
function Menu_ppt_CreateFcn(hObject, ~, ~)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
    set(hObject, 'String', {'��ʾ����','��ʵ����','��������(������Դ�ڿ��ٷ���'})

% ----------�ļ���ȡ���ӻ�---------
function filemenu_Callback(~, ~, ~)
function fileshow_CreateFcn(hObject, ~, ~)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

% ----------�򵥵Ĳ˵�������---------
function file_exit_Callback(~, ~, ~)
    clc;clear;close(gcf);
function helpmenu_Callback(~, ~, ~)
function readme_Callback(~, ~, ~)
