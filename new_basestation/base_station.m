%==========================================================================
% INITIALIZATION CODE
%==========================================================================


function varargout = base_station(varargin)
% BASE_STATION MATLAB code for base_station.fig
%      BASE_STATION, by itself, creates a new BASE_STATION or raises the existing
%      singleton*.
%
%      H = BASE_STATION returns the handle to a new BASE_STATION or the handle to
%      the existing singleton*.
%v
%      BASE_STATION('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BASE_STATION.M with the given input arguments.
%
%      BASE_STATION('Property','Value',...) creates a new BASE_STATION or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GU]I before base_station_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to base_station_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help base_station

% Last Modified by GUIDE v2.5 05-May-2018 11:56:20

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @base_station_OpeningFcn, ...
                   'gui_OutputFcn',  @base_station_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
end
% End initialization code - DO NOT EDIT

%==========================================================================
% VARIABLES AND CONSTANTS
%==========================================================================

% MATLAB sucks.
function initVarsAndConstants(handles1)
    global handles;
    global boatMode;
    global boatPos;
    global boatTransform;
    global windVec;
    global sailDir;
    global tailDir;
    
    global wayPoints;
    global buoyPoints;
    
    global pastTransforms;
    global drawScale;
    
    global DIR_LINE_LENGTH;
    global WIND_VEC_SCALE;
        
    global sendingData;
    global lastSendTime;
    
    handles = handles1;
    
    boatMode = 1;
    boatPos = [30 30];
    boatTransform = [1 0 0; 0 1 0; 30 30 1];
    windVec = [10 30];
    sailDir = [1 -.4];
    tailDir = [-.6 1];
    wayPoints = [325 58; -56 233];
    buoyPoints = [78 97; 253 75];
    
    drawScale = 1;
    
    lat = 42.4441;
    
    pastTransforms = [1 0 0; 0 1 0; 0 0 1];
    for i = 1:5
        pastTransforms(:, :, i) = [1 0 0; 0 1 0; 0 0 1];
    end
    
    DIR_LINE_LENGTH = 40;
    WIND_VEC_SCALE = 2;
    
    sendingData = false;
    lastSendTime = 0;
end

%==========================================================================
% FUNCTIONS
%==========================================================================

function drawTextureAt(path, transform)
    global handles;
    global drawScale;

    [im, map, alpha] = imread(path);
    %imshow(A, 'Parent', handles.CanvasAxes);
    
    [sizeX, sizeY, ~] = size(im);
    
    tx = -sizeX/2 - .5;
    ty = -sizeY/2 - .5;
    
    xl = xlim;
    yl = ylim;
    sx = (xl(2) - xl(1))/494;
    sy = (yl(2) - yl(1))/494;
        
    firstTranslate = [1 0 0; 0 1 0; ty tx 1];  % ty and tx are flipped in matrix dims
    scaling = [drawScale 0 0; 0 drawScale 0; 0 0 1];
    %rotate = [1 0 0; 0 1 0; 0 0 1];
    %lastTranslate = [1 0 0; 0 1 0; 30 30 1];
    tform = affine2d(firstTranslate * scaling * transform);
    [im, imRef] = imwarp(im, tform);
    alpha = imwarp(alpha, tform);
    
    %axes(handles.CanvasAxes);
    image = imshow(im, imRef, 'Parent', handles.CanvasAxes);
    image.AlphaData = alpha;
end

function drawVector(origin, vec, flags)
    global handles;
    x1 = origin(1);
    y1 = origin(2);
    plot(handles.CanvasAxes, [x1 x1+vec(1)], [y1 y1+vec(2)], flags);
end

%==========================================================================
% PUBLIC FUNCTIONS
%==========================================================================

function rotate = createRotZ(angle)
    rotate = [cos(angle) -sin(angle) 0; sin(angle) cos(angle) 0; 0 0 1];
end

function translate = createTranslation(pos)
    translate = [1 0 0; 0 1 0; pos(1) pos(2) 1];
end

function vec = angleToVec(angle)
    vec = [cos(angle) sin(angle)];
end

function updateFromData(data)
    global boatPos;
    global boatTransform;
    global windVec;
    global sailDir;
    global tailDir;
    
    global wayPoints;
    global buoyPoints;
    
    global pastTransforms;
    
    rotation = createRotZ(-data.boat_heading + pi/2);
    translate = createTranslation(data.position);
    
    for page = 1:size(pastTransforms, 3)-1
        pastTransforms(:, :, page+1) = pastTransforms(:, :, page);
    end
    pastTransforms(:, :, 1) = boatTransform;
    
    boatPos = data.position;
    boatTransform = rotation * translate;
    %windVec = angleToVec(data.wind(1)) * data.wind(2);
    %sailDir = angleToVec(data.sail_angle);
    %tailDir = angleToVec(data.tail_angle);
