function Combined = fcn_spectraCombineAverage( DataSet )
% Combine selected spectra to single entry in the data set. Average
% Intensity if wavelengths overlap. Enter new name in command window.


unique_wavenumbers = unique(cat(2, DataSet.wavenumber));
unique_wavelengths = unique(cat(2, DataSet.wavelength));

% Make an empty matrix to put in the data
all_the_signals = zeros(numel(DataSet), numel(unique_wavenumbers));

% These nested loops may not be super elegant
for i=1:numel(unique_wavenumbers)
    for j=1:numel(DataSet)
        
        signal_at_wavelength = ...
            DataSet(j).signal(DataSet(j).wavenumber == unique_wavenumbers(i));
        
        if isempty(signal_at_wavelength)
            % If wavelength is not present return nan
            signal_at_wavelength = NaN;
        end
        
        all_the_signals(j,i) = signal_at_wavelength;
        
    end
end

Combined.signal = nanmean(all_the_signals, 1);
Combined.wavenumber = unique_wavenumbers;
Combined.wavelength = unique_wavelengths;
Combined.name = sprintf('%g spectra combined', numel(DataSet));


end