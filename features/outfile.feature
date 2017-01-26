@outfile
Feature: Parse the definition for an output file
  In order to allow users to specify an outfile file 
  As a developer
  I should be able to run this scenario to prove that the defintion is correctly interpretted

  Scenario: Providing a filename
    Given an input /outfile my_text_file
    When parsed by OutfileG
    Then I have a FileIdentifier
    And I have a Outfile at the root
    And the filename is my_text_file

  Scenario: Providing a filename with spaces
    Given an input /outfile 'my text file.txt'
    When parsed by OutfileG
    Then I have a FileIdentifier
    And the filename is 'my text file.txt'

  Scenario: Providing a filename, a sequential organization and compressed
    Given an input /outfile 'My text_file.txt' Sequential compressed
    When parsed by OutfileG
    Then I have an organization
    And the filename is 'My text_file.txt'
    And the organization is sequential
    And the compressed is normal 

  Scenario: Providing a filename, a sequential organization and highly compressed
    Given an input /outfile 'My text_file.txt' Sequential compressed highcompression
    When parsed by OutfileG
    Then I have an organization
    And the filename is 'My text_file.txt'
    And the organization is sequential
    And the compressed is high 

  Scenario: Providing a filename, a sequential organization and not compressed 
    Given an input /outfile 'My text_file.txt' Sequential uncompressed
    When parsed by OutfileG
    Then I have an organization
    And the filename is 'My text_file.txt'
    And the organization is sequential
    And the compressed is none 

  Scenario: Providing a filename, and a record length
    Given an input /outfile 'My text_file.txt' 249
    When parsed by OutfileG
    And the filename is 'My text_file.txt'
    And the record length is 0, 249 

  Scenario: Providing a filename, and a max and min record length
    Given an input /outfile 'My text_file.txt' 249 25
    When parsed by OutfileG
    Then the filename is 'My text_file.txt'
    And the record length is 25, 249

  @current
  Scenario Outline: Providing a filename, and a field seperator
		Given an existing app that is reinitialized 
    Given an input /outfile 'My text_file.txt' <seperator_keyword> <seperator>
    And the app parses /infile <infile1> number_of_columns 23
    And the app parses /infile <infile2> NUMBER_OF_COLUMNS 5
    When parsed by OutfileG
    Then the filename is 'My text_file.txt'
    And the field seperator is <sep_value> 

    Examples:
      | infile1   | infile2         | seperator_keyword | seperator | sep_value |
      | 'f1.txt'  | 'f2.txt' "z"    | FIELDSEPARATOR    | "\t"      | \t        |
      | 'f1.txt'  | 'f2.txt' "z"    |                   | ","       | ,         |
      | 'f1.txt'  | 'f2.txt' "z"    | FIELDSEPARATOR    | x"73"     | s         |
      | 'f1.txt' 	| 'f2.txt' "z"  |					|           | z         |
      | 'f1.txt' "y"	| 'f2.txt'  |					|           | y         |
      | 'f1.txt' 	| 'f2.txt'      |					|           | \t        |


##### The following scenarios are specific to outfile while those above can
##### can also be applied to outfile


  Scenario: Providing a filename, and an overwrite disposition 
    Given an input /outfile 'My text_file.txt' overwrite
    When parsed by OutfileG
    Then the filename is 'My text_file.txt'
    And the disposition is overwrite

  Scenario: Providing a filename, and an append disposition 
    Given an input /outfile 'My text_file.txt' APPEND 
    When parsed by OutfileG
    Then the filename is 'My text_file.txt'
    And the disposition is append 

  Scenario: Providing a filename, and record numbering 
    Given an input /outfile 'My text_file.txt' recordNumber start 39 
    When parsed by OutfileG
    Then the filename is 'My text_file.txt'
    And the record number starts at 39

  Scenario: Providing a filename, and record numbering 
    Given an input /outfile 'My text_file.txt' recordNumber 96 
    When parsed by OutfileG
    Then the filename is 'My text_file.txt'
    And the record number starts at 96 

	Scenario: Provding all of the options
    Given an input /outfile 'My text_file.txt' Sequential compressed 49 325 "\t" appeNd recordnumber 22
    When parsed by OutfileG
    Then I have a Outfile at the root
    And I have an organization
    And the filename is 'My text_file.txt'
    And the organization is sequential
    And the compressed is normal 
    And the record length is 49, 325
    And the field seperator is \t
    And the record number starts at 22 
    And the disposition is append 

