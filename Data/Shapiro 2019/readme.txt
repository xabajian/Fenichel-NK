Data version 2.0, created 3/17/2020 
Source: "The Environmental Bias of Trade Policy," Joseph S. Shapiro

See paper text for data and method details. All data represent the year 2007, tariffs are from from CEPII 6-digit HS code files.

For each country, this dataset defines four measures of tariffs on 
intermediate and final goods:

tariff_unweighted_UNBEC: this is the mean tariff, where the mean is calculated without weights, 
and the definition of intermediate versus final goods comes from the UN BEC.

tariff_unweighted: this is the mean tariff, where the mean is calculated without weights,
and the definition of intermediate versus final goods comes from Exiobase.

tariff_weighted_BEC: this is the mean tariff, where the mean is calculated using trade values as weights,
and the definition of intermediate versus final goods comes from the UN BEC.

tariff_weighted: this is the mean tariff, where the mean is calculated using trade values as weights,
and the definition of intermediate versus final goods comes from Exiobase.

intermediate=1 for intermediate goods and materials (as defined in the BEC) or the third of industries that 
for each source country are most upstream (as measured by Exiobase).

intermediate=0 for consumer goods (as defined in the BEC) or the third of industries that
for each source country are least upstream (as measured by Exiobase).