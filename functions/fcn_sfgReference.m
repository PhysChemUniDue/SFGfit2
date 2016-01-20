function DataSet = fcn_sfgReference( DataSet )

fprintf( 'Loading reference spectrum ...\n' )
[GaAsSig,~,GaAsWL] = loadReference();

% Process Spectra
fprintf( 'Processing %g spectra ...\n', numel( DataSet ) )
for i=1:numel( DataSet )
    
    for j=1:numel( DataSet(i).wavelength )
        % Check if the GaAs spectrum contains all wavelengths of the actual SFG
        % spectrum
        isInReference = any( DataSet(i).wavelength(j) == GaAsWL );
        if ~isInReference
            fprintf( 'Did not apply correction on %s because the reference does not contain a wavelength of %g nm\n', DataSet(i).name, DataSet(i).wavelength(j) ) 
            continue
        else
            % Get index of current wavelength in GaAs reference
            idx = find( DataSet(i).wavelength(j) == GaAsWL );
            % Processing
            DataSet(i).signal(j) = DataSet(i).signal(j)/GaAsSig(idx);
        end
    end
    
end

fprintf( '\tDone.\n' )

end



function [GaAsSig,GaAsWN,GaAsWL] = loadReference()
% LOAD GaAs REFERENCE SPECTRUM FROM ITX FILE AND SAVE IT AS MAT %%%
% Input: none
% Output: [Signal, Wavenumber, Wavelength]

% Choose file
[filename, pathname, ~] = uigetfile('*.itx','Choose GaAs Reference');

% Import itx file
data = itximport( [pathname filename],'struct' );

% Process GaAs spectrum
[GaAsSig,GaAsWN,GaAsWL,~] = fcn_sfgprocess( data.WLOPG, ...
    data.SigOsc1, data.SigDet1 );

% Amplify Signal
GaAsSig = GaAsSig*1e10;

end