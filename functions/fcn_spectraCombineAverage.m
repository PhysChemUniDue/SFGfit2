function Combined = fcn_spectraCombineAverage( DataSet )
% Combine selected spectra to single entry in the data set. Average
% Intensity if wavelengths overlap. Enter new name in command window.

return

wavelengthArray = cat( 2, DataSet(:).wavelength );
[Combined.wavelength,IA,IC]...
    = unique( wavelengthArray );
% duplicate indices
duplicateInd = setdiff( 1:numel( Combined.wavelength ), IA )
% duplicate values
duplicateValue = Combined.wavelength(duplicateInd)

% Combine signal
signalArray = cat( 2, DataSet(:).signal );
Combined.signal = signalArray(IA);

for i=1:numel( duplicateValue )
    % Find the original inices of all duplicates
    duplicateWL = find( wavelengthArray == duplicateValue(i) )
    % Average the signal data and put into array
    Combined.signal(duplicateInd(i)-1) = mean( signalArray(duplicateWL) )
end


% Convert wavelengths to wavenumbers
Combined.wavenumber = 1e7./Combined.wavelength;

Combined.snr = mean( DataSet(:).snr )
Combined.spa = cat( 2, DataSet(:).spa )


end