@simple
Feature: Parse the join clause for the Narp language
  In order to allow users to specify what gets included in the subsequent processing / written to output
  As a developer
  I should be able to run this scenario to prove that the defintion is correctly interpretted

  @join
  Scenario Outline: Providing a valid join clause
    Given an input /join unPaired <input>
    When parsed by SimpleG 
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


  @join
  Scenario Outline: Join clause that should cause a parse error 
    Given an input /join <input> 
    Then parsing by SimpleG should raise Narp::ParseError 

    Examples:
      | input   |
      | unPeared |
      | leftside |
      | unpaired rightside leftside |
      | unpaired rightside only leftside |

  @copy
  Scenario: The copy clause
    Given an input /copy
    When parsed by SimpleG
    Then I have a Copy at the root
    
  @collatingsequence
  Scenario: The miniminal collating sequence clause
    Given an input /collatingsequence default ascii
    When parsed by SimpleG
    Then I have a CollatingSequence at the root
