%%%%
%% 2014.09.30 - lia@space.mit.edu
%%
%% multi_warmabs_db.sl -- Test functions for playing with multiple
%%    XSTAR fits file outputs
%%%%

%define find_line( transition_id, ion_string, struct_list )
%{
%    variable s, ltemp, result=Integer_Type[0];
%    foreach s (struct_list)
%    {
%	ltemp = where( s.transition == transition_id and s.ion == ion_string );
%	if (length(ltemp) != 0) result = [result, ltemp];
%	else result = [result, -1];
%    }
%    return result;
%}

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

%% Get the transition number and ion string based on line index
%% (products of where(xstar_wl) and where(xstar_el_ion) type outputs
%
% USAGE: (id, ion) = line_id( db, ll );
% RETURNS: transition id (integer) and ion name (string)
%
define line_id( db, ll )
{
    if (length(ll) > 1) 
    {
	print("line_id function can only take one line index as input");
	return;
    }
    else return db.transition[ll], db.ion[ll];
}

%%----------------------------------------------------------------------%%
%% Analogs to single database case

%% Search set of databases for lines within a wavelength range
%
% USAGE: xstar_wl_all([s1,s2], wlo, whi);
% RETURNS: An array of character arrays (booleans) specifying which lines lay
%          within a certain wavelength range.

define xstar_wl_all(struct_list, wlo, whi)
{
    variable i, temp, result = Array_Type[length(struct_list)];
    for (i=0; i<length(struct_list); i++)
    {
	temp = struct_list[i].wavelength > wlo and struct_list[i].wavelength <= whi;
	result[i] = temp;
    }
    return result;
}

%% Page through a set of databases for a set of lines
%
% USAGE: xstar_page_all([s1,s2], [bool1, bool2]);
% RETURNS: Prints line information sequentially from database
%          structure s1 and s2
%
define xstar_page_all(struct_list, bool_list)
{
    variable i;
    for (i=0; i<length(struct_list); i++)
    {
	print("Model " + string(i+1));
	xstar_page_group( struct_list[i], where(bool_list[i]) );
    }
}



%% Merge two XSTAR models into a single database structure
%
% USAGE: merge_xstar_output([s1,s2,s3])
% RETURNS: A database structure with an extra column, db_fname
%
define merge_xstar_output( db_list )
{
    variable fields = get_struct_field_names(db_list[0]);
    variable result = @db_list[0];
    variable i, ff, temp1, temp2;
    for (i=1; i<length(db_list); i++)
    {
	foreach ff (fields)
	{
	    temp1 = get_struct_field( result, ff );
	    temp2 = get_struct_field( db_list[i], ff );
	    set_struct_field( result, ff, [temp1, temp2] );
	}
    }
    return result;
}

