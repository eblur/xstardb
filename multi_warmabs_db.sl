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




