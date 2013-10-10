classdef config < meegpipe.node.abstract_config
    % CONFIG - Configuration of bad_channels nodes
    %
    % See: <a href="matlab:misc.md_help('meegpipe.node.bss_regr.config')">misc.md_help(''meegpipe.node.bss_regr.config'')</a>
    
    
    
    
    %% PUBLIC INTERFACE ...................................................
    
    properties
        
        PCA             = spt.pca.pca('Criterion', 'aic', 'Var', [0.95 0.9999], 'MaxDimOut', 50);
        BSS             = spt.bss.multicombi.multicombi;
        RegrFilter      = [];
        ChopSelector    = physioset.event.class_selector('Class', 'chop_begin');
        Overlap         = 25;
        Criterion       = spt.criterion.dummy.dummy;
        Reject          = true;
        FixNbICs        = [];
        Filter          = [];
        
    end
    
    % Consistency checks
    methods
        
        function obj = set.RegrFilter(obj, value)
            
            import exceptions.*;
            
            if isempty(value) || ...
                    (isnumeric(value) && numel(value) == 1 && isnan(value)),
                obj.RegrFilter = [];
                return;
            end
            
            if ~isa(value, 'filter.rfilt'),
                throw(InvalidPropValue('Filter', ...
                    'Must be a filter.dfilt objects'));
            end
            
            obj.RegrFilter = value;
            
        end
        
        function obj = set.Criterion(obj, value)
            
            import exceptions.*;
            
            if isempty(value),
                value = [];
            end
            
            if ~isa(value, 'spt.criterion.criterion'),
                throw(InvalidPropValue('Criterion', ...
                    'Must be a spt.criterion.criterion object'));
            end
            
            obj.Criterion = value;
            
        end
        
        function obj = set.PCA(obj, value)
            
            import exceptions.*;
            
            if isempty(value),
                value = [];
            end
            
            if ~isa(value, 'spt.pca.pca'),
                throw(InvalidPropValue('PCA', ...
                    'Must be a spt.pca.pca object'));
            end
            
            obj.PCA = value;
            
        end
        
        function obj = set.BSS(obj, value)
            
            import exceptions.*;
            
            if isempty(value),
                obj.BSS = spt.bss.multicombi.multicombi;
                return;
            end
            
            if ~isa(value, 'spt.bss.bss'),
                throw(InvalidPropValue('BSS', ...
                    'Must be a spt.bss.bss object'));
            end
            
            obj.BSS = value;
            
        end
        
    end
    
    
    % Constructor
    methods
        
        function obj = config(varargin)
            
            obj = obj@meegpipe.node.abstract_config(varargin{:});
            
        end
        
    end
    
    
    
end