function varargout = fcn_itximport(filename,varargin)
% Imports an *.itx file 

%% Vararg Settings
% Make empty cell array for output variables
varargout = cell(1,nargout);
% Input variables
if nargin == 0
    [file,path] = uigetfile('*.itx','Select IGOR text file');
    if file == 0
        % Return if no file was selected
        return
    end
    filename = [path file];
    importLocation = 'base';
elseif nargin == 1
    % Import waves to workspace (default)
    importLocation = 'base';
elseif nargin == 2
    % Set import Location
    switch varargin{1}
        case 'base'
            importLocation = 'base';
        case 'struct'
            importLocation = 'struct';
%         case 'csv'
%             importLocation = 'csv'
%         case 'mat'
%             importLocation = 'mat'
%         otherwise
%             importLocation = 'base'
    end
end

%% Read text
text = fileread(filename);

%% Return if file is empty
if numel(text) == 0
    fprintf('Could not import %s. (emtpty file)',filename)
    return
end

%% Search for waves
exprWAVES = 'WAVES';
[startWAVES,endWAVES] = regexp(text,exprWAVES);
startHEADER = zeros(1,numel(endWAVES));
% Check if Wave has a flag
for i=1:numel(endWAVES)
    % Get text right after "WAVES"
    flag = text(endWAVES(i)+1:endWAVES(i)+2);
    if strcmp(flag,'/D')
        % Set header start in case there is a flag
        startHEADER(i) = endWAVES(i) + 3;
    else
        % In case there is no flag
        startHEADER(i) = endWAVES(i) + 2;
    end
end

%% Wave info indices
endWAVEINFO = zeros(1,numel(startWAVES));
for i=1:numel(startWAVES)-1
    endWAVEINFO(i) = startWAVES(i+1) - 1;
end
% Last endpoint is end of file
endWAVEINFO(numel(startWAVES)) = numel(text);

%% Search for "BEGIN" keyword
exprBEGIN = 'BEGIN';
[startBEGIN,endBEGIN] = regexp(text,exprBEGIN);
% Correct indices
endHEADER = startBEGIN - 1;
startDATA = endBEGIN + 1;

%% Search for "END" keyword
exprEND = 'END';
[startEND,endEND] = regexp(text,exprEND);
% Correct indices
endDATA = startEND - 1;
startWAVEINFO = endEND + 1;
% If no "END" keyword exists (corupted file?) set data end to end of file
if numel(endDATA) < numel(startDATA)
    endDATA(numel(startDATA)) = numel(text);
end


%% Number of wavesets
numWavesets = numel(startWAVES);

%% Devide data in blocks
textHEADER = cell(1,numWavesets);
textDATA = cell(1,numWavesets);
textWAVEINFO = cell(1,numWavesets);
for i=1:numWavesets
    % Headers
    textHEADER{i} = text(startHEADER(i):endHEADER(i));
    % Data
    textDATA{i} = text(startDATA(i):endDATA(i));
    % Wave Info
    if ~isempty(startWAVEINFO)
        textWAVEINFO{i} = text(startWAVEINFO(i):endWAVEINFO(i));
    end
    
    %% Read WAVEINFO data
    if ~isempty(startWAVEINFO)
        % Get start of lines
        startLINE = regexp(textWAVEINFO{i},'X');
        % Get line ends
        endLINE = regexp(textWAVEINFO{i},'\r');
        % Loop through every line
        %[WIP]
    end
    
    %% Combine data and header
    % Write headers in cell
    cHeaders = textscan(textHEADER{i},'%s');
    % Get number of headers
    numHeaders = numel(cHeaders{1});
    % Write data in matrix
    mData = strread(textDATA{i});
    for j=1:numHeaders
        % Get name of wave
        varName = cHeaders{1}{j};
        % In case varname has a "'" in name, delete that
        varName = strrep(varName,'''','');
        % Check if the name of the variable is valid
        if ~isvarname(varName)
            % Variable name is not valid
            % Generate new variable name
            varName = matlab.lang.makeValidName(varName);
        end
        % Get data to wave
        data = mData(:,j);
        % Write
        if strcmp(importLocation,'base')
            assignin('base',varName,data)
        elseif strcmp(importLocation,'struct')
            varargout{1}.(varName) = data;
        else
            return
        end
    end
end

end