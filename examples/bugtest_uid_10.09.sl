%%%%
%% bugtest)uid_10.09.sl
%% 2014.10.09 : lia@space.mit.edu
%%
%% Testing that unique id's are working properly
%%%%

require("warmabs_db");

%% Load grid from previous run
variable fgrid, wa_grid;
fgrid = glob( "/vex/d1/lia/xstar_test/column/warmabs_*.fits" );
fgrid = fgrid[ array_sort(fgrid) ];

wa_grid = xstar_load_tables(fgrid);

%% Test the uid_flags

where(wa_grid.uid_flags[0]);
% 3230

length(wa_grid.db[0].uid);
% 3239

% Find which uids are in db0, should be same as wa_grid.uid_flag[0]
variable uid_in_db0 = ismember( wa_grid.uids, wa_grid.db[0].uid ); 

where( uid_in_db0 );
% 3230

variable db0_in_uid = ismember( wa_grid.db[0].uid, wa_grid.uids );
% should be all 1s
if( length(where(db0_in_uid)) == length(db0_in_uid) ) print("All uids in db0 are in wa_grid.uids");
%% it printed

variable unique_db0 = unique( wa_grid.db[0].uid );
print("Length of unique members in db0:");
print(length(unique_db0));
% 3230

%% Find missing members
variable not_unique = [0:length(wa_grid.db[0].uid)-1];
not_unique[unique_db0]  = 0;

variable missing = where(not_unique);
missing;
% 9

xstar_page_group(wa_grid.db[0], missing);

print( wa_grid.db[0].uid[missing] );
print( wa_grid.db[0].ind_ion[missing] );
print( wa_grid.db[0].ind_lo[missing] );
print( wa_grid.db[0].ind_up[missing] );
%% Those all look like they could be correct

%% First entry, what overlaps?
variable dupl1 = where( wa_grid.db[0].uid == wa_grid.db[0].uid[missing[0]] );

xstar_page_group(wa_grid.db[0], dupl1 );

%#      id      ion   lambda    A[s^-1]          f  gl  gu      tau_0       W(A) L[10^38 cgs]       type label
%   11515  Na     X   8.9444  3.740e+12  1.345e-01   1   3  1.445e-07  1.069e-07    0.000e+00       line       1s2.1S -   1s1.3p1.1P
%   11519  Na     X   8.9444  4.823e+10  1.735e-03   1   3  1.869e-09  1.379e-09    0.000e+00       line       1s2.1S -   1s1.3p1.1P

%% THESE ARE THE SAME IDEAS WITH DIFFERENT TRANSITION NUMBERS

%% Test that these came from the same database

variable ftemp = wa_grid.db[0].filename;

variable wacheck = rd_xstar_output(ftemp);

wacheck.transition;
% 3239;

xstar_page_group(wacheck, dupl1);
% #      id      ion   lambda    A[s^-1]          f  gl  gu      tau_0       W(A) L[10^38 cgs]       type label
%   11515  Na     X   8.9444  3.740e+12  1.345e-01   1   3  1.445e-07  1.069e-07    0.000e+00       line       1s2.1S -   1s1.3p1.1P
%   11519  Na     X   8.9444  4.823e+10  1.735e-03   1   3  1.869e-09  1.379e-09    0.000e+00       line       1s2.1S -   1s1.3p1.1P


%% Check a few more just to be sure.

variable dupl2 = where( wa_grid.db[0].uid == wa_grid.db[0].uid[missing[1]] );
xstar_page_group(wacheck, dupl2);

%#      id      ion   lambda    A[s^-1]          f  gl  gu      tau_0       W(A) L[10^38 cgs]       type label
%    7759   F  VIII  13.7368  8.654e+11  7.342e-02   1   3  6.994e-06  2.189e-06    0.000e+00       line       1s2.1S -   1s1.3p1.1P
%    7763   F  VIII  13.7368  2.045e+10  1.735e-03   1   3  1.655e-07  5.175e-08    0.000e+00       line       1s2.1S -   1s1.3p1.1P

variable dupl3 = where( wa_grid.db[0].uid == wa_grid.db[0].uid[missing[2]] );
xstar_page_group(wacheck, dupl3);

%#      id      ion   lambda    A[s^-1]          f  gl  gu      tau_0       W(A) L[10^38 cgs]       type label
%   27394  Ni   XII  35.1841  0.000e+00  0.000e+00   4   0  1.312e-05  0.000e+00    0.000e+00   edge/rrc   3p5.2P_3/2 -    continuum
%   27512  Ni   XII  35.1841  0.000e+00  0.000e+00   4   0  6.303e-05  0.000e+00    0.000e+00   edge/rrc   3p5.2P_3/2 -    continuum

