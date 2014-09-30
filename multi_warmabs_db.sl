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
	print("This function can only take a single line index");
	return;
    }
    else return db.transition[ll], db.ion[ll];
}