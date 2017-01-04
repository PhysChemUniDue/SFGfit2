function SFGfit2()
% 
%
%   Open a GUI for batch-fitting spectra
%

% Data is shared between all child functions by declaring the variables
% here (they become global to the function). We keep things tidy by putting
% all GUI stuff in one structure and all data stuff in another. As the app
% grows, we might consider making these objects rather than structures.
data = createData(  );
gui = createInterface(  );

% Now update the GUI with the current data
updateInterface();

%-------------------------------------------------------------------------%
    function data = createData()
        % Add folders to search path
        addpath([pwd,'/layout'], [pwd,'/data'], ...
            [pwd,'/settings'], [pwd,'/functions'])
        % Get the system defined monospaced font
        data.MonoFont = get(0, 'FixedWidthFontName');
        
        % Create empty data set
        data.spectraData.DataSet = struct([]);
        
        % Create empty FID data set
        data.FID = struct([]);
        
        % Entry for remembering the last folder that was selected
        data.lastFolder = [pwd,'/'];
        
        % Print output to command window?
        data.doPrint = true;
        
        % Add smoothed line to spectrum
        data.smoothed = false;
        
        % Define Laser bandwidth
        data.laserBandwidth = 4.5;
        
        % Load Default settings if exist
        if exist( 'settings/defaultParameters.mat', 'file' )
            
            % Load the data
            parameters = load( 'settings/defaultParameters.mat' );
            
            % Add to data struct
            data.parameters = parameters.parameters;
            
        end
        
        
        % Settings
        data.fitModel = 'Offset + abs(NR+A01./(w01-x-1i*G01)+A02./(w02-x-1i*G02)+A03./(w03-x-1i*G03)+A04./(w04-x-1i*G04)+A05./(w05-x-1i*G05)).^2';
        data.numPeaks = 5;
        
        % Configure fit options
        data.fitOpts = fitoptions( 'Method', 'NonlinearLeastSquares' );
        data.fitOpts.Robust = 'Bisquare';
        data.fitOpts.Algorithm = 'Trust-Region';
        data.fitOpts.DiffMaxChange = 10e-6;
        data.fitOpts.DiffMinChange = 10e-8;
        data.fitOpts.Display = 'notify';
        data.fitOpts.MaxFunEvals = 1e8;
        data.fitOpts.MaxIter = 1e5;
        data.fitOpts.TolFun = 1e-6;
        data.fitOpts.TolX = 1e-6;
        
    end % Create Data

