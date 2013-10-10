classdef mra < meegpipe.node.abstract_node
    % mra - MR gradient artifact removal
    %
    % See: <a href="matlab:misc.md_help('meegpipe.node.mra')">misc.md_help(''meegpipe.node.mra'')</a>
    
    % from meegpipe.node.abstract_node
    methods
        [data, dataNew] = process(obj, data, varargin)
    end
    
    % redefinition of report.reportable method whatfor()
    methods
        
        function str = whatfor(~)
            
            str = ['Nodes of class __mra__ remove MR gradient artifacts ' ...
                'using nearest-neighbors template matching'];
            
        end
        
    end
    
    
    % Constructor
    methods
        
        function obj = mra(varargin)
            
            import pset.selector.cascade;
            import pset.selector.good_data;
            import pset.selector.sensor_class;
            
            obj = obj@meegpipe.node.abstract_node(varargin{:});
            
            if isempty(get_data_selector(obj));
                dataSel = cascade(good_data, ...
                    sensor_class('Type', {'EEG', 'ECG'}));
                set_data_selector(obj, dataSel);
            end
            
            if isempty(get_name(obj)),
                obj = set_name(obj, 'mra');
            end
            
        end
        
    end
    
    
    
    
    
end