function physiosetObj = import(obj, varargin)
% IMPORT - Imports Wisse&Joris pupillator files
%
% 
% ## Notes:
%
%   * Compressed .gz files are supported.
%
% See also: pupillator


import pset.globals;
import mperl.split;
import physioset.physioset;
import physioset.event.event;
import misc.sizeof;
import misc.eta;
import pset.file_naming_policy;
import exceptions.*
import misc.decompress;
import io.pupillator.read;
import safefid.safefid;
import datestr2num.DateStr2Num;

if numel(varargin) == 1 && iscell(varargin{1}),
    varargin = varargin{1};
end

% Deal with the multi-file case
if nargin > 2
    physiosetObj = cell(numel(varargin), 1);
    for i = 1:numel(varargin)
        physiosetObj{i} = import(obj, varargin{i});
    end
    return;
end

fileName = varargin{1};

[fileName, obj] = resolve_link(obj, fileName);

% Default values of optional input arguments
verbose      = is_verbose(obj);
verboseLabel = get_verbose_label(obj);
origVerboseLabel = goo.globals.get.VerboseLabel;
goo.globals.set('VerboseLabel', verboseLabel);

% The input file might be zipped
[status, fileName] = decompress(fileName, 'Verbose', verbose);
isZipped = ~status;

% Determine the names of the generated (imported) files
if isempty(obj.FileName),
    
    newFileName = file_naming_policy(obj.FileNaming, fileName);
    dataFileExt = globals.get.DataFileExt;
    newFileName = [newFileName dataFileExt];
    
else
    
    newFileName = obj.FileName;
    
end

%% Read the data file
if verbose,
    clear +misc/eta.m;
    fprintf([verboseLabel 'Reading %s...\n\n'], fileName);
end

[data, prot, dataHdr, protHdr] = read(fileName);
isTime = cellfun(@(x) ~isempty(strfind(x, 'time [s]')), dataHdr);
isRespTime = cellfun(@(x) ~isempty(strfind(x, 'PVT responsetime [ms]')), dataHdr);

% respTime marks the location of button-press events
respTime = data(:, isRespTime);
evTime   = data(respTime > eps, isTime);
evSampl  = find(respTime > eps);
respTime = respTime(respTime>eps)/1e3;

% Assume a constant sampling rate, although there are tiny fluctuation in
% the sampling instants
samplingPeriod = mean(diff(data(:, isTime)));

% Any event that has a response time greater than the distance to the 
% previous PVT event must be spurious
isBad = respTime(2:end) > diff(evTime);

if verbose && any(isBad),
    fprintf([verboseLabel ...
        'Found %d spurious response times: ignoring those events ... \n\n']);
end

evTime   = evTime - respTime;
evSampl  = evSampl - round(respTime/samplingPeriod);
evSampl(evSampl<0) = 0;
evSampl(evSampl>size(data,1)) = size(data,1);

if verbose
    fprintf([verboseLabel 'File contains %d PVT events ...\n\n'], numel(evTime));
end

% Create a train of PVT events to hold the PVT response times
myEvs = event(evSampl, 'Type', 'PVT');
for i = 1:numel(myEvs)
    myEvs(i) = set(myEvs(i), ...
        'Time',     evTime(i), ...
        'Value',    respTime(i));        
end

% Create a train of events to mark the transitions between protocol stages
isStatus = cellfun(@(x) strcmp(x, 'status'), dataHdr);
isRed    = cellfun(@(x) strcmp(x, 'red [0-255]'), protHdr);
isBlue   = cellfun(@(x) strcmp(x, 'blue [0-255]'), protHdr);
isPVT    = cellfun(@(x) strcmp(x, 'pvt'), protHdr);
[blockID, transitionSampl] = unique(data(:, isStatus), 'first');
myProtEvs = event(transitionSampl);

