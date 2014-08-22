% 2014.04.22 dph
%
% test new FITS output version of photemis model
% copied from warmabs_example-02.sl, modified for photemis case.
%
% 2014.08.07 lia - updated to v1.1 for testing on vex
%      08.22 lia - updated for warmabs -> xstar function name change
require( "warmabs_db");

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% misc. plotting utilities:

stdpltsetup; resize(20,0.5);

variable x1, x2 ;
%(x1, x2) = linear_grid( 1.0, 40.0, 16384 ) ; 
(x1, x2) = linear_grid( 1.0, 40.0, 8192 ) ; 

% Define a model;  warmabs is an xspec local model:

fit_fun( "photemis2( 1 )" ); 

% define output file:
set_par( "photemis2(1).autoname_outfile", 1 );
set_par( "photemis2(1).write_outfile", 1 );

variable ph_norm = 1.0, ph_xi  = 2.5, ph_vt  = 100 ; 

set_par( "photemis2(1).norm",   ph_norm ) ;
set_par( "photemis2(1).rlogxi", ph_xi ) ;
set_par( "photemis2(1).vturb",  ph_vt  ) ;

save_par( "photemis2-001.par");

% evaluate the model on the grid, and load the resulting output table:
%
variable y1 = eval_fun( x1, x2 ) ; 
variable c1 = rd_photemis_output( "photemis_1.fits");

% Look at the spectrum:

define do_plt_01()
{
    plot_bin_density;
    xlabel( latex2pg( "Wavelength [\\A]" ) ) ; 
    ylabel( latex2pg( "Flux [phot/cm^2/s/A]" ) );
    xrange; xlin;  yrange; ylin; 
    cp1;pst; hplot( x1, x2, y1, 1 ) ; 
}

do_plt_01;

variable s = "a photemis model spectrum:" ; 
message(s); pltid( s; size=1.4, color=4 );
plot_pause; 

% get list of strongest features in a wavelength range:

define do_plt_02()
{
    plot_bin_density;
    variable la = xstar_strong(  1, c1; wmin = 13, wmax = 15, type="edge" );
    variable lb = xstar_strong( 10, c1; wmin = 13, wmax = 15, emis );
    xrange( 13, 15 ) ; yrange( 0 ) ;
    variable lx = where( x1 >= 13 and x2 <= 15 );
    variable ymax = max( y1[lx] / (x2[lx]-x1[lx])) ;
    cp1;pst; hplot( x1, x2, y1, 1 ) ; 
    xstar_plot_group( c1, lb );
    xstar_plot_group( c1, la );
}

do_plt_02;
s = "Strongest features in 13--15A region:";
message(s); pltid(s ; size=1.4, color=4);
xstar_page_group( c1, xstar_strong( 10, c1; wmin = 13, wmax = 15 ) );
% Test for difference between emis qualifier and normal - lia
%
xstar_page_group( c1, xstar_strong( 10, c1; wmin = 13, wmax = 15, emis ) );
plot_pause; 


% find Ne features
%

define do_plt_03()
{
    variable lne = xstar_strong( 10, c1; elem = Ne, wmin=10, wmax=14 );
    xrange(10,14);;
    cp1;pst; hplot( x1, x2, y1,1 ) ; 
    xstar_plot_group( c1, lne );
}

do_plt_03;
s = "Mark strong Ne features:";
message(s); pltid(s ; size=1.4, color=4);
plot_pause; 


define do_plt_04()
{
    variable l  = xstar_strong( 20, c1; wmin=18.2, wmax=19.5);
    variable lo = xstar_strong( 10, c1; elem=O, wmin=18.2, wmax=19.5 );
    xrange( 18.2, 19.5);
    ylog;
    cp1;pst; hplot( x1, x2, y1,1 ) ; 
    xstar_plot_group( c1, l );
    xstar_plot_group( c1, lo );
    ylin;
}

do_plt_04;
s="Strong features in 18.2--19.5A range:";
message(s); pltid(s ; size=1.4, color=4);
plot_pause; 


% look for edges:
define do_plt_05()
{
    variable l1 = xstar_strong( 5, c1; wmin=10, wmax=85, type="edge",  field="luminosity");
    variable l2= xstar_strong(  5, c1; wmin=18, wmax=20, type="edge", field="luminosity");
    xrange( 10, 20);
    ylog;
    cp1;pst; hplot( x1, x2, y1,1 ) ; 
    xstar_plot_group( c1, l1 );
    xstar_plot_group( c1, l2 );
    ylin;
}

do_plt_05;
s="Look for edge features:";
message(s); pltid(s ; size=1.4, color=4);
plot_pause;
xstar_page_group( c1, xstar_strong( 10, c1; wmin=10, wmax=20, type="edge", field="luminosity") );

define do_plt_06()
{
    variable l  = xstar_strong( 1, c1; wmin=13, wmax=15, type="edge", field="luminosity");
    variable l2 = xstar_strong( 10, c1; wmin=13, wmax=15, type="line", field="luminosity");
    xrange( 13, 15 );
    cp1;pst; hplot( x1, x2, y1,1 ) ; 
    xstar_plot_group( c1, l );
    xstar_plot_group( c1, l2 );
}

do_plt_06;
s="Strongest features in 13--16A region:";
message(s); pltid(s ; size=1.4, color=4);
plot_pause;
xstar_page_group( c1, xstar_strong( 1, c1; wmin=13, wmax=15, type="edge", field="luminosity") );
xstar_page_group( c1, xstar_strong( 10, c1; wmin=13, wmax=15, type="line", field="luminosity") );


variable pid; 

message( "Create plots and feature tables:");

pid = open_plot("ph_example_01.ps/vcps"); stdpltsetup; _pgscf(1); resize(16,0.6);
do_plt_01;
close_plot(pid); window(1);

pid = open_plot("ph_example_02.ps/vcps"); stdpltsetup; _pgscf(1); resize(16,0.6);
do_plt_02;
close_plot(pid); window(1);

pid = open_plot("ph_example_03.ps/vcps"); stdpltsetup; _pgscf(1); resize(16,0.6);
do_plt_03;
close_plot(pid); window(1);

pid = open_plot("ph_example_04.ps/vcps"); stdpltsetup; _pgscf(1); resize(16,0.6);
do_plt_04;
close_plot(pid); window(1);

pid = open_plot("ph_example_05.ps/vcps"); stdpltsetup; _pgscf(1); resize(16,0.6);
do_plt_05;
close_plot(pid); window(1);

pid = open_plot("ph_example_06.ps/vcps"); stdpltsetup; _pgscf(1); resize(16,0.6);
do_plt_06;
close_plot(pid); window(1);

xstar_page_group( c1, xstar_strong( 20, c1; wmin=18, wmax=23) );
xstar_page_group( c1, xstar_strong( 20, c1; wmin=18, wmax=23); file="wa_list_01.tbl" );
xstar_page_group( c1, xstar_strong(  5, c1; wmin=5, wmax=10, type="edge", field="tau0"); file="ph_edge_list_01.tbl" );
