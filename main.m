clear;

% Read a spreadsheet named "GLD.xls" into MATLAB
[num, txt] = xlsread('GLD');
% The first column (starting from the second row) is the trading days in format mm/dd/yyyy
tday1 = txt(2:end, 1);
% Convert the format into yyyymmdd
tday1 = datestr(datenum(tday1, 'mm/dd/yyyy'), 'yyyymmdd');
% Convert the date strings first into cell arrays and then into numeric format
tday1 = str2double(cellstr(tday1));
% The last column contains the adjusted close prices
adjcls1 = num(:, end);

% Read a spreadsheet named "GDX.xls" into MATLAB
[num, txt] = xlsread('GDX');
% The first column (starting from the second row) is the trading days in format mm/dd/yyyy
tday2 = txt(2:end, 1);
% Convert the format into yyyymmdd
tday2 = datestr(datenum(tday2, 'mm/dd/yyyy'), 'yyyymmdd');
% Convert the date strings first into cell arrays and then into numeric format
tday2 = str2double(cellstr(tday2));
% The last column contains the adjusted close prices
adjcls2 = num(:, end);

% Find the intersection of the two data sets, and sort them in ascending order
[tday, idx1, idx2] = intersect(tday1, tday2);
cl1 = adjcls1(idx1);
cl2 = adjcls2(idx2);

% Define indices for training set
trainset = 1:252;
% Define indices for test set
testset = trainset(end)+1:length(tday);

% Determines the hedge ratio on the trainset using regression function
results = ols(cl1(trainset), cl2(trainset));
hedgeRatio = results.beta;

% Spread = GLD - hedgeRatio * GDX
spread = cl1 - hedgeRatio * cl2;
plot(spread(trainset));
figure;
plot(spread(testset));
figure;

% Mean of spread on trainset
spreadMean = mean(spread(trainset));
% Standard deviation of spread on trainset
spreadStd = std(spread(trainset));

% Z-score of spread
zscore = (spread - spreadMean) ./ spreadStd;

% Buy spread when its value drops below 2 standard deviations
longs = zscore <= -2;
% Short spread when its value rises above 2 standard deviations
shorts = zscore >= 2;
% Exit any spread position when its value is within 1 standard deviation of its mean
exits = abs(zscore) <= 1;

% Initialize positions array
positions = NaN(length(tday), 2);
% Long entries
positions(shorts, :) = repmat([-1 1], [length(find(shorts)) 1]);
% Short entries
positions(longs, :) = repmat([1 -1], [length(find(longs)) 1]);
% Exit positions
positions(exits, :) = zeros(length(find(exits)), 2);

% Ensure existing positions are carried forward unless there is an exit signal
positions = fillMissingData(positions);

% Combine the 2 price series
cl = [cl1 cl2];
% Calculate daily returns
dailyret = (cl - lag1(cl)) ./ lag1(cl);
% Calculate PnL
pnl = sum(lag1(positions) .* dailyret, 2);

% Calculate Sharpe ratio on the training set
sharpeTrainset = sqrt(252) * mean(pnl(trainset(2:end))) / std(pnl(trainset(2:end)));
% Calculate Sharpe ratio on the test set
sharpeTestset = sqrt(252) * mean(pnl(testset)) / std(pnl(testset));

% Plot cumulative PnL on the test set
plot(cumsum(pnl(testset)));

% Save positions file for checking look-ahead bias
save example3