blockDur = diff([transitionSampl(:);size(data,1)]);
isPre = true;
isPost = false;
for i = 1:numel(myProtEvs)
   
   thisType = 'block_';
   if prot(i, isRed) > 0,
       
       thisType = [thisType 'red']; %#ok<*AGROW>
       isPre = false;
   elseif prot(i, isBlue) > 0,
       thisType = [thisType 'blue'];
       isPost = true;
   elseif isPre,
       thisType = [thisType 'dark-pre'];
   elseif isPost
       thisType = [thisType 'dark-post'];
   else
       thisType = [thisType 'dark'];
   end
   if prot(i, isPVT) > 0,
       thisType = [thisType, '-pvt'];
   end
   
   myProtEvs(i) = set(myProtEvs(i), ...
       'Time',      data(transitionSampl(i), isTime), ...
       'Value',     blockID(i), ...
       'Duration',  blockDur(i), ...
       'Type',      thisType ...
       );
   
   myProtEvs(i) = set_meta(myProtEvs(i), 'Block_1_7', ceil(blockID(i)/3));
   
end

% The only blocks that are always there are the dark-pre, the red, the
% dark, the blue and the dark-post. Any block before the dark-pre will be
% labeled as dark-pre-1, dark-pre-2, etc. Any block after the dark-post
% will be labeled as dark-post-1, dark-post-2, etc.
evTypes = get(myProtEvs, 'Type');

firstBlock = find(ismember(evTypes, 'block_dark-pre-pvt'), 1, 'last');

for i = 1:firstBlock-1
    thisType = get(myProtEvs(i), 'Type');
    newType  = [thisType '-' num2str(firstBlock-i)];
    myProtEvs(i) = set(myProtEvs(i), 'Type', newType);
end

lastBlock = find(ismember(evTypes, 'block_dark-post-pvt'), 1, 'first');

for i = 1:(numel(myProtEvs)-lastBlock)
    thisType = get(myProtEvs(lastBlock+i), 'Type');
    newType  = [thisType '-' num2str(i)];
    myProtEvs(lastBlock+i) = set(myProtEvs(lastBlock+i), 'Type', newType);
end

dataCols = cellfun(@(x) ismember(x, {'diameter [mm]', 'shapefactor'}), dataHdr);

% Instead of using the actual times, we enforce the sampling period to be
% constant
%time = data(:, isTime);
t0 = data(1, isTime);
time = t0:samplingPeriod:(t0+samplingPeriod*(size(data,1)-1));

data = data(:, dataCols);

if verbose,
    fprintf('Done reading data values and event information...\n\n')
end

%% Read sensor information
if verbose,
    fprintf([verboseLabel 'Creating sensor array ...']);
end

sens = sensors.pupillometry('Label', dataHdr(dataCols));

    
if verbose,
    fprintf('[done]\n\n');
end


%% Write the data values to disk
if verbose,
    fprintf('%sWriting data to %s ...', verboseLabel, newFileName);
end
fid = safefid.fopen(newFileName, 'w');
if fid < 1,
    error('Could not open %s for writing', newFileName);
end

nbSamples = size(data,1);

if nbSamples < 1,
    error('No data samples were found');
end

data  = data';
fid.fwrite(data(:), obj.Precision);

if verbose,
    fprintf('[done]\n\n');
end

%% Generate output object
if verbose,
    fprintf('%sGenerating a physioset object...', verboseLabel);
end

% Guess the sampling rate
recordTime = [datestr(time(1), 'yyyymmddTHHMMSS') '.000'];
startTime = DateStr2Num(recordTime, 300);

samplingTime = time;
sampleRate   = round(1/samplingPeriod);

physiosetArgs = construction_args_physioset(obj);
physiosetObj = physioset(newFileName, nb_sensors(sens), ...
    physiosetArgs{:}, ...
    'SamplingRate',     sampleRate, ...
    'Sensors',          sens, ...
    'StartTime',        startTime, ...
    'SamplingTime',     samplingTime, ...
    'Event',            [myEvs(:);myProtEvs(:)]);

if verbose,
    fprintf('Done reading %s\n\n', fileName);
end

%% Undoing stuff 

% Unset the global verbose
goo.globals.set('VerboseLabel', origVerboseLabel);

% Delete unzipped data file
if isZipped,
    delete(fileName);
end

end