%-------------------------------------------------------------------------%
    function gui = createInterface()
        % Create the user interface for the application and return a
        % structure of handles for global use.
        gui = struct();
        % Open a window and add some menus
        gui.Window = figure( ...
            'Name', 'SFG fit', ...
            'NumberTitle', 'off', ...
            'MenuBar', 'none', ...
            'Toolbar', 'figure', ...
            'HandleVisibility', 'off', ...
            'Position', [200, 200, 1200, 400] );
        
        % + File menu
        gui.FileMenu = uimenu( gui.Window, 'Label', 'File' );
        uimenu( gui.FileMenu, 'Label', 'Load Data Set ...', ...
            'Callback', @onLoadData );
        uimenu( gui.FileMenu, 'Label', 'Save Data Set ...', ...
            'Callback', @onSaveData );
        gui.ImportMenu = uimenu( gui.FileMenu, 'Label', 'Import', ...
            'Separator', 'on' );
            uimenu( gui.ImportMenu, 'Label', 'Process ITX Files ...', ...
                'Callback', @onProcessITX );
        uimenu( gui.FileMenu, 'Label', 'Edit Settings ...', ...
            'Separator', 'on', 'Callback', @onEditSettings );
        uimenu( gui.FileMenu, 'Label', 'Load Settings ...', ...
            'Callback', @onLoadSettings );
        uimenu( gui.FileMenu, 'Label', 'Remove Selected', ...
            'Separator', 'on', 'Callback', @onRemoveSelected );
        uimenu( gui.FileMenu, 'Label', 'Clear Data', ...
            'Separator', 'off', 'Callback', @onClearData );
        uimenu( gui.FileMenu, 'Label', 'Exit', ...
            'Separator', 'off', 'Callback', @onExit );
        
        % + Fit Menu
        gui.FitMenu = uimenu ( gui.Window, 'Label', 'Fit' );
        uimenu( gui.FitMenu, 'Label', 'Single Fit', ...
            'Callback', @onSingleFit );
        uimenu( gui.FitMenu, 'Label', 'Batch Fit', ...
            'Callback', @onBatchFit );
        uimenu( gui.FitMenu, 'Label', 'Save Fit Parameters ...', ...
            'Separator', 'on', 'Callback', @onSaveFitParameters );
        uimenu( gui.FitMenu, 'Label', 'Load Fit Parameters ...', ...
            'Separator', 'off', 'Callback', @onLoadFitParameters );
        gui.PlotParameters = uimenu( gui.FitMenu, 'Label', 'Plot Fit Parameters', ...
            'Separator', 'on', 'Checked', 'on', 'Callback', @onPlotParameters );
        
        % + Tools Menu
        gui.ToolsMenu = uimenu ( gui.Window, 'Label', 'Tools' );
        uimenu( gui.ToolsMenu, 'Label', 'Apply Reference...', ...
            'Callback', @onApplyReference );
        uimenu( gui.ToolsMenu, 'Label', 'Combine/Average Selected', ...
            'Callback', @onCombineAverage );
        uimenu( gui.ToolsMenu, 'Label', 'Export Axes to Figure', ...
            'Callback', @onExportAxesToFigure );
        uimenu( gui.ToolsMenu, 'Label', 'Print Info', ...
            'Callback', @onPrintInfo );
        
        % + FID Menu
        gui.FIDMenu = uimenu ( gui.Window, 'Label', 'FID' );
        uimenu( gui.FIDMenu, 'Label', 'Load FID data (ITX) ...', ...
            'Callback', @onProcessFID );
        
        % Arrange the main interface
        mainLayout = uix.HBoxFlex( 'Parent', gui.Window, 'Spacing', 3 );
        
        % + Create the panels
        controlPanel = uix.BoxPanel( ...
            'Parent', mainLayout, ...
            'Title', 'Data Set' );
        gui.ViewPanel = uix.BoxPanel( ...
            'Parent', mainLayout, ...
            'Title', 'View' );
        gui.ViewContainer = uicontainer( ...
            'Parent', gui.ViewPanel );
        rightContainer = uix.VBoxFlex( ...
            'Parent', mainLayout, ...
            'Padding', 3, 'Spacing', 3 );

        % + Adjust the main layout
        set( mainLayout, 'Widths', [-0.6,-1.5,-1]  );
        
        
        % LEFT SIDE
        % + Create spectra overview
        controlLayout = uix.VBox( 'Parent', controlPanel, ...
            'Padding', 3, 'Spacing', 3 );
        gui.Spectra = uicontrol( 'Parent', controlLayout, ...
            'Style', 'listbox', ...
            'FontName', data.MonoFont, ...
            'String', 'no data', ...
            'Callback', @onDataSelect, ...
            'Min', 0, ...
            'Max', 2);
        
        infoPanel = uix.BoxPanel( 'Parent', rightContainer, ...
            'Title', 'Infos' );
        gui.FitInfo = uicontrol( 'Parent', infoPanel, ...
            'Style', 'text');
        
        parameterPanel = uix.BoxPanel( 'Parent', rightContainer, ...
            'Title', 'Fit Parameters' );
        parameterLayout1 = uix.VBox( 'Parent', parameterPanel, ...
            'Padding', 3, 'Spacing', 3 );
        parameterLayout2 = uix.HBox( 'Parent', parameterLayout1, ...
            'Padding', 3, 'Spacing', 3 );
        
            gui.Txt_showCoeffs = uicontrol( 'Parent', parameterLayout2, ...
                'String', 'Show CF', ...
                'Style', 'text' );
            gui.Check_showCoeffs = uicontrol( 'Parent', parameterLayout2, ...
                'Style', 'Checkbox', ...
                'Callback', @onShowCoeffs );
            
            gui.Txt_autoCalcA = uicontrol( 'Parent', parameterLayout2, ...
                'String', 'Auto Calc A', ...
                'Style', 'text' );
            gui.Check_autoCalcA = uicontrol( 'Parent', parameterLayout2, ...
                'Style', 'Checkbox', ...
                'Callback', @()updateParameters );
            
        gui.paramTable = uitable( 'Parent', parameterLayout1, ...
            'CellEditCallback', @updateTableData );
        
        % + Adjust the Heigths
        set( rightContainer, 'Heights', [-1,-3] );
        set( parameterLayout1, 'Heights', [25 -1] );
        
        % + Adjust the Widths
        set( parameterLayout2, 'Widths', ones(1,4)*(-1) );
        
        % + Create the view
        gui.ViewContainer = gui.ViewContainer;
        gui.ViewAxes = axes( 'Parent', gui.ViewContainer );
        
    end % createInterface

