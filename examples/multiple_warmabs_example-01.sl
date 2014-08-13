%
% multiple_warmabs_example-01.sl
% 2014.08.11 Created by lia@space.mit.edu
%
% Test use of multiple warmabs models, a la Holczer+ 2010 ApJ 708, 981
%
%=====================================================================

require("warmabs_db");

variable x1, x2 ;
(x1, x2) = linear_grid( 1.0, 40.0, 16384 );

% Absorber 1: Local (z=0) material
% Absorber 2: Fast outflow from MCG -6-30-15
% Absorber 3: Slow outflow from MCG -6-30-15
%
fit_fun("warmabs2(1) + warmabs2(2) + warmabs2(3)");

% Automatically write output model files
set_par("warmabs2(*).write_outfile", 1);
set_par("warmabs2(*).autoname_outfile", 1);

% Set some basic parameters
%
set_par( "warmabs2(1).column", -1 ); % Log10(1.e20/1.e21) ??
set_par( "warmabs2(1).rlogxi", -1.0 ); % Guess

variable colfast = log10(8.1), colslow = log10(5.3); % Guess, log10(NH/1.e21)
variable xi_fast = 3.8, xi_slow = 2.5;
set_par( "warmabs2(2).column", colfast );
set_par( "warmabs2(2).rlogxi", xi_fast );

set_par( "warmabs2(3).column", colslow );
set_par( "warmabs2(3).rlogxi", xi_fast );


variable vt_fast = 500, vt_slow = 100;
set_par( "warmabs2(1).vturb",  100.0 );
set_par( "warmabs2(2).vturb",  vt_fast );
set_par( "warmabs2(3).vturb",  vt_slow );

% The different absorbers are at various redshifts
% (some doppler, some cosmological)

variable z_mcg = 0.007749, zfast = -1900/3.e5, zslow = -100/3.e5;
set_par( "warmabs2(1).Redshift", 0.0 );
set_par( "warmabs2(2).Redshift", z_mcg+zfast );
set_par( "warmabs2(3).Redshift", z_mcg+zslow );

% Evaluate the model on the grid and load the resulting table:
%
variable y1 = eval_fun( x1, x2 ); 
variable db1 = rd_xstar_lines_output( "warmabs_1.fits" );
variable db2 = rd_xstar_lines_output( "warmabs_2.fits" );
variable db3 = rd_xstar_lines_output( "warmabs_3.fits" );

plot_bin_density;
xlabel( latex2pg( "Wavelength [\\A]" ) ) ; 
ylabel( latex2pg( "Flux [phot/cm^2/s/A]" ) );
hplot( x1, x2, y1, 1 );

define do_plt_01()
{
    xrange(1.5,5.5);
    ylog;
    hplot( x1, x2, y1, 1 );
}

%% Task 1 : Identify strongest lines from a mixture of warmabs models
%% Suggested syntax : warmabs_strong( n, dblist[; qualifiers] );

variable l1 = warmabs_strong(3, db1; wmin=1.5, wmax=5.5);
warmabs_page_group(db1, l1);

variable l2 = warmabs_strong(3, db2; wmin=1.5, wmax=5.5);
warmabs_page_group(db2, l2);

variable l3 = warmabs_strong(3, db3; wmin=1.5, wmax=5.5);
warmabs_page_group(db3, l3);

do_plt_01;
warmabs_plot_group(db1, l1, 1100; yfrac=0.8, col=2);
warmabs_plot_group(db2, l2, 1100; yfrac=0.8, col=3);
warmabs_plot_group(db3, l3, 1100; yfrac=0.8, col=4);
% ^ I still don't understand these qualifiers, what they mean

