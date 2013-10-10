function [data, dataNew] = process(obj, data, varargin)
% PROCESS - Rejects bad channels
%
% data = process(obj, data)
%
% Where
%
% DATA is a physioset object
%
%
% See also: physioset, bad_channels


import mperl.join;
import report.generic.generic;
import report.object.object;
import meegpipe.node.bad_channels.bad_channels;
import meegpipe.node.globals;

dataNew = [];

verbose = is_verbose(obj);
verboseLabel = get_verbose_label(obj);

% Select only good samples
select(data, 1:nb_dim(data), ~is_bad_sample(data));

% Iterate across sensor groups
[sensObj, sensIdx] = sensor_groups(sensors(data));


crit  = get_config(obj, 'Criterion');
evSel = get_config(obj, 'EventSelector');
dur   = get_config(obj, 'Duration');
off   = get_config(obj, 'Offset');

ev = get_event(data);
if ~isempty(ev) && ~isempty(evSel),
    ev = select(evSel, ev);
end

rep = get_report(obj);

print_title(rep, 'Data processing report', get_level(rep) + 1);

if isempty(ev),
    warning('bad_epochs:NoEvents', ...
        'There are no epoch events: nothing was done!');
    print_paragraph(rep, 'There are no epoch events in this dataset');
    return;
end

% Set the duration and offset properties of the events
ev = set_duration(ev, round(dur*data.SamplingRate));
ev = set_offset(ev, round(off*data.SamplingRate));

evLogName = [get_name(data) '_events.log'];
fid = get_log(obj, evLogName);
fprintf(fid, ev);

badEvLogName = [get_name(data) '_bad_events.log'];
fid = get_log(obj, badEvLogName);
rep = get_report(obj);
for i = 1:numel(sensObj)
    
    if do_reporting(obj),
        % Create a sub-report for this sensor group
        sensorClass = regexprep(class(sensObj{i}), '^(.+?)([^\.]+)$', '$2');
        sensorClass = upper(sensorClass);
        sgRep = generic('Title', ...
            sprintf('Sensor Group %d: %s', i, sensorClass));
        sgRep = childof(sgRep, rep);
        initialize(sgRep);
        print_link2report(rep, sgRep);
    else
        sgRep = [];
    end
    
    select(data, sensIdx{i});
    
    [evBad, ~, idxBadSampl] = find_bad_epochs(crit, data, ev, sgRep);
    
    fprintf(fid, evBad);
    
    set_bad_sample(data, idxBadSampl(:));
    
    restore_selection(data);
    
end

if isempty(evBad),
    msg = 'Did not reject any epoch';
    print_paragraph(rep, msg);
else
    msg = sprintf('Rejected %d/%d (%d%%%%) epochs', ...
        numel(evBad), numel(ev), round(100*numel(evBad)/numel(ev)));
    print_paragraph(rep, msg);
    
    print_paragraph(rep, 'All events: [%s][evlog]', evLogName);
    print_paragraph(rep, 'Bad events: [%s][badevlog]', badEvLogName);
    print_link(rep, ['../' evLogName], 'evlog');
    print_link(rep, ['../' evLogName], 'badevlog');
    
end

if verbose,
    fprintf([verboseLabel msg '\n\n']);  
end    



% Remove the good sample selection
restore_selection(data);

end