end

function updateCanvas()
    global serialPort;
    global handles;

    global boatMode;
    global boatPos;
    global boatTransform;
    global windVec;
    global sailDir;
    global tailDir;
    
    global wayPoints;
    global buoyPoints;
    
    global pastTransforms;
    global drawScale;
    global DIR_LINE_LENGTH;
    global WIND_VEC_SCALE;
        
    %axes(handles.CanvasAxes);
    cla(handles.CanvasAxes);
    
    %disp(handles.CanvasAxes);
    
    minX = realmax('single');
    maxX = -realmax('single');
    minY = realmax('single');
    maxY = -realmax('single');
    points = cat(1, wayPoints, buoyPoints, boatPos);
    for row = 1:size(points, 1)
        point = points(row, :);
        x = point(1);
        y = point(2);
        if (x < minX)
            minX = x;
        end
        if (x > maxX)
            maxX = x;
        end
        if (y < minY)
            minY = y;
        end
        if (y > maxY)
            maxY = y;
        end
    end
    
    %paddingX = (maxX - minX) * 1.1;
    %paddingY = (maxY - minY) * 1.1;
    %paddingX = 0;
    %paddingY = 0;
    %xlim([minX-paddingX maxX+paddingX]);
    %ylim([minY-paddingY maxY+paddingY]);
    
    distX = maxX - minX;
    distY = maxY - minY;
    midX = distX/2 + minX;
    midY = distY/2 + minY;
    maxDist = max(distX, distY);
    padding = maxDist * 1.14;
    if (padding == 0)
        padding = 1000;
    end
    
    xlim(handles.CanvasAxes, [midX-padding/2 midX+padding/2]);
    ylim(handles.CanvasAxes, [midY-padding/2 midY+padding/2]);
    
    drawScale = padding/494;
    
    %disp(boatTransform)
    drawTextureAt('Boat.png', boatTransform);
%     drawVector(boatPos, windVec * WIND_VEC_SCALE * drawScale, 'k');
%     drawVector(boatPos, sailDir * DIR_LINE_LENGTH * drawScale, '--r');
%     drawVector(boatPos, tailDir * DIR_LINE_LENGTH * drawScale, '--b');
%     
%     for row = 1:size(wayPoints, 1)
%         point = wayPoints(row, :);
%         drawTextureAt('Waypoint.png', createTranslation(point));
%     end
%     
%     for row = 1:size(buoyPoints, 1)
%         point = buoyPoints(row, :);
%         drawTextureAt('Buoy.png', createTranslation(point));
%     end
%     
%     for page = 1:size(pastTransforms, 3)
%         transform = pastTransforms(:, :, page);
%         drawTextureAt('PastPoint.png', transform);
%     end
end

function str = formatPoint(pt)
    str = string(sprintf('(%.0f, %.0f)', pt(1), pt(2)));
end

function updateWaypointList()
    global handles;
    global wayPoints;
    
    numPoints = size(wayPoints, 1);
    stringVec = [];

    for row = 1:numPoints
        stringVec = [stringVec; formatPoint(wayPoints(row, :))];
    end
    
    handles.WaypointList.String = stringVec;
end

function updateBuoyList()
    global handles;
    global buoyPoints;
    
    numPoints = size(buoyPoints, 1);
    stringVec = [];

    for row = 1:numPoints
        stringVec = [stringVec; formatPoint(buoyPoints(row, :))];
    end
    
    handles.BuoyList.String = stringVec;
end

function updateAll()
    updateCanvas();
    updateWaypointList();
    updateBuoyList();
end


%==========================================================================
% EVENT HANDLERS
%==========================================================================

% --- Executes just before base_station is made visible.
function base_station_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to base_station (see VARARGIN)

    % Choose default command line output for base_station
    handles.output = hObject;
    
    handles.timer = timer(...
    'ExecutionMode', 'fixedRate', ...       % Run timer repeatedly
    'Period', .5, ...                        % Initial period is 1 sec.
    'TimerFcn', {@update_display,hObject}); % Specify callback function


    % Update handles structure
    guidata(hObject, handles);

    % UIWAIT makes base_station wait for user response (see UIRESUME)
    % uiwait(handles.figure1);
    
    initVarsAndConstants(handles);
    updateAll();
    start(handles.timer);
end


% --- Outputs from this function are returned to the command line.
function varargout = base_station_OutputFcn(hObject, eventdata, handles) 
    % varargout  cell array for returning output args (see VARARGOUT);
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Get default command line output from handles structure
    varargout{1} = handles.output;
