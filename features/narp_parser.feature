@narp_parser
Feature: Parse a narp statement 
  In order to allow users to specify the components of a ETL application 
  As a developer
  I should be able to run this scenario to prove that the Narp understands its own language

  Scenario: Parsing an infile defintion
    Given an input /infile 'My text_file.txt' alias moo x"73"  Sequential compressed highcompression 349 15 	fskiprecord 15 fstopafter 87
    When parsed by Narp 
    Then I have a Infile at the root
    And the original filename is My text_file.txt
    And the field seperator is s
    And the alias is moo
    And the record length is 15, 349
    And the organization is sequential
    And the compressed is high 
    And skip to record 15 
    And stop after 87 records 


	Scenario: Provding an outfile definition
    Given an input /outfile 'My text_file.txt' Sequential compressed 49 325 "\t" appeNd recordnumber 22
    When parsed by Narp 
    Then I have a Outfile at the root
    And I have an organization
    And the original filename is My text_file.txt
    And the organization is sequential
    And the compressed is normal 
    And the record length is 49, 325
    And the field seperator is \t
    And the record number starts at 22 
    And the disposition is append 

  Scenario Outline: providing a name and a delimited position
    Given an input /fields my_col <start> <stop> <format>
    When parsed by Narp 
      And I am examining the 1st field
    Then the start field is <start_field> with byte offset of <start_offset> 
    And the stop field is <stop_field> with byte offset of <stop_offset> 
   	And the datatype is <data_type>
		And it has these datetime pieces <pieces>

	Examples: 
	| start | stop 			| format 		|start_field 	| start_offset| stop_field | stop_offset | data_type | pieces 			|
	| 23:1  |      			|integer 		| 23          |		1					| null			 | null				 |integer		 | []  					|
	| 41:  	|      			|integer 		| 41          |		null			| null			 | null				 |integer 	 | []						|

  Scenario Outline: Providing a character/numeric expression with field references
    Given an input /condition <name> <condition>
		And the app has numeric fields <numeric_field_list>
		And the app has character fields <character_field_list>
    When parsed by Narp 
   	Then the condition is called <name> 
    And the hql is <hql>
  
  	Examples:
  	|  name		  | condition 				                  |numeric_field_list  | character_field_list |  hql |
  	| c_cond	  | 5"blue" ct "green" anD int6 < 10    |	int6, int9         | []                   | LOCATE('green', 'blueblueblueblueblue') > 0 AND lhs_int6 < 10|
  	| d_cond	  | int6 < 10 and 5"blue" ct "green"    |	int6, int9         | []                   | lhs_int6 < 10 AND LOCATE('green', 'blueblueblueblueblue') > 0 |


  Scenario Outline: Providing a valid reference to a condition
    Given an input /include <input>
		And the app has conditions <conditions_list>
    When parsed by Narp 
    Then I have a Include at the root
    And the included condition is <input> and is a Condition object

    Examples:
      | input             | conditions_list     |
      | cond1             | cond3, cond2, cond1 |
      | cond3             | cond3, cond2, cond1 |


  Scenario Outline: Providing a valid join clause
    Given an input /join unPaired <input>
    When parsed by Narp 
    Then I have a Join at the root
    And the value is <value>

    Examples:
      | input                   | value         |
      | leftside                | left join     |
      | rightside               | right join    |
      | leftside rightside      | full join     |
      |                         | full join     |
      | leftside rightside only | xor           |
      | only                    | xor           |
      | leftside only           | left not in   |
      | rightside only          | right not in  |


  Scenario Outline: Providing a valid join key clause
    Given an input /joinkeys <input>
    And an existing app that is reinitialized
		And the app has numeric fields <fields>
    When parsed by Narp 
    Then I have a JoinKeys at the root
    And these keys <list>
		And the keys are Field objects 
    And the sort attribute is <sort>

    Examples: 
      | input              | fields           | list       | sort     |
      | sorted c1          | b1,c1            | c1         | sorted   |
      |  c3,f1             | c5,f2,f1,c3,c1   | c3,f1      | null     |
      |  sorted f2,c3,c9   | f2,c9,c2,c3,f9   | f2,c3,c9   | sorted   |
      |  f2                | f2,c9,c2,c3,f9   | f2         | null     |


    Scenario Outline: providing a name, a fixed position and a data type
    Given an input /reformat <input>
		And the app has numeric fields <fields>
    When parsed by Narp
    Then we have the left fields <lhs_fields>
      And we have the right fields <rhs_fields> 
	
		Examples:
		|  input                              | fields                | lhs_fields   | rhs_fields   | 
    | f1	                                | f2,f1                 | f1           | []           | 
    | rightside:f21	                      | f12,f21               | []           | f21           | 
    | f3,rightside:f21	                  | f12,f21,f3            | f3           | f21           | 
    | f3,rightside:f21,f5,leftside:f4,f6	| f3,f5,f4,f6,f12,f21   | f3,f4,f6     | f21,f5          | 


  Scenario Outline: providing a character/numeric expression 
    Given an input /derivedfield <name> <expression>
    And an existing app that is reinitialized
		And the app has numeric fields fn1, fn2, fn3
		And the app has character fields fc1, fc2
    When parsed by Narp 
   	Then the name is <name> 
    And the column expression is <column_expression>
    And the sequence is <sequence> 

    Examples:
      | name      | expression                             | column_expression            							| sequence 	| 
      | calc1     | fc1                                    | lhs_fc1 AS calc1   														| null			|
      | calc2     | fc2 23 compress ascii                  | TRIM(CAST(lhs_fc2 AS VARCHAR(23))) AS calc2   	| ascii 		|
      | calc2     | fc2 character 28 compress ascii        | TRIM(CAST(lhs_fc2 AS VARCHAR(28))) AS calc2   	| ascii 		|
      | calc2     | fc2 54 character compress ascii        | TRIM(CAST(lhs_fc2 AS VARCHAR(54))) AS calc2   	| ascii 		|
      | calc3     | 23,000 en 6 compress                   | TRIM(CAST(23000 AS VARCHAR(6))) AS calc3   | null      |
      | calc4     | 23 uinteger 8                          | CAST(23 AS VARCHAR(8)) AS calc4            | null      |
      | calc5     | 92.5 float 4                           | CAST(92.5 AS VARCHAR(4)) AS calc5          | null      |
      | calc5     | fn1 + 92.5 float 4                     | CAST(lhs_fn1 + 92.5 AS VARCHAR(4)) AS calc5          | null      |
      | calc6     | 13,292.5 extract /(\d+).+(\d+)/ '#1k' compress   | TRIM(CONCAT('', REGEXP_EXTRACT(13292.5, '(\\\\\d+).+(\\\\\d+)', 1), 'k')) AS calc6 | null |
      | calc7     | 29,333.53 en 10 4/1 | CONCAT(CAST(SPLIT(29333.53, '\\.')[0] AS VARCHAR(4)), '.', CAST(SPLIT(29333.53, '\\.')[1] AS VARCHAR(1))) AS calc7 | null |
      | calc8     | 29,333.53 En 10 4 | CAST(SPLIT(29333.53, '\\.')[0] AS VARCHAR(4)) AS calc8 | null |
      

  Scenario Outline: providing a character regex 
    Given an input /derivedfield <name> <expression>
    And an existing app that is reinitialized
    And the app has numeric fields fn1, fn2, fn3
		And the app has character fields fc1, fc2
    When parsed by Narp
   	Then the name is <name> 
    And the column expression is <column_expression>

    Examples:
      | name      | expression                                      | column_expression                                                                       |
      | calc1     | 'bluecheese' extract /(.+)cheese/i 'cheese: #1' truncate | RTRIM(CONCAT('cheese: ', REGEXP_EXTRACT(LOWER('bluecheese'), '(.+)cheese', 1))) AS calc1 |
      | calc2     | fc1 extract /(.+)chee(.+)/i 'cheese: #2; then #1' | CONCAT('cheese: ', REGEXP_EXTRACT(LOWER(lhs_fc1), '(.+)chee(.+)', 2), '; then ', REGEXP_EXTRACT(LOWER(lhs_fc1), '(.+)chee(.+)', 1)) AS calc2 |

  Scenario Outline: providing an if expression 
    Given an input /derivedfield <name> <expression>
    And an existing app that is reinitialized
		And the app has numeric fields fn1, fn2, fn3
		And the app has character fields fc1, fc2
    And the app has conditions cond2, cond5, cond7
    When parsed by Narp
   	Then the name is <name> 
    And the column expression is <column_expression>

    Examples:
      | name      | expression                         | column_expression                                              |
      | calc1     | if cond2 then 25.3 else 56         | CASE WHEN _cond2_ THEN 25.3 ELSE 56 END AS calc1   |
      | calc2     | if cond2 then if cond5 then 22 + fn1 else 23 else 56         | CASE WHEN _cond2_ THEN CASE WHEN _cond5_ THEN 22 + lhs_fn1 ELSE 23 END ELSE 56 END AS calc2   |
      | calc3     | if cond2 then if cond5 then 22 + fn1 else if cond7 then 15+fn3 else 0 else 56         | CASE WHEN _cond2_ THEN CASE WHEN _cond5_ THEN 22 + lhs_fn1 ELSE CASE WHEN _cond7_ THEN 15 + lhs_fn3 ELSE 0 END END ELSE 56 END AS calc3   |


  Scenario Outline: A derived expression referencing another derived_expression
    Given an input /derivedfield <name> <expression>
    And an existing app that is reinitialized
		And the app has numeric fields fn1, fn2, fn3
		And the app has character fields fc1, fc2
		And the app has derived fields fd1, fd2
    And the app has conditions cond2, cond5, cond7
    When parsed by Narp
   	Then the name is <name> 
    And the column expression is <column_expression>

    Examples:
      | name      | expression                                  | column_expression                                                                 |
      | calc2     | fd1 + 25.3 + 56 + fd2                       |  (_fd1_) + 25.3 + 56 + (_fd2_) AS calc2    |
      | calc3     | fn1 + 25.3 + fd2 * 19                       |  lhs_fn1 + 25.3 + (_fd2_) * 19 AS calc3    |
      | calc4     | if cond2 then fd1 + 25.3 else 56 + fd2      | CASE WHEN _cond2_ THEN (_fd1_) + 25.3 ELSE 56 + (_fd2_) END AS calc4    |
      | calc5     | if cond2 then fn1 / 25.3 else 56 + fd2      | CASE WHEN _cond2_ THEN lhs_fn1 / 25.3 ELSE 56 + (_fd2_) END AS calc5    |
      | calc6     | fd1 compress | TRIM((_fd1_)) AS calc6 |



