@infile
Feature: Parse the definition for an input file
  In order to allow users to specify an input file 
  As a developer
  I should be able to run this scenario to prove that the defintion is correctly interpretted

  Scenario: Providing a filename
    Given an input /infile my_text_file
    When parsed by InfileG 
    Then I have a FileIdentifier 
    And I have a Infile at the root
    And the filename is my_text_file

  Scenario: Providing a filename with spaces
    Given an input /infile 'my text file.txt'
    When parsed by InfileG
    Then I have a FileIdentifier
    And the filename is my text file.txt
    Given an input /infile 'short/path/to/My text file.txt'
    When parsed by InfileG
    And the filename is short/path/to/My text file.txt
		Given an existing app that is reinitialized with zions domain
    And an input /infile 'short/path/to/Your text file.txt'
    When parsed by InfileG

  Scenario Outline: Providing a filename, an organization and compression
    Given an input /infile 'path/to/inputfile/My text_file.txt' <organization> <compressed> 
    When parsed by InfileG
    Then I have an organization
    And the filename is path/to/inputfile/My text_file.txt
    And the organization is <organization>
    And the compressed is <compression>

    Examples:
      | organization            | compressed                  | compression   |
      | sequential              | compressed                  | normal        | 
      | indexed                 | compressed highcompression  | high          |
      | sequential              | uncompressed                | none          |


  Scenario Outline: Providing a filename, and a record length
    Given an input /infile 'My text_file.txt' <record_length> 
    When parsed by InfileG
    And the filename is My text_file.txt
    And the record length is <min_max>

    Examples:
      | record_length | min_max |
      | 249           | 0, 249  |
      | 315 25        | 25, 315 |


  Scenario Outline: Providing a filename, and a field seperator
    Given an input /infile 'My text_file.txt' <seperator>
    When parsed by InfileG
    Then the filename is My text_file.txt
    And the field seperator is <sep_value> 

    Examples:
      | seperator | sep_value |
      | FIELDSEPARATOR "\t"   | \t        |
      |                 ","   | ,         |
      | FIELDSEPARATOR x"73"  | s         |
      |  							       	| \t        |


##### The following scenarios are specific to infile while those above can
##### can also be applied to outfile

  Scenario: Providing a filename and an alias
    Given an input /infile my_text_file alias goo
    When parsed by InfileG
    Then I have an Alias 
    And the filename is my_text_file
    And the alias is goo

  Scenario: Providing a filename, an alias, and a sequential organization
    Given an input /infile 'My text_file.txt' alias moo Sequential
    When parsed by InfileG
    Then I have an organization
    And the filename is My text_file.txt
    And the alias is moo
    And the organization is sequential


  Scenario: Providing a filename and a recordlimit for skips
    Given an input /infile 'My text_file.txt' fskiprecord 23
    When parsed by InfileG
    Then I have a Infile at the root
    And the filename is My text_file.txt
    And skip to record 23  

  Scenario: Providing a filename, an alias, and a recordlimit for skips
    Given an input /infile 'My text_file.txt' alias moo fskipnumbeR 92
    When parsed by InfileG
    Then I have a Infile at the root
    And the filename is My text_file.txt
    And the alias is moo
    And skip to record 92 
  
  Scenario: Providing a filename, an alias, and a recordlimit for stop records
    Given an input /infile 'My text_file.txt' alias moo fskiprecord 15 fstopafter 87 
    When parsed by InfileG
    Then I have a Infile at the root
    And the filename is My text_file.txt
    And the alias is moo
    And skip to record 15 
    And stop after 87 records 

  Scenario: Providing the full set of options 
    Given an input /infile 'My text_file.txt' alias moo x"73"  Sequential compressed highcompression 349 15 	fskiprecord 15 fstopafter 87
    When parsed by InfileG 
    Then I have a Infile at the root
    And the filename is My text_file.txt
    And the field seperator is s
    And the alias is moo
    And the record length is 15, 349
    And the organization is sequential
    And the compressed is high 
    And skip to record 15 
    And stop after 87 records 

  Scenario: Providing the another set of options 
    Given an input /infile /etlsource/text_253_2016-09-23.txt STREAM CRLF "\t" 1500 
    When parsed by InfileG
    Then I have a Infile at the root
    And the filename is /etlsource/text_253_2016-09-23.txt
    And the field seperator is \t
    And the record delimiter is \r\n
    And the record data is stream
    And the record length is 0, 1500

  @current
  Scenario: Providing NUMBER_OF_COLUMNS option
    Given an input /infile /etlsource/text_253_2016-09-23.txt STREAM CRLF "\t" 1500 NUMBER_OF_COLUMNS 9
    When parsed by InfileG
    Then I have a Infile at the root
    And the filename is /etlsource/text_253_2016-09-23.txt
    And the field seperator is \t
    And the record delimiter is \r\n
    And the record data is stream
    And the record length is 0, 1500
    And the number of columns is 9
