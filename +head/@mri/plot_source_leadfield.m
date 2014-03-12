function h = plot_source_leadfield(obj, index, varargin)
% PLOT_SOURCE_LEADFIELD
% Plots the distribution of scalp potentials generated by one or more sources
%
% plot_source_leadfield(obj, index)
%
% plot_source_leadfield(obj, index, 'key', value, ...)
%
%
% where
%
% OBJ is a head.mri object
%
% INDEX is a vector of source indices or a cell array containing source
% names
%
%
% ## Commonly used key/value pairs:
%
%
% 'momentum'    : A scalar that can be used to modify the length of the
%                 displayed source dipoles. Default: [], i.e. do not plot
%                 the dipole momentums
%
% 'SizeData'    : A scalar that can be used to modify the size of the
%                 source grid markers. Default: [], i.e. use the automatic
%                 size chosen by MATLAB
%
% 'Time'        : A scalar indicating a sampling instant. If this argument
%                 is provided, the non-normalized scalp potentials
%                 generated at that time instant will be plotted, instead
%                 of the normalized distribution of potentials.
%
%
% ## Notes:
%
% * By leadfield we refer to the "normalized" distribution of scalp
% potentials. By "normalized" we mean that source activation is not taken
% into consideration for plotting the potential distribution, i.e. source
% activation is considered to be equal to 1.
%
%
%
% See also: head.mri

import fieldtrip.ft_plot_topo3d;
import misc.process_varargin;
import fieldtrip.projecttri;

FACE_ALPHA = 0.7; %#ok<NASGU>


MissingSourceLeadField = MException('head:mri:plot_source_leadfield', ...
    'You need to run make_leadfield() first!');

MissingIndex = MException('head:mri:plot_source_leadfield', ...
    'A source index or multiple source indices must be provided');

if nargin < 2 || isempty(index),
    throw(MissingIndex);
end

if isempty(obj.LeadField),
    throw(MissingSourceLeadField);
end

keySet = {'dipoles', 'momentum','sizedata','time','inversesolution', ...
    'leadfield'};
dipoles = false;
momentum = 0;
sizedata =[]; %#ok<NASGU>
time = [];
inversesolution=false;
leadfield = [];
eval(process_varargin(keySet, varargin));


if momentum,
    dipoles = true; %#ok<UNRCH>
end

% if isempty(obj.Source) || isempty(index),
%     return;
% end

if ischar(index) || iscell(index),
    index = source_index(obj, index);
end

h = [];

x = obj.Sensors.Cartesian(:,1);
y = obj.Sensors.Cartesian(:,2);
z = obj.Sensors.Cartesian(:,3);
pnt = [x y z];
tri = projecttri(pnt, 'delaunay');

if isempty(leadfield),
    val = source_leadfield(obj, index, 'time', time, ...
        'InverseSolution', inversesolution);
else
    val = leadfield;
end

thisH = patch('Vertices', pnt, 'Faces', tri, 'FaceVertexCData', sum(val,2), ...
    'FaceColor', 'interp');
set(thisH, 'EdgeColor', 'none');
set(thisH, 'FaceLighting', 'none');

h = [h thisH];

if dipoles,
    set(thisH, 'facealpha', FACE_ALPHA); %#ok<UNRCH>
    hold on;
    thisH = plot_source_dipoles(obj, index, ...
        'momentum', momentum, ...
        'surface', false, ...
        'sizedata', sizedata, varargin{:});
    h = [h thisH];
end

axis off
axis vis3d
axis equal

end