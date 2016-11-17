@join_keys
Feature: Parse the join key clause for the Narp language
  In order to allow users to specify what gets included in the subsequent processing / written to output
  As a developer
  I should be able to run this scenario to prove that the defintion is correctly interpretted

  Scenario Outline: Providing a valid join key clause
    Given an input /joinkeys <input>
    And an existing app that is reinitialized
		And the app has numeric fields <fields>
    When parsed by JoinKeysG 
    Then I have a JoinKeys at the root
    And these keys <list>
		And the keys are Field objects 
    And the sort attribute is <sort>

    Examples: 
      | input                   | fields                  | list       | sort     |
      | sorted c1               | b1,c1                   | c1         | sorted   |
      |  c3,f1                  | c5,f2,f1,c3,c1          | c3,f1      | null     |
      |  sorted f2,c3,c9        | f2,c9,c2,c3,f9          | f2,c3,c9   | sorted   |


  @current
  Scenario Outline: Join key clause that should cause a parse error 
    Given an input /joinkeys <input> 
    And an existing app that is reinitialized
		And the app has numeric fields <fields>
    Then parsing by JoinKeysG should raise Narp::ParseError 

    Examples:
      | input                   | fields                  | 
      | snorted               	| b1,c1                   | 
      | c3,f1                  	| c5,f2,f11,c13,c1        | 
      | sorted f2,c3,c9        	| f2,cl9,c2,c3,f9          | 
