function [DataSet,lastFolder] = fcn_sfgReference( DataSet, idx )

fprintf( 'Loading reference spectrum ...\n' )
[GaAsSig,~,GaAsWL] = loadReference();

% Process Spectra
fprintf( 'Processing %g spectra ...\n', numel( idx ) )
for i=1:numel( idx )
    % Loop only through the selected spectra
    
    for j=1:numel( DataSet(idx(i)).wavelength )
        % Check if the GaAs spectrum contains all wavelengths of the actual SFG
        % spectrum
        isInReference = any( DataSet(idx(i)).wavelength(j) == GaAsWL );
        if ~isInReference
            fprintf( 'Did not apply any corrections because the reference does not contain a wavelength of %g nm\nError caused by %s\n', DataSet(idx(i)).wavelength(j), DataSet(idx(i)).name ) 
            % Return without applying anything
            return
        else
            % Get index of current wavelength in GaAs reference
            WLidx = find( DataSet(idx(i)).wavelength(j) == GaAsWL );
            % Processing
            DataSet(idx(i)).signal(j) = DataSet(idx(i)).signal(j)/GaAsSig(WLidx);
        end
    end
    
end

fprintf( '\tDone.\n' )



function [GaAsSig,GaAsWN,GaAsWL] = loadReference()
% LOAD GaAs REFERENCE SPECTRUM FROM ITX FILE AND SAVE IT AS MAT %%%
% Input: none
% Output: [Signal, Wavenumber, Wavelength]

% Choose file
[filename, pathname, ~] = uigetfile('*.itx','Choose GaAs Reference');
lastFolder = pathname;

% Import itx file
data = itximport( [pathname filename],'struct' );

% Process GaAs spectrum
[GaAsSig,GaAsWN,GaAsWL,~] = fcn_sfgprocess( data.WLOPG, ...
    data.SigOsc1, data.SigDet1 );

% Amplify Signal
GaAsSig = GaAsSig*1e10;

end

end

