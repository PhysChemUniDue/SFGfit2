function [varargout] = fcn_sfgprocess(wavelengthData,signalData,temperatureData)
% Process SFG raw data
%
% S = SFGPROCESS(WLOPG, SIGOSC1) takes the wavelengths WLOPG and the signal
%   from SIGOSC1 and returns a structure S.
% [I,WN] = SFGPROCESS(___) returns the intensity of the signal and the
%   wavenumbers.
% [I,WN,WL] = SFGPROCESS(___) returns also the wavelength.
% [___,T] = SFGPROCESS(___) ... and the temperature


%% Processing
%
%   1st step: Make signal data absolute values
%   2nd step: Take all signal data points for one 
%             wavelength and average them
%

% Amplification factor
amplificationFactor = 1e10;

% Correct temperature values
temperatureData = temperatureData * 1;

% Make absolute signal values
signalData = abs(signalData) * amplificationFactor;

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
% Make empty error array
error = zeros(size(wlDataPr));
% temperature array
temperature = zeros(size(wlDataPr));
temperature_error = zeros(size(wlDataPr));

% Loop through every wavelength
for j=1:length(wlDataPr)
    % Get range of signal data
    signalDataRangeL = ((j-1)*shotsPerWL) + 1;
    signalDataRangeU = signalDataRangeL + shotsPerWL - 1;
    dataRange = signalDataRangeL:signalDataRangeU;
    % Get average of signalData
    sigDataPr(j) = mean(signalData(dataRange));
    error(j) = std(signalData(dataRange));
    % Average temperature
    temperature(j) = mean(temperatureData);
    temperature_error(j) = std(temperatureData);
    % Calculate Signal to noise Ratio
    signal = signalData(dataRange);
    noise = signal - sigDataPr(j);
    snrData(j) = snr(signal,noise);
end

% Mean temperature
temperature_mean = mean(temperatureData);

%% Calculate wavenumbers
wavenumber = 1e7./wlDataPr;

%% Data output

if nargout == 1
    % Make structure
    varargout{1}.amplification = amplificationFactor;
    varargout{1}.signal = sigDataPr;
    varargout{1}.error = error;
    varargout{1}.wavenumber = wavenumber;
    varargout{1}.wavelength = wlDataPr;
    varargout{1}.snr = snrData;
    varargout{1}.temperature = temperature_mean;
    varargout{1}.temp_series = temperature;
    varargout{1}.temp_error = temperature_error;
elseif nargout == 2
    % Make signal and wavenumber array
    varargout{1} = sigDataPr;
    varargout{2} = wavenumber;
elseif nargout == 3
    % Make signal, wavenumber and wavlength array
    varargout{1} = sigDataPr;
    varargout{2} = wavenumber;
    varargout{3} = wlDataPr;
elseif nargout == 4
    % Make signal, wavenumber and wavlength array
    varargout{1} = sigDataPr;
    varargout{2} = wavenumber;
    varargout{3} = wlDataPr;
    varargout{4} = TempDataPr;
end



end