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


require("warmabs_vs_xi_test");
%%-------------------------------%%
%% Taken from warmabs_vs_xi_test.sl, with modifications from me

variable f, t, k;
f = glob( "/vex/d1/logxi_test/warmabs_10*.fits");
f = f[ array_sort( f ) ] ; 
tic; t = xstar_load_tables( f ); toc;
% ~ 8.5

k = 50 ; 
xstar_page_group( t.db[k],  xstar_strong( 10, t.db[k]; wmin=13, wmax=14 ) );

variable uid, y;
% manually pick out Ne VII 13.83; uid should have length [1]:
uid = t.db[k].uid[ where( t.db[k].transition == 10453 ) ];

tic; y = xstar_collect_value( t, uid[0], "ew" ); toc;
% ~ 0.00007
pointstyle(24);
plot( t.par.rlogxi, y );

%% Test of find_line function (multi_warmabs_db)

require("multi_warmabs_db");
variable test_fl;
tic; test_fl = find_line( 10453, "ne_vii", t.db ); toc;
% ~ 0.005

%variable i;
%for (i=0; i<length(test_fl); i++) xstar_page_group(t.db[i], where(test_fl[i]));;

variable ew_test = xstar_line_ew( 10453, "ne_vii", t.db);
pointstyle(0);
oplot( t.par.rlogxi, ew_test, 2 );

%% Test line_id finding thingy
variable index = xstar_strong( 10, t.db[k]; wmin=13, wmax=14 );
variable id0, ion0;
(id0, ion0) = line_id(t.db[k], index[0]);

% Here's something neat you can do
variable ew_test2 = xstar_line_ew( line_id(t.db[k],index[0]), t.db );
plot(t.par.rlogxi, ew_test2, 1);