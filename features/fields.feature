@fields
Feature: Parse the definition for fields
  In order to allow users to specify fields in an input file
  As a developer
  I should be able to run this scenario to prove that the defintion is correctly interpretted

    Scenario Outline: providing a name, a fixed position and a data type
    Given an input /fields <name> <position> <data_type> <length>
    When parsed by FieldsG
    And I am examining the 1st field
    Then the name is <name> 
    	And the starting byte position is <byte_position> and offset is <offset> bits
    	And the datatype is <data_type> <default_data_type>
    	And it is <dt_length> bytes long
	
		Examples:
		|  name		| position | data_type  |length |byte_position | offset | dt_length | default_data_type |
		| my_col	| 23			 | character  | 15 		|		23				 | null 	| 15  			|                   |
		| yourcol	| 15B3		 | integer  	| 			|	15					 | 3 	 	 	| null			|                   | 
		| his_col | 82B9		 | float   		| 			|		82				 | 9			| null			|                   |
		| her_col | 82B9		 |   		      | 			|		82				 | 9			| null      | character         |


    Scenario Outline: providing a name and a supported datetime datatype 
    Given an input /fields my_col 92B3 <data_type> <format>
    	When parsed by FieldsG 
      And I am examining the 1st field
    	Then I have a Field at the root
    	  And the datatype is <data_type> 
			  And it has these datetime pieces <pieces>

 		Examples:

 		| data_type | format									|pieces 									|
 		| datetime 	| year                    | year                    |
 		| datetime 	| year/mon                | year,mon                |
 		| datetime 	| yy-mm0-dd0 hh0:mi0:se0  | yy,mm0,dd0,hh0,mi0,se0 	|
 		| datetime 	| yy-mm-dd0 hh0:mi0:se0   | yy,mm,dd0,hh0,mi0,se0 	|
 		| datetime 	| yy-mnth									| yy,mnth									|
 		| datetime 	| yy-mnth-ddth            | yy,mnth,ddth            |
 		| datetime 	| yy-mnth-dd0 hh0:mi0:se0 | yy,mnth,dd0,hh0,mi0,se0 |
 		| datetime 	| yy-mnth-dd hh0:mi0:se0  | yy,mnth,dd,hh0,mi0,se0  |
 		| datetime 	| yy-mnth-day hh:mi0:se0  | yy,mnth,day,hh,mi0,se0  |
 		| datetime 	| yy-mnth-day hr:mi:se0   | yy,mnth,day,hr,mi,se0   |
 		| datetime 	| yy-mnth-day hr:mi:se    | yy,mnth,day,hr,mi,se    |

    Scenario Outline: providing a name and a delimited position
    Given an input /fields my_col <start> <stop> <format>
    When parsed by FieldsG 
    And I am examining the 1st field
    Then the start field is <start_field> with byte offset of <start_offset> 
      And the stop field is <stop_field> with byte offset of <stop_offset> 
   	  And the datatype is <data_type> <default_data_type>
		  And it has these datetime pieces <pieces>

	Examples: 
	| start | stop 			| format 		|start_field 	| start_offset| stop_field | stop_offset | data_type | pieces 			| default_data_type |
  | 23:1  |      			| integer 	| 23          |		1					| null			 | null				 |integer		 | []  					|                   |
	| 41:  	|      			|  	        | 41          |		null			| null			 | null				 | 	         | []						| character         |
  | 41:  	| -72: 			| integer 	| 41          |		null			| 72			 	 | null				 |integer 	 | []						|                   |
  | 41:  	| - 72:15  	| integer 	| 41          |		null			| 72			 	 | 15				 	 |integer 	 | []						|                   |
	| 83:3 	| -   22:0  | integer 	| 83          |		3					| 22			 	 | 0				 	 |integer 	 | []						|                   |
	| 83:3 	| -92:0 		| character	| 83          |		3					| 92			 	 | 0			 		 | character | []						|                   |
	| 83:3 	| 	| datetime yy/mm-dd	| 83          |		3					| null			 | null			 	 | datetime  | yy,mm,dd   	|                   |
	| 96:1 	| -101:	| datetime yy/mm-dd0 hh	| 96  |		1				 	| 101			 	 | null 			| datetime	 | yy,mm,dd0,hh	|                   |


    Scenario: providing a name and a precision
    Given an input /fields my_col 14:1 float 4 /1
    When parsed by FieldsG 
      And I am examining the 1st field
    Then I have a Field at the root
    	And I have 1 Field 
    	And the name is my_col
    	And the start field is 14 with byte offset of 1
    	And the datatype is float 
			And the precision is 5 and the scale is 1

    Scenario Outline: providing a name and a sequence 
    Given an input /fields my_col 14:1 character <collation> 
		  And the app has collations <collation_list>
    When parsed by FieldsG 
      And I am examining the 1st field
    Then the collation is <collation> 

		Examples:
		| collation 					| collation_list 				|
		| ascii								| []										|
		| myascii							| yourascii,myascii 		|


  Scenario Outline: providing a name and a unsupported format 
    Given an input /fields my_col 29b9 <format> 
    When parsed by FieldsG 
      And I am examining the 1st field
    Then the datatype should raise ArgumentError

		Examples:
		| format 	|
		| lz			|
		| lp			| 
		| tp 			| 
		| zd			| 
		| ls			| 
		| ts			| 
		| an			| 
		| pd			| 

  @current
  Scenario: Parsing two fields
    Given an input /fields My_col 91B3 your_col 25 
    When parsed by FieldsG 
    And I am examining the 1st field
    Then the name is My_col
    	And the starting byte position is 91 and offset is 3 bits
    	And the datatype is character
    And I am examining the 2nd field
    Then the name is your_col
    	And the starting byte position is 25 and offset is null bits
    	And the datatype is character
	
  Scenario Outline: Things that should cause a parse error 
    Given an input /fields <input> 
		And the app has collations <collation_list>
    Then parsing by FieldsG should raise ParseError 

		Examples:
		| input 																		| collation_list | message 														|
		|	my_col 14:1 character myascii							| blueshoose     | referencing unknown collation			|
		|	my_col 14:1 character myascii							| []     | referencing unknown collation			|


