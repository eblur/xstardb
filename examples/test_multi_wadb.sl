%%%%
%% 2014.09.30 - lia@space.mit.edu
%%
%% test_multi_wadb.sl -- Test the test functions from multi_warmabs_db.sl
%%%%

require("warmabs_db");
require("multi_warmabs_db");

variable s1 = rd_xstar_output("warmabs_1.fits");
variable s2 = rd_xstar_output("warmabs_2.fits");
variable slist = [s1, s2];

variable test_id = 1493, test_ion = "c_v";

variable test = find_line( test_id, test_ion, slist );

variable i;
for (i=0; i<length(test); i++) xstar_page_group(slist[i], where(test[i])); ;