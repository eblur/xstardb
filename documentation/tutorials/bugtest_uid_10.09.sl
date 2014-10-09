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
