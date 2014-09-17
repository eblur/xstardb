%%%
%% Examples: How ISIS interacts with AtomDB, a model for interacting with XSTAR
%% 2014.09.15 : lia@space.mit.edu
%%%

plasma(aped);  % Loads the atomic database

%% -- Create a multi-component plasma model --- %%
% Note from lia : It seems there are several ways to do this

create_aped_fun("xapec", default_plasma_state());
fit_fun("xapec(1) + xapec(2)");
list_par;

set_par("xapec(1).temperature", 1.16e8); % Equiv to 10 keV plasma temp
set_par("xapec(2).temperature", 1.16e7); % Equiv to 1 keV plasma temp

% Evaluate the plasma model
variable x1, x2;
(x1, x2) = linear_grid( 1.0, 40.0, 8192 ); 
variable y1 = eval_fun(x1, x2);

% Plot it
plot_bin_density;
xlabel( latex2pg( "Wavelength [\\A]" ) ) ; 
ylabel( latex2pg( "Flux [phot/cm^2/s/A]" ) );
ylog;
hplot(x1,x2,y1,1);

%% --- Navigating the database with ISIS --- %%

% The wl ("wavelength") function searches for transitions in the specified range (units:Angstroms)
variable adb_lines = wl(18.0, 20.0);  % Note: this is an array of characters, 0 or 1 (boolean)

% The page_group function neatly displays information from the database
page_group(where(adb_lines));

% Note there are a lot, so I'll choose just H-like and He-like Fe
variable adb_Fe = where( el_ion(Fe,[26,27]) and wl(18,20) );
page_group(adb_Fe);

% We can also choose the brightest lines (by flux) using the "brightest" function
variable lines = brightest(10, where(wl(18,20)));
page_group(lines); % Note that fluxes are attached now (as opposed to before)

% Now plot the brightest lines in this region, using the "plot_group" function
xrange(18.0, 20.0);
hplot(x1,x2,y1,1);
plot_group(lines);

%% --- Capabilities of warmabs database (warmabs_db) so far --- %%

require("warmabs_db");

% Create a system with multiple warm absorbers

% Absorber 1: Local (z=0) material
% Absorber 2: Fast outflow from MCG -6-30-15
%
fit_fun("warmabs2(1) + warmabs2(2)");
% Note: warmabs2 is a modified warmabs model, allows for automatic output naming

% Set up models to automatically write output
set_par("warmabs2(*).write_outfile", 1);
set_par("warmabs2(*).autoname_outfile", 1);

list_par;
set_par( "warmabs2(1).column", -1 ); % Log10(1.e20/1.e21) ??
set_par( "warmabs2(1).rlogxi", -1.0 ); % Guess
set_par( "warmabs2(1).vturb", 100.0 );
set_par( "warmabs2(1).Redshift", 0.0 );

set_par( "warmabs2(2).column", log10(8.1) );
set_par( "warmabs2(2).rlogxi", 3.8 );
set_par( "warmabs2(2).vturb", 500.0 );
set_par( "warmabs2(2).Redshift", 0.007749 );

% Evaluate the model on the grid and load the resulting tables:
variable y2 = eval_fun(x1, x2); 

variable wadb1 = rd_xstar_output( "warmabs_1.fits" );
variable wadb2 = rd_xstar_output( "warmabs_2.fits" );

% What's loaded is a structure (similar to an object) that stores information from the fits files
print(wadb1);

% Plot it up
xrange(1.0,40.0);
hplot(x1,x2,y2,1);

% We can perform similar functions to "wl":
variable wadb1_lines = xstar_wl(wadb1, 1.5, 5.5); 
% Note: I made this a line list instead of a string of characters

length(wadb1_lines);

% To cross-reference with elements, ions, add qualifiers
% (I see now that this is different from the standard way. I wrote this function form and can change it back if desired.)

variable wadb1_lines_S4 = xstar_wl(wadb1, 1.5, 5.5; elem=S, ion=4);

xstar_page_group(wadb1, wadb1_lines_S4);

% Identify strongest lines -- so far we can only do this one db at a time
variable s1 = xstar_strong(3, wadb1; wmin=1.5, wmax=5.5);
variable s2 = xstar_strong(3, wadb2; wmin=1.5, wmax=5.5);

xstar_page_group(wadb1, s1);
xstar_page_group(wadb2, s2);

xrange(1.5, 5.5);
hplot(x1,x2,y2,1);

xstar_plot_group(wadb1, s1, 2);
xstar_plot_group(wadb2, s2, 3);

%% One of our issues seems to be that these line "ids" are not unique (transition # ??)
%% AtomDB is one go-to database, but XSTAR output is post-processed; we need a central db for reference