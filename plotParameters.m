paramnames = coeffnames( DataSet(1).fitresult );

y = zeros(1, length(DataSet));
x = 1:length(DataSet);
e = zeros(1, length(DataSet));

for i = 1:length(paramnames)
    figure()
    hold on
    title(paramnames(i))
    for j = 1:length(DataSet)
        y(j) = DataSet(j).fitresult.(paramnames(i));        
        ci = confint(DataSet(j).fitresult);
        e(j) = y(j) - ci(2,i);
    end
    errorbar(x, y, e, 'o-')
end