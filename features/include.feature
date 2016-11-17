@include
Feature: Parse the include clause for the Narp language
  In order to allow users to specify what gets included in the subsequent processing / written to output
  As a developer
  I should be able to run this scenario to prove that the defintion is correctly interpretted

  Scenario Outline: Providing a valid reference to a condition
    Given an input /include <input>
		And the app has conditions <conditions_list>
    When parsed by IncludeG 
    Then I have a Include at the root
    And the included condition is <input> and is a Condition object

    Examples:
      | input             | conditions_list     |
      | cond1             | cond3, cond2, cond1 |
      | cond3             | cond3, cond2, cond1 |
      | all               | []                  |

  @current
  Scenario Outline: Providing an invalid reference to a condition
    Given an input /include <input>
		And the app has conditions <conditions_list>
    Then parsing by IncludeG should raise Narp::ParseError 

    Examples:
      | input             | conditions_list       |
      | cond1             | cond3, cond2, cond11  |
      | cond3             | []                    | 
      | Allmine           | []                    |
    
