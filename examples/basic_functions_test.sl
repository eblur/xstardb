
% 2014.08.13 - lia
%
% Test to be sure that basic functions work

require("warmabs_db");

%% Test of autoname outfile

fit_fun( "Powerlaw(1) * warmabs2(1) + photemis2(123)"  );
set_par( "warmabs2(1).write_outfile",  1 );
set_par( "photemis2(123).write_outfile",  1 );
set_par( "*.autoname_outfile", 1 );

variable x1, x2 ;
(x1, x2) = linear_grid( 1.0, 40.0, 16384 );

variable y = eval_fun(x1, x2);

%% Test of read db functions

variable wa = rd_warmabs_output("warmabs_1.fits");
variable pe = rd_photemis_output("photemis_123.fits");

%% Test of wavelength selection from db
%% And qualifiers "elem" and "ion"

variable iwa = warmabs_wl(wa, 3.0, 3.5);
variable ipe = photemis_wl(pe, 3.0, 3.5);

warmabs_page_group(wa, iwa);

% Right now the qualifiers only work for xstar_wl
variable iwa2 = xstar_wl(wa, 3.0, 3.5; elem=Ca, ion=5);
warmabs_page_group(wa, iwa2);

% There are no lines found in this model between 2 and 3, by the way
% So this returns nothing / null
variable ii = xstar_wl(pe, 2.0, 3.0);

