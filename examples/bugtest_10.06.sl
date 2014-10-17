
%% bugtest_10.06.sl
%% 2014.10.06 - lia@space.mit.edu
%%
%% What's going on with the weird "continuum" levels?

require("multi_warmabs_tutorial");

variable contm = wa1.upper_level == "continuum" or wa1.upper_level == "continuu";

variable edges = where( wa1.type == "edge/rrc" and not contm );
% I get 573 listings

xstar_page_group(wa1, edges);

define print_some_info( s, i )
{
    print( s.ion[i] );
    print( s.lower_level[i] + "    " + string(s.ind_lo[i]) );
    print( s.upper_level[i] + "    " + string(s.ind_up[i]) );
}

foreach line (edges[[0:10]]) print_some_info(wa1, line);