@condition
Feature: Parse the conditions
  In order to allow users to affect what gets generated by Narp
  As a developer
  I should be able to run this scenario to prove that the defintion is correctly interpretted

  Scenario Outline: providing an arithmetic expression 
    Given an input /condition <condition>
    When parsed by ConditionG 
   	And the sql is <sql>
  
  	Examples:
    | condition 				|  sql |
    | my_cond	23+ 79= 102			 	|  	23 + 79 = 102 |
    | my_cond	79 lt 102 * (25 - 33)			 	| 79 < 102 * (25 - 33) |
    | y_cond 23+71eq94			 	  |  	23 + 71 = 94 |
    | b_cond (23+71)* 23=94		|  	(23 + 71) * 23 = 94 |
    | c_cond (23+71)*( 51+4)=94|  	(23 + 71) * (51 + 4) = 94 |
    | d_cond (23+71)/( 51-4)+5 ne 94 |  	(23 + 71) / (51 - 4) + 5 != 94  |
    | e_cond (23+71)/( 51-4)+5 < 94  |  	(23 + 71) / (51 - 4) + 5 < 94   |
    | f_cond (23+71)/( 51-4)+5 ge 78-(24*93) |  	(23 + 71) / (51 - 4) + 5 >= 78 - (24 * 93)  |
    | g_cond (23+71) ge 78-(24*93) or 5 < 3 |  	(23 + 71) >= 78 - (24 * 93) OR 5 < 3 |
    | g_cond ((23+71) ge 78 or 5 < 3) |  	((23 + 71) >= 78 OR 5 < 3) |
    | i_cond ((23+71) ge 78+15) or (5 < 3) |  	((23 + 71) >= 78 + 15) OR (5 < 3) |
    | j_cond (((23+71) ge 78+15) and (5 < 3)) |  	(((23 + 71) >= 78 + 15) AND (5 < 3)) |
  

  @current
  Scenario Outline: providing a character expression 
    Given an input /condition <name> <condition>
    When parsed by ConditionG 
   	Then the condition is called <name> 
    And the sql is <sql>
  
  	Examples:
  	|  name		  | condition 				              |  sql |
    | my_cond	  | 'Blue' nc 'green'			 	        | LOCATE('green', 'Blue') = 0|
    | b_cond	  | 'blue '' goo ' mt 'green'			 	| 'blue '' goo ' = 'green' |
  	| c_cond	  | "blue "" goo " ct "green"			 	| LOCATE('green', 'blue "" goo ') > 0 |
    | d_cond	  | "blue" mt /u/			 	            | 'blue' RLIKE 'u' |
  

  Scenario Outline: Providing a character/numeric expression with field references
    Given an input /condition <condition>
    And an existing app that is reinitialized
		And the app has numeric fields <numeric_field_list>
		And the app has character fields <character_field_list>
    When parsed by ConditionG 
    And the sql is <sql>

  	Examples:
  	| condition 				                  |numeric_field_list  | character_field_list |  sql |
  	| mycond int6 + 5 > 10                       |	int6, int9         | []                   | lhs_int6 + 5 > 10|
  	| mycond 5"blue" ct "green" or int6 < 10    |	int6, int9         | []                   | LOCATE('green', 'blueblueblueblueblue') > 0 OR lhs_int6 < 10|
    | mycond int6 < 10 AND 5"blue" ct "green"    |	int6, int9         | []                   | lhs_int6 < 10 AND LOCATE('green', 'blueblueblueblueblue') > 0 |
    | mycond 'blue' mt 'green' AnD ch5 mt /ye/	  | []                 | ch5, ch6             | 'blue' = 'green' AND lhs_ch5 RLIKE 'ye' |
  	| mycond "blue "" goo " mt /ue/ AND ch5 mt /\d+/		| []           | ch6, ch5             | 'blue "" goo ' RLIKE 'ue' AND lhs_ch5 RLIKE '\d+' |
  	| mycond (3"blue" ct "green" aND int6 < 9) or cha5 mt /yE/i   |	int6, int9         | ch4,cha5,col1         | (LOCATE('green', 'blueblueblue') > 0 AND lhs_int6 < 9) OR LOWER(lhs_cha5) RLIKE 'ye'|
    | mycond cha5 = "     "                      |	int6, int9         | ch4,cha5,col1         | lhs_cha5 = '     ' |
  
