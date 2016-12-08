@derived_field
Feature: Parse the derived fields 
  In order to allow users to affect what gets generated by Narp
  As a developer
  I should be able to run this scenario to prove that the defintion is correctly interpretted

  @current
  Scenario Outline: providing a character/numeric expression 
    Given an input /derivedfield <expression>
    And an existing app that is reinitialized
		And the app has numeric fields fn1, fn2, fn3
		And the app has character fields fc1, fc2
    When parsed by DerivedFieldG 
    Then the column expression is <column_expression>
    And the sequence is <sequence> 

    Examples:
      | expression                                   | column_expression            							| sequence 	| 
      | calc1 fc1                                    | lhs_fc1 AS calc1   														| null			|
      | calc1 -5 * 20                                | - 5 * 20 AS calc1   														| null			|
      | calc2 fc2 23 compress ascii                  | TRIM(CAST(lhs_fc2 AS VARCHAR(23))) AS calc2   	| ascii 		|
      | calc2 fc2 character 28 compress ascii        | TRIM(CAST(lhs_fc2 AS VARCHAR(28))) AS calc2   	| ascii 		|
      | calc2 fc2 54 character compress ascii        | TRIM(CAST(lhs_fc2 AS VARCHAR(54))) AS calc2   	| ascii 		|
      | calc3 23,000 en 6 compress                   | TRIM(CAST(23000 AS VARCHAR(6))) AS calc3   | null      |
      | calc4 23 uinteger 8                          | CAST(23 AS VARCHAR(8)) AS calc4            | null      |
      | calc5 92.5 float 4                           | CAST(92.5 AS VARCHAR(4)) AS calc5          | null      |
      | calc5 fn1 + 92.5 float 4                     | CAST(lhs_fn1 + 92.5 AS VARCHAR(4)) AS calc5          | null      |
      | calc6 13,292.5 extract /(\d+).+(\d+)/ '#1k' compress   | TRIM(CONCAT(REGEXP_EXTRACT(13292.5, '(\\\\\d+).+(\\\\\d+)', 1), 'k')) AS calc6 | null |
      | calc7 29,333.53 en 10 4/1 | CONCAT(CAST(SPLIT(29333.53, '\\.')[0] AS VARCHAR(4)), '.', CAST(SPLIT(29333.53, '\\.')[1] AS VARCHAR(1))) AS calc7 | null |
      | calc8 29,333.53 En 10 4 | CAST(SPLIT(29333.53, '\\.')[0] AS VARCHAR(4)) AS calc8 | null |
      

  Scenario Outline: providing a character regex 
    Given an input /derivedfield <name> <expression>
    And an existing app that is reinitialized
    And the app has numeric fields fn1, fn2, fn3
		And the app has character fields fc1, fc2
    When parsed by DerivedFieldG
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
    When parsed by DerivedFieldG 
   	Then the name is <name> 
    And the column expression is <column_expression>

    Examples:
      | name      | expression                         | column_expression                                              |
      | calc1     | if cond2 then 25.3 else 56         | CASE WHEN _cond2_ THEN 25.3 ELSE 56 END AS calc1   |
      | calc2     | if cond2 then if cond5 then 22 + fn1 else 23 else 56         | CASE WHEN _cond2_ THEN CASE WHEN _cond5_ THEN 22 + lhs_fn1 ELSE 23 END ELSE 56 END AS calc2   |
      | calc3     | if cond2 then if cond5 then 22 + fn1 else if cond7 then 15+fn3 else 0 else 56         | CASE WHEN _cond2_ THEN CASE WHEN _cond5_ THEN 22 + lhs_fn1 ELSE CASE WHEN _cond7_ THEN 15 + lhs_fn3 ELSE 0 END END ELSE 56 END AS calc3   |


  Scenario Outline: A derived expression referencing another derived_expression
    Given an input /derivedfield <expression>
    And an existing app that is reinitialized
		And the app has numeric fields fn1, fn2, fn3
		And the app has character fields fc1, fc2
		And the app has derived fields fd1, fd2
    And the app has conditions cond2, cond5, cond7
    When parsed by DerivedFieldG 
    And the column expression is <column_expression>

    Examples:
      | expression                                  | column_expression                                                                 |
      | calc2 fd1 + 25.3 + 56 + fd2                       |  (_fd1_) + 25.3 + 56 + (_fd2_) AS calc2    |
      | calc3 fn1 + 25.3 + fd2 * 19                       |  lhs_fn1 + 25.3 + (_fd2_) * 19 AS calc3    |
      | calc4 if cond2 then fd1 + 25.3 else 56 + fd2      | CASE WHEN _cond2_ THEN (_fd1_) + 25.3 ELSE 56 + (_fd2_) END AS calc4    |
      | calc5 if cond2 then fn1 / 25.3 else 56 + fd2      | CASE WHEN _cond2_ THEN lhs_fn1 / 25.3 ELSE 56 + (_fd2_) END AS calc5    |
      | calc6 fd1 compress | TRIM((_fd1_)) AS calc6 |

