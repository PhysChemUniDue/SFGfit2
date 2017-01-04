function [varargout] = fcn_sfgprocess(wavelengthData,signalData,temperatureData)
% Process SFG raw data


%% Processing
%
%   1st step: Make signal data absolute values
%   2nd step: Take all signal data points for one wavelength and average them
%

% Make absolute signal values
signalData = abs(signalData)*1e10;

% Correct temperature values
temperatureData = temperatureData;

% Count shots per wavelength
shotsPerWL = 1;
for k=1:length(wavelengthData)
    if wavelengthData(k+1) == wavelengthData(k)
        shotsPerWL = shotsPerWL + 1;
    else
        break
    end
end

% Get length of raw data
lengthRD = length(wavelengthData);
% Determine length of processed data
lengthPD = lengthRD/shotsPerWL;

% Get step size
% Get minimum WL
minWL = min(wavelengthData);
% Get maximum WL
maxWL = max(wavelengthData);
% Total wavelength range
rangeWL = maxWL - minWL;
% Step size
stepSize = rangeWL/(lengthPD - 1);

% Make array for processed Wavelength data
wlDataPr = minWL:stepSize:maxWL;
% Make empty array for processed signal data
sigDataPr = zeros(1,length(wlDataPr));

% Make empty array for signal to noise ratio data
snrData = zeros(1,length(wlDataPr));

% Loop through every wavelength
for j=1:length(wlDataPr)
    % Get range of signal data
    signalDataRangeL = ((j-1)*shotsPerWL) + 1;
    signalDataRangeU = signalDataRangeL + shotsPerWL - 1;
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
TempDataPr = mean(temperatureData);
%% Calculate wavenumbers
wavenumber = 1e7./wlDataPr;

%% Data output

if nargout == 1
    % Make structure
    varargout{1}.signal = sigDataPr;
    varargout{1}.wavenumber = wavenumber;
    varargout{1}.wavelength = wlDataPr;
    varargout{1}.settings.snr = snrData;
    varargout{1}.settings.spa = shotsPerWL;
    varargout{1}.settings.stepSize = stepSize;
    varargout{1}.temperature = TempDataPr;
elseif nargout == 3
    % Make signal and wavenumber array
    varargout{1} = sigDataPr;
    varargout{2} = wavenumber;
    varargout{3} = TempDataPr;
elseif nargout == 4
    % Make signal, wavenumber and wavlength array
    varargout{1} = sigDataPr;
    varargout{2} = wavenumber;
    varargout{3} = wlDataPr;
    varargout{4} = TempDataPr;
end



end