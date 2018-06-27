function DataSet = fcn_juliamatimport(filename)

data = open(filename);

fnames = fieldnames(data);

DataSet = [];

for i = 1:numel(fnames)
    if ~any(strcmp(fieldnames(data.(fnames{i})), 'name'))
        data.(fnames{i}).name = 'unknown';
    end
    DataSet = [DataSet, data.(fnames{i})];
end

end