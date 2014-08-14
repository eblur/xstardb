
% 2014.08.13 - lia
%
% Test to be sure that basic functions work
%
%% NOTE: On first run, be sure to uncomment test_autoname_outfile
%% All of the test function calls are list at the end

require("warmabs_db");

%%---------------------------------------%%
%% Test of autoname outfile

variable x1, x2, y;
(x1, x2) = linear_grid( 1.0, 40.0, 16384 );

define test_autoname_outfile()
{
    fit_fun( "Powerlaw(1) * warmabs2(1) + photemis2(123)"  );
    set_par( "warmabs2(1).write_outfile",  1 );
    set_par( "photemis2(123).write_outfile",  1 );
    set_par( "*.autoname_outfile", 1 );
    
    y = eval_fun(x1, x2);
}


%%---------------------------------------%%
%% Test of read db functions

variable wa, pe;

define test_read_db()
{
    wa = rd_warmabs_output("warmabs_1.fits");
    pe = rd_photemis_output("photemis_123.fits");
}

%%---------- After first autoname, must load dbs ----------%%

%test_autoname_outfile;
test_read_db;

%%---------------------------------------%%
%% Test of wavelength selection from db
%% And qualifiers "elem" and "ion"

variable MIN = 3.0, MAX = 3.5;
variable iwa = warmabs_wl(wa, MIN, MAX);
variable ipe = photemis_wl(pe, MIN, MAX);

define test_xstar_wl()
{
    print("Features selected from warmabs model:");
    warmabs_page_group(wa, iwa);
    print("Features selected from photemis model:");
    warmabs_page_group(wa, ipe);
}

% Right now the qualifiers only work for xstar_wl
define test_xstar_wl_qualifiers()
{
    print("Testing xstar_wl qualifiers, return Ca V lines only");
    variable iwa2 = xstar_wl(wa, 3.0, 3.5; elem=Ca, ion=5);
    warmabs_page_group(wa, iwa2);
}

%%---------------------------------------%%
%% Test xstar_strong and qualifiers
%% This also tests the warmabs_page_group sorting qualifiers

variable nstrong = 10;
variable iwa_strong = xstar_strong(nstrong, wa; wmin=MIN, wmax=MAX);

% warmabs default: field="ew" and emis=0
define test_warmabs_strong()
{
    variable wa_ew = get_struct_field(wa,"ew")[iwa];
    variable isort = array_sort(wa_ew);
    
    print("The largest equiv widths:");
    print(wa_ew[isort[[-nstrong:]]]);

    print("The list returned from xstar_strong");
    warmabs_page_group(wa, iwa_strong; sort="ew");
}
%% Okay, this is correct (note difference in format)

%%---------------------------------------%%
%% Test sorting cases for warmabs_page_group

define test_warmabs_page_group_sorting()
{
    print("Sorting photoemis by luminosity");
    warmabs_page_group(pe, ipe; sort="luminosity");
    
    print("Sorting photoemis by nothing");
    warmabs_page_group(pe, ipe; sort="none");

    print("Sorting warmabs by tau0");
    warmabs_page_group(wa, iwa[[0:10]]; sort="tau0");
}


%%------- TEST FUNCTION CALLS ----------------%%
%% Modify this portion to turn on various tests

%test_xstar_wl;
%test_xstar_wl_qualifiers;

test_warmabs_strong;

test_warmabs_page_group_sorting;
