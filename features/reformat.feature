@reformat
Feature: Parse the definition for reformat
  In order to allow users to specify the format for output records
  As a developer
  I should be able to run this scenario to prove that the defintion is correctly interpretted

    @current
    Scenario Outline: providing a name, a fixed position and a data type
    Given an input /reformat <input>
		And the app has numeric fields <fields>
    When parsed by ReformatG 
    Then we have the left fields <lhs_fields>
      And we have the right fields <rhs_fields> 
	
		Examples:
		|  input                              | fields                | lhs_fields   | rhs_fields   | 
    | f1	                                | f2,f1                 | f1           | []           | 
    | rightside:f21	                      | f12,f21               | []           | f21           | 
    | f3,rightside:f21	                  | f12,f21,f3            | f3           | f21           | 
    | f3,rightside:f21,f5,leftside:f4,f6	| f3,f5,f4,f6,f12,f21   | f3,f4,f6     | f21,f5          | 


  Scenario Outline: Things that should cause a parse error 
    Given an input /fields <input> 
		And the app has numeric fields <fields>
    Then parsing by ReformatG should raise Narp::ParseError 

		Examples:
		|  input                              | fields                | 
    | f1	                                | f2,f1                 | 
    | right:f21	                          | f12,f21               | 
    | f3,rightside:f21	                  | f12,f21,f31           | 