end


% --- Executes on selection change in ModeSelect.
function ModeSelect_Callback(hObject, eventdata, handles)
% hObject    handle to ModeSelect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ModeSelect contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ModeSelect
% handles    structure with handles and user data (see GUIDATA)
    global boatMode;
    
    boatMode = hObject.Value;

    data = containers.Map({
        'command', 'mission_number'
    }, {
        0, boatMode
    });

    send_data(data);
end


% --- Executes during object creation, after setting all properties.
function ModeSelect_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to ModeSelect (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end



function WaypointIn_Callback(hObject, eventdata, handles)
    % hObject    handle to WaypointIn (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: get(hObject,'String') returns contents of WaypointIn as text
    %        str2double(get(hObject,'String')) returns contents of WaypointIn as a double
end


% --- Executes during object creation, after setting all properties.
function WaypointIn_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to WaypointIn (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end


% --- Executes on selection change in WaypointList.
function WaypointList_Callback(hObject, eventdata, handles)
% hObject    handle to WaypointList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns WaypointList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from WaypointList
    lastValue = getappdata(hObject, 'lastValue');
    disp(lastValue);
    %disp(hObject.Value);
end


% --- Executes during object creation, after setting all properties.
function WaypointList_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to WaypointList (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: listbox controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end


% --- Executes on button press in WaypointAdd.
function WaypointAdd_Callback(hObject, eventdata, handles)
% hObject    handle to WaypointAdd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    global wayPoints;
    
    inString = char(handles.WaypointIn.String);
    inString = erase(inString, '(');
    inString = erase(inString, ')');
    
    [pt, success] = str2num(inString);
    if (success == 0)
        return;
    end
    
    wayPoints = [wayPoints; pt];
    
    updateWaypointList();
    updateCanvas();
end


% --- Executes on button press in WaypointUp.
function WaypointUp_Callback(hObject, eventdata, handles)
% hObject    handle to WaypointUp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    global wayPoints;
    
    selIndex = handles.WaypointList.Value;
    if (selIndex <= 1)
        return;
    end
    
    temp = wayPoints(selIndex, :);
    wayPoints(selIndex, :) = wayPoints(selIndex-1, :);
    wayPoints(selIndex-1, :) = temp;
    
    handles.WaypointList.Value = selIndex-1;
    
    updateWaypointList();
    updateCanvas();
end


% --- Executes on button press in WaypointDown.
function WaypointDown_Callback(hObject, eventdata, handles)
% hObject    handle to WaypointDown (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    global wayPoints;
    
    selIndex = handles.WaypointList.Value;
    if (selIndex >= size(wayPoints, 1))
        return;
    end
    
    temp = wayPoints(selIndex, :);
    wayPoints(selIndex, :) = wayPoints(selIndex+1, :);
    wayPoints(selIndex+1, :) = temp;
    
    handles.WaypointList.Value = selIndex+1;
    
    updateWaypointList();
    updateCanvas();
end


% --- Executes on button press in BuoyDown.
function BuoyDown_Callback(hObject, eventdata, handles)
% hObject    handle to BuoyDown (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    global buoyPoints;
    
    selIndex = handles.BuoyList.Value;
    if (selIndex >= size(buoyPoints, 1))
        return;
    end
    
    temp = buoyPoints(selIndex, :);
    buoyPoints(selIndex, :) = buoyPoints(selIndex+1, :);
    buoyPoints(selIndex+1, :) = temp;
    
    handles.BuoyList.Value = selIndex+1;
    
    updateBuoyList();
    updateCanvas();
end


% --- Executes on button press in BuoyUp.
function BuoyUp_Callback(hObject, eventdata, handles)
% hObject    handle to BuoyUp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    global buoyPoints;
    
    selIndex = handles.BuoyList.Value;
    if (selIndex <= 1)
        return;
    end
    
    temp = buoyPoints(selIndex, :);
    buoyPoints(selIndex, :) = buoyPoints(selIndex-1, :);
    buoyPoints(selIndex-1, :) = temp;
    
    handles.BuoyList.Value = selIndex-1;
    
    updateBuoyList();
    updateCanvas();
end


% --- Executes on button press in BuoyAdd.
function BuoyAdd_Callback(hObject, eventdata, handles)
% hObject    handle to BuoyAdd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    global buoyPoints;
    
    inString = char(handles.BuoyIn.String);
    inString = erase(inString, '(');
    inString = erase(inString, ')');
    
    [pt, success] = str2num(inString);
    if (success == 0)
        return;
    end
    
    buoyPoints = [buoyPoints; pt];
    updateBuoyList();
    updateCanvas();
end


% --- Executes on selection change in BuoyList.
function BuoyList_Callback(hObject, eventdata, handles)
% hObject    handle to BuoyList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns BuoyList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from BuoyList
end


% --- Executes during object creation, after setting all properties.
function BuoyList_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to BuoyList (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: listbox controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end



function BuoyIn_Callback(hObject, eventdata, handles)
% hObject    handle to BuoyIn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of BuoyIn as text
%        str2double(get(hObject,'String')) returns contents of BuoyIn as a double
end


% --- Executes during object creation, after setting all properties.
function BuoyIn_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BuoyIn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end
end


% --- Executes on button press in DeleteButton.
function DeleteButton_Callback(hObject, eventdata, handles)
% hObject    handle to DeleteButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end

% --- Executes on button press in SendButton.
function SendButton_Callback(hObject, eventdata, handles)
% hObject    handle to SendButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global wayPoints;
    
    data = containers.Map({
        'command', 'waypoints'
    }, {
        1, wayPoints
    });

    send_data(data);
end


% --- Executes on button press in WaypointRemove.
function WaypointRemove_Callback(hObject, eventdata, handles)
% hObject    handle to WaypointRemove (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    global wayPoints;
    
    selIndex = handles.WaypointList.Value;
    wayPoints(selIndex, :) = [];
    
    if (selIndex > 1)
        handles.WaypointList.Value = selIndex - 1;
    end
    
    updateWaypointList();
    updateCanvas();
end


% --- Executes on button press in BuoyRemove.
function BuoyRemove_Callback(hObject, eventdata, handles)
% hObject    handle to BuoyRemove (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

    global buoyPoints;
    
    selIndex = handles.BuoyList.Value;
    buoyPoints(selIndex, :) = [];
    
    if (selIndex > 1)
        handles.BuoyList.Value = selIndex - 1;
    end
    
    updateBuoyList();
    updateCanvas();
end

function disableSendButton()
    global handles;
    handles.SendButton.String = "Sending...";
    handles.SendButton.Enable = 'off';
    handles.ModeSelect.Enable = 'off';
end

function enableSendButton()
    global handles;
    handles.SendButton.String = "Send to Boat";
    handles.SendButton.Enable = 'on';
    handles.ModeSelect.Enable = 'on';
end

function send_data(data)
    global serialPort;
    global sendingData;
    global lastSendTime;
    
    serialized = jsonencode(data);
    serialized = serialized(2:end-1);
    %fwrite(serialPort, serialized);
    disp(serialized);
    
    %flushinput(serialPort);
    %flushoutput(serialPort);
    
    disableSendButton();
    
    sendingData = true;
    lastSendTime = cputime;
end

function get = scale(x,xprev)
    get = (abs(x - xprev))*10000;
end

% Timer timer1 callback, called each time timer iterates.
function update_display(hObject,eventdata,hfigure)
    global serialPort;

    global sendingData;
    global lastSendTime;

    serialPort = serial('COM5', 'BaudRate', 9600, 'Terminator', 'CR', 'StopBit', 1, 'Parity', 'None');
    %fopen(serialPort);

    % Read everything available in serialPort
    %recvData = "";
    recvData = [];
    while (serialPort.BytesAvailable > 0)
        recvData = [recvData, fscanf(serialPort)];
    end

    % Check for boat ACK if sending data
    if (sendingData)
        pattern = "ACK";
        allRecvData = strcat(recvData);
        if (contains(allRecvData, pattern) == 1)
            disp('Boat successfully received data.');
            sendingData = false;
            enableSendButton();
        else
            if (cputime - lastSendTime > 1)
                warning('Failed to recieve ACK from boat.');
                sendingData = false;
                enableSendButton();
            end
        end
    end

    lat = 0;
    lon = 0;
    dir = 0;
    
    line = recvData(1);
    if (length(line) < 10 && strcmp(line(2:9), 'Latitude'))
        lat = str2double(line(12:end)); %convert latitude from string to double and saves it in a variable
        disp('X')
    else
        return;
    end
    
    line = recvData(2);
    if (length(line) < 10 && strcmp(line(2:10), 'Longitude'))  
        lon = str2double(line(13:end));
        disp('Y')
    else
        return;
    end
    
    line = recvData(3);
    if (length(line) < 10 && strcmp(line(2:5), 'Boat'))
        dir = str2double(line(18:end));
        disp('C')
    else
        return;
    end

    drawData = containers.Map({
        'position', 'boat_heading'
    }, {
        [lat lon], dir
    });
    updateFromData(drawData);

    %pause(2);%Allow the graph to be draw
    fclose(serialPort);

    updateCanvas();
end


% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
global serialPort;

%fclose(serialPort);
delete(hObject);
end