%-------------------------------------------------------------------------%
    function updateInterface()
        % Update various parts of the interface in response to boundary
        % conditons being changed
        
        % + Update boundary conditions information if the data exists. (It
        % doesn't when the program starts)
        if isfield( data.spectraData, 'DataSet' )
            % Format the text that shall be displayed
            InfoString = sprintf( 'coming soon' );
            % Apply the string to the text control
            set( gui.FitInfo, 'String', InfoString );
            
            % Update the listbox
            spectraNames = cell( 1, numel( data.spectraData.DataSet ) );
            for i=1:numel(data.spectraData.DataSet)
                spectraNames{1,i} = data.spectraData.DataSet(i).name;
            end
            set( gui.Spectra, 'String', spectraNames )
        end % Update Interface
        
        drawTable();
        
    end % updateInterface

%-------------------------------------------------------------------------%
    function redrawView()
        % Draw a demo into the axes provided
        
        % We first clear the existing axes ready to build a new one
        if ishandle( gui.ViewAxes )
            delete( gui.ViewAxes );
        end
        
        % Get rid of the opened figure
        close( fig );
    end % redrawDemo
%-------------------------------------------------------------------------%

%-------------------------------------------------------------------------%
    function drawTable()
        % Draw write table entries in the provided uitable
        
        if ~isfield( data,'parameters' )
            return
        end
        
        % Get Column names from fit model
        rnames = coeffnames( fittype( data.fitModel ) );
        cnames = {'Start', 'Lower', 'Upper'};
        
        % Get table data
        d = [data.parameters.oscStrength, ...
            data.parameters.dampingCoeffs, ...
            data.parameters.nonResonant, ...
            data.parameters.offset, ...
            data.parameters.peakPos;
            data.parameters.oscStrengthLower, ...
            data.parameters.dampingCoeffsLower, ...
            data.parameters.nonResonantLower, ...
            data.parameters.offsetLower, ...
            data.parameters.peakPosLower;
            data.parameters.oscStrengthUpper, ...
            data.parameters.dampingCoeffsUpper, ...
            data.parameters.nonResonantUpper, ...
            data.parameters.offsetUpper, ...
            data.parameters.peakPosUpper]';
        
        % Set row and column names and other parameters
        set( gui.paramTable, ...
            'ColumnName', cnames, ...
            'RowName', rnames, ...
            'Units', 'normalized', ...
            'Data', d );
        
        set( gui.paramTable, ...
            'ColumnEditable', [true true true] );
        
    end % redrawDemo
%-------------------------------------------------------------------------%


%-------------------------------------------------------------------------%
%%% HELPER FUNCTIONS
%-------------------------------------------------------------------------%
    
    %%%-----------------------------------------------------------------
    %%% Loads a data set from a .mat file
    %%%-----------------------------------------------------------------
    function onLoadData( ~, ~ )
        % Load data set and display it in listbox
        
        % Get file path and name
        [FileName,PathName,filterindex] = ...
            uigetfile( '*.mat','Load Data Set', ...
            'data/' );
        
        % If user presses 'Cancel'
        if filterindex == 0
            return
        end
        
        % Remember folder
        data.lastFolder = PathName;
        
        % Load the data
        data.spectraData = load( [PathName, '/', FileName] );
        
        % Update the interface
        updateInterface();
        onDataSelect();
    end    

    %%%-----------------------------------------------------------------
    %%% Saves a data set to a .mat file
    %%%-----------------------------------------------------------------
    function onSaveData( ~, ~ )
        % Load data set and display it in listbox
        
        % Get file path and name
        [FileName,PathName,filterindex] = ...
            uiputfile( '*.mat','Save Data Set', ...
            'data/' );
        
        % If user presses 'Cancel'
        if filterindex == 0
            return
        end
        
        DataSet = data.spectraData.DataSet;
        
        % Save the data set
        save( [PathName, '/', FileName], 'DataSet' );
        
    end

    %%%-----------------------------------------------------------------
    %%% Loads fit parameters from a .mat file
    %%%-----------------------------------------------------------------
    function onLoadFitParameters( ~, ~ )
        % Load data set and display it in listbox
        
        % Get file path and name
        [FileName,PathName,filterindex] = ...
            uigetfile( '*.mat','Load Fit Parameters', ...
            'data/' );
        
        % If user presses 'Cancel'
        if filterindex == 0
            return
        end
        
        % Load the data
        parameters = load( [PathName, '/', FileName] );
        
        % Add to data struct
        data.parameters = parameters.parameters;
        
        % Update the interface
        drawTable();
    end
    
    %%%-----------------------------------------------------------------
    %%% Saves the fit parameters to a .mat file
    %%%-----------------------------------------------------------------
    function onSaveFitParameters( ~, ~ )
        % Load data set and display it in listbox
        
        % Get file path and name
        [FileName,PathName,filterindex] = ...
            uiputfile( '*.mat','Save Fit Parameters', ...
            'data/' );
        
        % If user presses 'Cancel'
        if filterindex == 0
            return
        end
        
        parameters = data.parameters;
        
        % Save the data set
        save( [PathName, '/', FileName], 'parameters' );
        
    end    

    %%%-----------------------------------------------------------------
    %%% Plots the selected spectrum
    %%%-----------------------------------------------------------------
    function onDataSelect( ~, ~ )
        % Plot the data points
        
        value = get(gui.Spectra, 'Value');
        
        if numel( value ) == 0
            % Return if nothing is selected
            return
        end
        
        for i=1:numel( value )
                                   
            xData = data.spectraData.DataSet(value(i)).wavenumber;
            yData = data.spectraData.DataSet(value(i)).signal;
            
            h = gui.ViewAxes;
            
            if i>1
                % Plot the other selected spectra with the previous one
                hold( h,'on' )
            else
                hold( h,'off' )
            end
            
            % Plot
            p(i) = plot( h, xData,yData,'.' );
            
            % Set name on legend
            p(i).DisplayName = data.spectraData.DataSet(value(i)).name;
            
            % Label the axes
            xlabel(h,'Wavenumber'); ylabel(h,'Signal');
            
            if isfield( data.spectraData.DataSet(value(i)), 'fitresult' ) ...
                    && ~isempty( data.spectraData.DataSet(value(i)).fitresult )
                
                fitResult = data.spectraData.DataSet(value(i)).fitresult;
                xFit = linspace(xData(1),xData(end),1000);
                yFit = feval( fitResult, xFit );
                
                hold( h, 'on' );
                plot( h, xFit, yFit, '-' )
                hold( h, 'off' );
                
            end
            
            if data.smoothed
                % Plot smoothed line through spectrum
                
                for j=1:numel(p)
                    ySmooth = smooth(yData,round( numel( yData)/15 ),'sgolay' );
                    
                    hold( h, 'on' );
                    s = plot( h, xData, ySmooth, '-' );
                    s.Color = p(i).Color;
                    hold( h, 'off' );
                end
                
            end
            
            if strcmp(gui.PlotParameters.Checked,'on')
                
                hold( h, 'on' )
                
                % Evaluate function
                
                parameters = [data.parameters.oscStrength, ...
                    data.parameters.dampingCoeffs, ...
                    data.parameters.nonResonant, ...
                    data.parameters.offset, ...
                    data.parameters.peakPos];
                
                FitString = 'cfit(f';
                
                for m=1:numel( parameters )
                    FitString = [FitString, ', ', num2str( parameters(m) )];
                end
                
                FitString = [FitString, ')'];
                    
                f = fittype( data.fitModel );
                c = eval( FitString );
                
                xFit = linspace(xData(1),xData(end),1000);
                yFit = feval( c, xFit );
                
                hold( h, 'on' );
                plot( h, xFit, yFit, '-' )
                hold( h, 'off' );
                
                hold( h, 'off' )
            end
            
        end
        
        % Show legend
        l = legend(h,'show',p);
        l.Interpreter = 'none';
        
        % Release hold
        hold( h,'off' )
        
        updateParameters();
        
    end

    %%%-----------------------------------------------------------------
    %%% Executes fitting function for all available spectra
    %%%-----------------------------------------------------------------
    function onBatchFit( ~, ~ )
        
        % Get number of spectra to fit
        spectraIdx = 1:numel( data.spectraData.DataSet );
        
        % Start fit
        startFit( spectraIdx );
        
    end
    
    %%%-----------------------------------------------------------------
    %%% Executes fitting function for selected spectrum
    %%%-----------------------------------------------------------------
    function onSingleFit( ~, ~ )
               
        % Get selected spectrum
        spectraIdx = get( gui.Spectra, 'Value' );
        
        % Start fit
        startFit( spectraIdx );
        
    end

    %%%-----------------------------------------------------------------
    %%% Executes fitting function for selected spectrum
    %%%-----------------------------------------------------------------
    function onPlotParameters( ~, ~ )
        
        if strcmp(gui.PlotParameters.Checked,'on')
            gui.PlotParameters.Checked = 'off';
        else
            gui.PlotParameters.Checked = 'on';
        end
        
    end

%%%-----------------------------------------------------------------
    %%% Draws a table with fitting parameters
    %%%-----------------------------------------------------------------
    function updateTableData( ~, callbackdata )
        
        numval = eval(callbackdata.EditData);
        r = callbackdata.Indices(1);
        c = callbackdata.Indices(2);
        gui.paramTable.Data(r,c) = numval;
        
        updateParameters()
        onDataSelect()
        
    end

    function onShowCoeffs( ~, ~ )        
        % Show Coefficients of fitresult if box is checked
        
        % Get value of the checkbox
        value = gui.Check_showCoeffs.Value;
        
        % Get selected spectrum and check if a fitresult is available
        spectrumIdx = gui.Spectra.Value;
        fitIsAvailable = ...
            isfield( data.spectraData.DataSet(spectrumIdx), 'fitresult' );
        
        if value==0
            % Show fit parameters
            
            drawTable()
            
        elseif value == 1 && fitIsAvailable == true
            % Show coefficients of fitresult
            
            showCoeffs()
            
        else
            
            drawTable()
            disp('No fit data available')
            
        end
        
    end

    %%%-----------------------------------------------------------------
    %%% Processes all itx files in the selected
    %%%-----------------------------------------------------------------
    function onProcessITX( ~, ~ )
        
        % Open get file dialog
        [fileName,pathName,filterindex] = uigetfile(...
            [data.lastFolder,'*.itx'],...
            'Choose Files to Import',...
            'MultiSelect','on');
        
        % If user presses 'Cancel'
        if filterindex == 0
            return
        end
        
        % If only one file is selected it is treated as a string but is not
        % contained in a cell array. Because we access a cell array
        % underneath we have to but it in one
        if ~iscell( fileName )
            fileNameString = fileName;
            fileName = cell(1);
            fileName{1} = fileNameString;
        end
        
        % Remember folder
        data.lastFolder = pathName;
        
        % Print info to command window
        fprintf( 'Importing %g files...\n', numel( fileName ) )
        
%         DataSet = struct([]);
        DataSet = struct('signal',[],...
            'wavenumber',[],...
            'wavelength',[],...
            'settings',[],...
            'temperature',[]);
        
        for i=numel( fileName ):-1:1
            
            % Define full path to file (including file)
            fullPath = [pathName, fileName{i}];
            
            % For the displayed name get rid of the 'itx' format ending
            [~, name, ~] = fileparts( fullPath );
            
            % Import itx file
            importData = fcn_itximport( fullPath, 'struct' );
            
%             [signal,wavenumber,wavelength,temperature] = ...
%                 fcn_sfgprocess( importData.WLOPG, importData.SigOsc1, ...
%                 importData.SigDet1 );
%             
%             DataSet(i).signal = signal*10e10;
%             DataSet(i).wavenumber = wavenumber;
%             DataSet(i).wavelength = wavelength;
%             DataSet(i).temperature = temperature;

            DataSet(i) = ...
                fcn_sfgprocess( importData.WLOPG, importData.SigOsc1, ...
                importData.SigDet1 );
            
            n(i).name = name;
            
        end
        
        for i=1:numel( DataSet )
            % Set names (somehow not possible to do it in the above loop)
            
            % Set name of the spectrum
            DataSet(i).name = n(i).name;
        end
        
        if numel( data.spectraData.DataSet ) < 1
            data.spectraData.DataSet = DataSet;
        else
            % Put new spectra at the end of the data set
            data.spectraData.DataSet(end+1:end+numel(fileName)) = DataSet;
        end
        
        
        updateInterface();
        onDataSelect();
        fprintf( '\tDone.\n' )
        
    end

%%%-----------------------------------------------------------------
%%% Apply Reference Spectrum
%%%-----------------------------------------------------------------
    function onApplyReference( ~, ~ )
        
        [DataSet,data.lastFolder] = ...
            fcn_sfgReference( data.spectraData.DataSet, gui.Spectra.Value );
        data.spectraData.DataSet = DataSet;
        
        updateInterface()
        onDataSelect()
        
    end

%%%-----------------------------------------------------------------
%%% Apply Reference Spectrum
%%%-----------------------------------------------------------------
    function onCombineAverage( ~, ~ )
        
        % Get selected spectra
        idx = gui.Spectra.Value;
        
        % Return if only one is selected
        if numel( idx ) < 1
            return
        end
        
        % Function
        DataSet = ...
            fcn_spectraCombineAverage( data.spectraData.DataSet(idx) );
        
        
        data.spectraData.DataSet(end+1:end+numel(idx)) = DataSet;
    end

%%%-----------------------------------------------------------------
%%% Export Axes to Figue
%%%-----------------------------------------------------------------
    function onExportAxesToFigure( ~, ~ )
        % Creates a new figure outside of the GUI and copies the currently
        % selected plots to it
        
        % Get Axes handle
        ax = gui.ViewAxes;
        
        % Create new figure
        f = figure;
        
        % Copy axes to new figure
        copyobj( ax,f )
        
    end

%%%-----------------------------------------------------------------
%%% Print Info
%%%-----------------------------------------------------------------
    function onPrintInfo( ~, ~ )
        % Print Info for selected plots to command window
        
        % Get selected spectra
        values = gui.Spectra.Value;
        
        for i=1:numel( values )
            disp( data.spectraData.DataSet(i).name )
            disp( data.spectraData.DataSet(i).settings )
        end
        
    end


%%%-----------------------------------------------------------------
%%% Removes the selected data from listbox and struct
%%%-----------------------------------------------------------------
    function onRemoveSelected( ~, ~ )
        
        % Clear data
        data.spectraData.DataSet(gui.Spectra.Value) = [];
        
        % Update the interface
        updateInterface();
        
    end

%%%-----------------------------------------------------------------
%%% Clears the listbox and data from struct
%%%-----------------------------------------------------------------
    function onClearData( ~, ~ )
        
        % Clear data
        data.spectraData.DataSet = struct([]);
        
        % Empty the listbox
        gui.Spectra.String = {};
        
        % Update the interface
        updateInterface();
        
    end

%%%-----------------------------------------------------------------
%%% Process FID
%%%-----------------------------------------------------------------
    function onProcessFID( ~, ~ )
        
        % Open get file dialog
        [fileName,pathName,filterindex] = uigetfile(...
            [data.lastFolder,'*.itx'],...
            'Choose FID to Process',...
            'MultiSelect','off');
        
        % If user presses 'Cancel'
        if filterindex == 0
            return
        end
        
        % Import itx file
        importData = fcn_itximport( [pathName '/' fileName], 'struct' );
        
        % Put imported data in the appropriate structure
        data.FID(1).signalRaw = importData.SigOsc1;
        data.FID(1).delayRaw = importData.DtLine1;
        
        % Make absolute signal values
        signalData = abs(data.FID(1).signalRaw);
        
        % Count shots per delay
        shotsPerDL = 1;
        for k=1:length(data.FID.delayRaw)
            if data.FID.delayRaw(k+1) == data.FID.delayRaw(k)
                shotsPerDL = shotsPerDL + 1;
            else
                break
            end
        end
        
        % Get length of raw data
        lengthRD = length(data.FID.delayRaw);
        % Determine length of processed data
        lengthPD = lengthRD/shotsPerDL;
        
        % Get step size
        % Get minimum delay
        minDL = min(data.FID.delayRaw);
        % Get maximum delay
        maxDL = max(data.FID.delayRaw);
        % Total delay range
        rangeDL = maxDL - minDL;
        % Step size
        stepSize = rangeDL/(lengthPD - 1);
        
        % Make array for processed delay data
        dlDataPr = minDL:stepSize:maxDL;
        % Make empty array for processed signal data
        sigDataPr = zeros(1,length(dlDataPr));
        
        % Make empty array for signal to noise ratio data
        snrData = zeros(1,length(dlDataPr));
        
        % Loop through every delay
        for j=1:length(dlDataPr)
            % Get range of signal data
            signalDataRangeL = ((j-1)*shotsPerDL) + 1;
            signalDataRangeU = signalDataRangeL + shotsPerDL - 1;
            % Define signal data in range
            dataRange = signalData(signalDataRangeL:signalDataRangeU);
            %   DataNumber = numel(dataRange)
            % Calculate Standard deviation
            % stdDev =...
            %    std(dataRange);
            % Delete Values that are out of a reasonable range
            meanDataRange = mean(dataRange);
            %dataRange(dataRange>meanDataRange + stdDev) = [];
            %dataRange(dataRange<meanDataRange - stdDev) = [];
            %meanDataRange2 = mean(dataRange);
            %  newDataNumber = numel(dataRange)
            % Get average of signalData
            sigDataPr(j) =...
                meanDataRange;
            % Calculate Signal to noise Ratio
            signal = signalData(signalDataRangeL:signalDataRangeU);
            noise = signal - sigDataPr(j);
            snrData(j) = snr(signal,noise);
        end
        
        data.FID.signal = sigDataPr*1e10;
        data.FID.delay = dlDataPr;
        
        disp( data.FID )
        
        % Fit data
        ft = fittype( 'a*exp(-(x-b)^2/(2*c^2))+d' );
        FitObj = fit( data.FID.delay', data.FID.signal', ft, ...
            'StartPoint', ...
            [max(data.FID.signal), ...
            data.FID.delay(data.FID.signal==max(data.FID.signal)), ...
            15, ...
            mean(data.FID.signal)] );
        xFit = linspace( min(data.FID.delay),max(data.FID.delay),1000 );
        yFit = feval( FitObj, xFit );
        
        cVals = coeffvalues( FitObj );
        cErrors = confint( FitObj );
        cErrorsRelative = cErrors(2,:) - cVals;
        
        data.FID.delayTime = cVals(2);
        data.FID.FWTM = 2*sqrt(2*log(10))*cVals(3);
        
        % Plot results
        figure
        hold on
        p = plot( data.FID.delay, data.FID.signal, '.-' );
        p.DisplayName = 'Data';
        f = plot( xFit,yFit );
        f.DisplayName = sprintf(...
            'Fitted Curve\nDelay = %.1f $\\pm$ %.1f ps\nFWTM = %.1f ps\n', ...
            data.FID.delayTime, cErrorsRelative(2), data.FID.FWTM );
        xlabel( 'Delay [ps]' )
        ylabel( 'Signal [a.u.]')
        title( fileName )
        legend('show','Location','best')
        
    end

    %%%-----------------------------------------------------------------
    %%% Closes the program window
    %%%-----------------------------------------------------------------
    function onExit( ~, ~ )
        
        close( gui.Window );
        
    end

%-------------------------------------------------------------------------%
%%% PROGRAM FUNCTIONS
%-------------------------------------------------------------------------%

    function startFit( spectraIdx )
        
        
        for i=spectraIdx
            
            updateCoefficients(i);
            
            % Output
            if data.doPrint
                fprintf('Peak positions set to:\n')
                disp(data.parameters.peakPos)
                fprintf('Bounds: %g\n',data.parameters.peakPosLower)
                fprintf('Damping coefficients set to:\n')
                disp(data.parameters.dampingCoeffs)
                fprintf('Bounds: %g\n',data.parameters.dampingCoeffsLower)
            end
            
            % Prepare wavenumber and signal data for fitting
            wavenumber = data.spectraData.DataSet(i).wavenumber;
            signal = data.spectraData.DataSet(i).signal;
            [xData,yData] = prepareCurveData( wavenumber, signal );
            
            % Fit
            [data.spectraData.DataSet(i).fitresult, ...
                data.spectraData.DataSet(i).gof, ...
                data.spectraData.DataSet(i).output] = ...
                fit( xData, yData, data.fitModel, data.fitOpts );
            
            coeffnames( data.spectraData.DataSet(i).fitresult )
            
            % View Current Fit
            set( gui.Spectra, 'Value', i );
            
            % Update Axes
            onDataSelect();
            
        end
                       
    end

    function updateParameters()
        
        if ~isfield( data,'parameters' )
            return
        end
        
        % Get data from table
        tableData = gui.paramTable.Data;
        
        % Get number of peaks
        numPeaks = data.numPeaks;
        
        % Write values to data structure
        data.parameters.peakPos = tableData(end-numPeaks+1:end,1)';
        data.parameters.peakPosLower = tableData(end-numPeaks+1:end,2)';
        data.parameters.peakPosUpper = tableData(end-numPeaks+1:end,3)';
        data.parameters.dampingCoeffs = tableData(numPeaks+1:2*numPeaks,1)';
        data.parameters.dampingCoeffsLower = tableData(numPeaks+1:2*numPeaks,2)';
        data.parameters.dampingCoeffsUpper = tableData(numPeaks+1:2*numPeaks,3)';
        data.parameters.oscStrength = tableData(1:numPeaks,1)';
        data.parameters.oscStrengthLower = tableData(1:numPeaks,2)';
        data.parameters.oscStrengthUpper = tableData(1:numPeaks,3)';
        data.parameters.nonResonant = tableData(2*numPeaks+1,1)';
        data.parameters.nonResonantLower = tableData(2*numPeaks+1,2)';
        data.parameters.nonResonantUpper = tableData(2*numPeaks+1,3)';
        
        data.parameters.offset = tableData(2*numPeaks+2,1)';
        data.parameters.offsetLower = tableData(2*numPeaks+2,2)';
        data.parameters.offsetUpper = tableData(2*numPeaks+2,3)';
        
        updateCoefficients( gui.Spectra.Value )
    end

    function updateCoefficients(spectrumIndex)
        
        if ~isfield( data,'parameters' )
            return
        end
        
        % Calculate Oscillator Strength Parameters
        if gui.Check_autoCalcA.Value
            % If automatic calculation of oscillator strengths is selected
            
            % Find index number of each Start Point of the peak frequencies
            idx = zeros(1,data.numPeaks);
            for i=1:data.numPeaks
                [~, idx(i)] = min( abs( data.spectraData.DataSet(spectrumIndex).wavenumber - ...
                    data.parameters.peakPos(i) ));
            end           
            
            % Mumbo Jumbo
            data.parameters.oscStrength = ...
                ((data.parameters.dampingCoeffs - data.laserBandwidth).* ...
                sqrt(data.spectraData.DataSet(spectrumIndex).signal(idx)) + ...
                (data.parameters.dampingCoeffs - data.laserBandwidth) * ...
                data.parameters.nonResonant);
            data.parameters.oscStrengthLower = ...
                data.parameters.oscStrength - data.parameters.oscStrength*2;
            data.parameters.oscStrengthUpper = ...
                data.parameters.oscStrength + data.parameters.oscStrength*2;
            
        end
        
        data.fitOpts.StartPoint = [data.parameters.oscStrength, ...
            data.parameters.dampingCoeffs, ...
            data.parameters.nonResonant, ...
            data.parameters.offset, ...
            data.parameters.peakPos];
        data.fitOpts.Lower = [data.parameters.oscStrengthLower, ...
            data.parameters.dampingCoeffsLower, ...
            data.parameters.nonResonantLower, ...
            data.parameters.offsetLower, ...
            data.parameters.peakPosLower];
        data.fitOpts.Upper = [data.parameters.oscStrengthUpper, ...
            data.parameters.dampingCoeffsUpper, ...
            data.parameters.nonResonantUpper, ...
            data.parameters.offsetUpper, ...
            data.parameters.peakPosUpper];
        
        % Update Table
        drawTable();
        
    end

    function showCoeffs()
        
        spectrumIdx = gui.Spectra.Value;
        fitresult = data.spectraData.DataSet(spectrumIdx).fitresult;
        
        gui.paramTable.Data(:,1) = round( coeffvalues( fitresult )'*10 )./10;
        gui.paramTable.Data(:,2:3) = round( confint( fitresult )'*10 )./10;
        
    end

end