%% How many duplicate entries are we talking about?
variable j;
for (j=0; j<length(wa_grid.uid_flags); j++)
{
    print( string(length(wa_grid.db[j].uid) - length(where(wa_grid.uid_flags[j]))) + " missing entries" );
}
%% 9 in each! Maybe it is just those nine

%%%--- 2014.10.20 : What line is missing from each?

variable dd;
foreach dd (wa_grid.db[0].uid[missing])
{
    xstar_page_group(wa_grid.db[0], where(wa_grid.db[0].uid == dd) );
}


%%%--- 2014.10.15 : Check that at least the uids correspond
%%%--- to the same lines across several dbs

%% Get a few examples from the 1-10 Angstrom range
variable AMIN = 1.0, AMAX = 10.0;
variable i, example = 1.0;
for (i=0; i<=3; i++) example = example and ( xstar_wl(wa_grid.mdb, AMIN, AMAX) and wa_grid.uid_flags[i]);
variable ex_uids = where(example)[[0:5]];

xstar_page_grid(wa_grid, ex_uids);

variable k, line;
foreach  k ([0:5])
{
    xstar_page_grid(wa_grid, ex_uids[k]);

    line = Integer_Type[0];
    variable db;
    foreach db (wa_grid.db)
    {
	line = where(db.uid == wa_grid.uids[ex_uids[k]])[0];
	() = printf( "%i , %s , %.4f\n", db.transition[line], db.ion[line], db.wavelength[line] );
    }
}

%% Looks like everything is working properly


%%%--- 2014.10.17 : Using some old code that searches according to
%%%--- transition number and ion, make ew curve for that weird Na line.

%% Code form multi_warmabs_db.sl

%% Returns lists of booleans, for use with where function
% USE: find_line(1493, "c_v", [s1,s2])
% RETURNS: An array of character arrays containing boolean flags for use with where function
%
define find_line( transition_id, ion_string, struct_list )
{
    variable i, ltemp, result = Array_Type[length(struct_list)];
    for (i=0; i<length(struct_list); i++)
    {
	ltemp = struct_list[i].transition == transition_id and struct_list[i].ion == ion_string;
	result[i] = ltemp;
    }
    return result;
}

%% Get equivalent widths across a list of db structures
% USAGE: xstar_line_ew( 10453, "ne_vii", db_list );
% RETURNS: An array containing ew values from a particular line
%
define xstar_line_ew( transition_id, ion_string, struct_list )
{
    variable i, fl_list;
    variable temp, result = Float_Type[length(struct_list)];

    fl_list = find_line( transition_id, ion_string, struct_list );

    for (i=0; i<length(struct_list); i++)
    {
	temp = where(fl_list[i]);
	if ( length(temp) != 0 ) result[i] = struct_list[i].ew[temp][0];;
    }
    return result;
}

%% Get the weird line and plot curve

variable l1 = xstar_line_ew( 11515, "na_x", wa_grid.db );
variable l2 = xstar_line_ew( 11519, "na_x", wa_grid.db );

plot( wa_grid.par.column, l1 );
oplot( wa_grid.par.column, l2, 2 );


%% Test on Dave's warmabs_vs_xi values

%% Warmabs models
variable f2 = glob( "/vex/d1/lia/xstar_test/warmabs_10*.fits");
f2 = f2[ array_sort(f2) ];

variable wa_xi = xstar_load_tables(f2);

variable l1_wxi = xstar_line_ew( 11515, "na_x", wa_xi.db );
variable l2_wxi = xstar_line_ew( 11519, "na_x", wa_xi.db );

ylog;
xlabel( latex2pg( "r \log\\xi" ) );
ylabel( latex2pg( "W [\\A]" ) );
title( "warmabs models" );
plot( wa_xi.par.rlogxi, l1_wxi );
oplot( wa_xi.par.rlogxi, l2_wxi, 2 );

%% Photemis models

variable f3 = glob( "/vex/d1/lia/xstar_test/photemis_10*.fits" );
f3 = f3[ array_sort(f3) ];

variable pe_xi = xstar_load_tables(f3);

variable l1_pxi = xstar_line_ew( 11515, "na_x", pe_xi.db );
variable l2_pxi = xstar_line_ew( 11519, "na_x", pe_xi.db );

ylin;
title( "photemis models" );
plot( pe_xi.par.rlogxi, -l1_pxi );
oplot( pe_xi.par.rlogxi, -l2_pxi, 2 );




