function hFig = make_rank_plots(rankIndex, rejIdx, minRank, maxRank)

import rotateticklabel.rotateticklabel;
import meegpipe.node.globals;
import mperl.split;
import mperl.join;

SIZE_FACTOR = 2;

visible = globals.get.VisibleFigures;

if visible,
    visibleStr = 'on';
else
    visibleStr = 'off';
end

hFig = figure('Visible', visibleStr);
h = plot(rankIndex, 'ko-', 'LineWidth', globals.get.LineWidth);
set(h, 'MarkerSize', 3, ...
    'LineWidth', 1, ...
    'Color', [0.5 0.5 0.5], ...
    'MarkerFaceColor', 'black', ...
    'MarkerEdgeColor', 'black');

axis tight;
yLims    = get(gca, 'YLim');
yRange   = abs(diff(yLims));
yLims(1) = yLims(1) - 0.1*yRange;
yLims(2) = yLims(2) + 0.1*yRange;
set(gca, 'YLim', yLims);
set(gca, 'FontSize', 8);
ylabel('Rank index value');

% Make clear which channels were rejected
if ~isempty(rejIdx),
    hold on;
    h = plot(rejIdx, rankIndex(rejIdx), 'ro');
    set(h, 'MarkerFaceColor', 'red');
    
end


if ~isempty(rejIdx),
    
    % Set the figure XTicks (non-rejected/non-extreme channels)
    nonRejIdx = setdiff(1:numel(rankIndex), rejIdx(:));
    set(gca, 'XTick', nonRejIdx);
    
    if ~isempty(nonRejIdx),
        XLabels = split(',', join(',', nonRejIdx));
        XLabels = cellfun(@(x) [x '   '], XLabels, 'UniformOutput', false);
        set(gca, 'XTickLabel', XLabels);
        th = rotateticklabel(gca, 90);
        
        fontSize = 12;
        
        if numel(rejIdx) > 1,
            fontSize = max(2, min(12, min(diff(nonRejIdx))*SIZE_FACTOR));
        end
        
        set(th, 'FontSize', fontSize);
    end
    
    % Place text labels over the points marking bad channels
    fontSize = 12;
    if numel(rejIdx) > 1,
        fontSize = max(2, min(12, min(diff(rejIdx))*SIZE_FACTOR));
    end
    
    if ~isempty(rejIdx),
        sensLabels = split(',', join(',', rejIdx));
        for i = 1:numel(rejIdx),
            h = text(rejIdx(i), rankIndex(rejIdx(i)), [' ' sensLabels(i)]);
            set(h, 'Rotation', 90, 'FontSize', fontSize);
        end
    end
    
end

if ~isempty(minRank) && minRank > -Inf,
    hold on;
    plot(1:numel(rankIndex), minRank, 'r');
end

if ~isempty(maxRank) && maxRank < Inf,
    hold on;
    plot(repmat(maxRank, 1, numel(rankIndex)), 'r:');
end

end