classdef verbose_handle < handle
    % VERBOSE_HANDLE - Interface for classes that display status messages
    %
    %
    %
    % See also: eegpipe.verbose
  
    properties (SetAccess = private, GetAccess = private)
        
        Verbose         = true;
        VerboseLabel    = '';
        VerboseLevel    = [];
        
    end
    
    methods
        
        function set.Verbose(obj, value)
            if numel(value) ~= 1 || ~islogical(value),
                error('Property Verbose must be a logical scalar');
            end
            obj.Verbose = value;
        end
  
    end
 
    methods
        
        function bool   = is_verbose(obj)
            import goo.globals;
            bool = globals.get.Verbose & obj.Verbose;
        end
        
        function level  = get_verbose_level(obj)
            if ~isempty(obj.VerboseLevel) && is_verbose(obj),
                % user-defined level
                level = obj.VerboseLevel;
                return;
            end
            
            if is_verbose(obj),
                level = 1;
            elseif ~is_verbose(obj) && obj.Verbose,
                level = 2;
            else
                level = 0;
            end
        end
        
        function label  = get_verbose_label(obj)
            import goo.globals;
            label = globals.get.VerboseLabel;
            if ~isempty(label),
                return;
            elseif ischar(obj.VerboseLabel),
                label = obj.VerboseLabel;
            elseif isa(obj.VerboseLabel, 'function_handle'),
                st = dbstack;
                if numel(st) > 1,
                    name = st(end).name;
                    name = regexpi(name, '(?<name>[^.]+$) ', 'names');
                    label = obj.VerboseLabel(obj, name.name);
                else
                    label = obj.VerboseLabel(obj,'');
                end
            end
        end
        
        function obj    = set_verbose(obj, value)
            obj.Verbose = value;
        end
        
        function obj    = set_verbose_label(obj, value)
            obj.VerboseLabel = value;
        end
        
        function obj    = set_verbose_level(obj, value)
            obj.VerboseLevel = value;
            if ~value,
                obj = set_verbose_level(obj, 0);
            end
        end
        
    end
    
end