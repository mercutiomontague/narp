@basic
Feature: Parse the definition basic elements of the Narp language
  In order to allow users to specify basic building elements
  As a developer
  I should be able to run this scenario to prove that the defintion is correctly interpretted

  @string
  Scenario Outline: Providing a string definition
    Given an input <input>
    When parsed by BasicG 
    Then I have a String at the root
    And the value is <value>

    Examples:
      | input               | value             |
      | 3"blue"           | blueblueblue      |
      | 'blue\tyellow'    | blue	yellow      |
      | 2'blue\tyellow'   | blue	yellowblue	yellow      |
      | x"73616D706C65"   | sample            |
      | "\x73amp\x6C\x65" | sample						|
      | 'blue'            | blue              |
      | 'blue #3'           | blue #3           |


  Scenario Outline: Providing a regular expression definition
    Given an input <input>
    When parsed by BasicG 
    Then I have a Regex at the root
    And the regexp should match <value> with a value of <match>
  
    Examples:
      | input               | value             | match     |
      | /\S+/               | blue              | b         |
      | /\l./               | blue              | lu        |
      | /[[:digit:]+]/      | go23bat           | 23        |
      | /87[[:alpha:]]{2}/  | shax 87code       | 87co      |
      | /\S+\t\S/            | love	it          | love	i   |

  
  @current
  Scenario Outline: Providing a numeric definition
    Given an input <input>
    When parsed by BasicG 
    Then I have a <class> at the root
    And the value is <value>
  
    Examples:
      | input   | class             | value    |
      | 23      | OrdinalLiteral    | 23         |
      | -23     | IntegerLiteral    | -23         |
      | 23.33   | FloatLiteral      | 23.33        |
      | 2,333   | EditedNumeric     | 2333        |
      | 8,333.3 | EditedNumeric     | 8333.3        |
    



  Scenario Outline: Providing an invalid regular expression definition should cause Parse Error
    Given an input <input>
    Then parsing by BasicG should raise ParseError 
  
    Examples:
      | input               | 
      | /blue               | 
      | /a(/              | 
