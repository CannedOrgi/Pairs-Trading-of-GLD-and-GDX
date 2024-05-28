% Function to lag the data by one period
function y = lag1(x)
    if isnumeric(x)
        % Populate the first entry with NaN
        y = [NaN(1, size(x, 2)); x(1:end-1, :)];
    elseif ischar(x)
        % Populate the first entry with an empty string
        y = [repmat('', [1 size(x, 2)]); x(1:end-1, :)];
    else
        error('Can only be numeric or char array');
    end
end