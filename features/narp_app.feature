@narp_app
Feature: Parse the definition of a an ETL program using the Narp language
  In order to allow users to specify an ETL program
  As a developer
  I should be able to run this scenario to prove that the defintion is correctly interpretted


  Scenario Outline: Adding outfile objects to the app
		Given an existing app that is reinitialized 
		And the app has outfiles <initial_outfiles>
    And additional outfiles <additional_outfiles>
    Then I expect outfiles with these pieces <outfile_positions>

    Examples:
      | initial_outfiles  | additional_outfiles | outfile_positions |
      | f9,f8,f7          | f1,f2               | f9:1, f8:2, f7:3, f1:4, f2:5 |
      | f2,f8,f7          | []                  | f2:1, f8:2, f7:3 |


  Scenario Outline: Adding outfile and include objects to the app
		Given an existing app that is reinitialized 
		And the app has outfiles <initial_outfiles>
    And the app has includes <initial_includes>
    And additional outfiles <additional_outfiles>
    And additional includes <additional_includes>
    Then I expect outfiles with these pieces <outfile_positions>
    Then I expect includes with these pieces <include_positions>

    Examples:
      | initial_outfiles  | additional_outfiles | initial_includes | additional_includes | outfile_positions            | include_positions           | 
      | f9,f8,f7          | f1,f2               | i1,i3            | i9,i2               | f9:1, f8:2, f7:3, f1:6, f2:7 | i1:4, i3:5, i9:8, i2:9      |
      | f2,f8,f7          | []                  | i9,i2            | i3,i5               | f2:1, f8:2, f7:3             | i9:4, i2:5, i3:6, i5:7      |


  Scenario: Providing a complete application definition
		Given an existing app that is reinitialized 
    And the app parses /infile '/short/path/My text_file.txt' alias moo x"73"  Sequential compressed highcompression 349 15 	fskiprecord 15 fstopafter 87 
    And the app parses /infile 'Your text_file.txt' alias zoo fskiprecord 15 fstopafter 87 
    And the app parses /fields my_col 4:1 integer 
    And the app parses /fields col3 3:3 - 4:7 
    And the app parses /fields dateCol 5:1 datetime mm/yy-dd0 hh 
    And the app parses /condition cond11 5"blue" ct "green" oR my_col < 10
    And the app parses /condition cond2 col3 mt /yel/i
    And the app parses /reformat dateCol, rightside:my_col
    And the app parses /outfile 'Her text_file.txt' Sequential compressed
    And the app parses /joinkeys col3
    And the app parses /include cond11
    And the app parses /infile 'third_file.txt' alias foo fskiprecord 5 fstopafter 17 
    And the app parses /joinkeys my_col 
		And the app parses /join unpaired leftside
    And the app parses /outfile 'path/to/file/His text_file.txt' Sequential compressed highcompression 49 325 "\t" recordnumber 22
    And the app parses /include cond2
    Then the ddl should match app_spec_0 
     And the preprocess should match app_spec_0
     # And show the app hql
     And the hql should match app_spec_0
     And the postprocess should match app_spec_0

  Scenario: Parse a definition where all options/commands are on one line
		Given an existing app that is reinitialized 
    And the app parses /infile '/short/path/My text_file.txt' alias moo x"73"  Sequential compressed highcompression 349 15 	fskiprecord 15 fstopafter 87 /infile 'Your text_file.txt' alias zoo fskiprecord 15 fstopafter 87 /fields my_col 4:1 integer /fields col3 3:3 - 4:7 /fields dateCol 5:1 datetime mm/yy-dd0 hh /condition cond11 5"blue" ct "green" oR my_col < 10 /condition cond2 col3 mt /yel/i /reformat dateCol, rightside:my_col /outfile 'Her text_file.txt' Sequential compressed /joinkeys col3 /include cond11 /infile 'third_file.txt' alias foo fskiprecord 5 fstopafter 17 /joinkeys my_col /join unpaired leftside /outfile 'path/to/file/His text_file.txt' Sequential compressed highcompression 49 325 "\t" recordnumber 22 /include cond2
    Then the ddl should match app_spec_0 
     And the preprocess should match app_spec_0
     And the hql should match app_spec_0
     And the postprocess should match app_spec_0

  Scenario: Defining a 'splitter' app
   	Given an existing app that is reinitialized 
     And the app parses /infile 'My_text_file.txt' alias moo "\t"  Sequential compressed highcompression 349 15 	fskiprecord 15 fstopafter 87 
     And the app parses /infile 'Your_text_file.txt' alias zoo fstopafter 87 
     And the app parses /fields my_col 2:1 integer 
     And the app parses /fields col3 1:3 - 1:
     And the app parses /fields dateCol 3: - 4: datetime yy/mm  
     And the app parses /condition cond11 5"blue" ct "green" oR my_col < 10
     And the app parses /condition cond2 col3 mt /yEl?/i
     And the app parses /reformat dateCol, rightside:my_col, leftside:col3
     And the app parses /outfile 'Her_text_file.txt' Sequential compressed
     And the app parses /joinkeys col3
     And the app parses /include cond11
     And the app parses /infile 'third_file.txt' alias foo 
     And the app parses /joinkeys my_col 
   	 And the app parses /join unpaired leftside
     And the app parses /outfile 'Our_text_file.txt' Sequential compressed highcompression 49 325 "z" overwrite recordnumber 22
     And the app parses /include cond2
     Then the ddl should match app_spec_1 
      And the preprocess should match app_spec_1
      And the hql should match app_spec_1
      And the postprocess should match app_spec_1
  
  Scenario: Defining another 'splitter' app
  	Given an existing app that is reinitialized 
    And the app parses /infile /etlsource/text_zubuat_2016-09-23.txt STREAM CRLF "\t" 1500 
    And the app parses /collatingsequence DEFAULT ASCII
    And the app parses /fields form 2:19 - 2:27
    And the app parses /fields desc 7:1 - 7:8
    And the app parses /fields formz 6:1 - 6:6
    And the app parses /condition rec (desc != "blue cheese")
    And the app parses /condition hmda    (formz >= "889900" and formz <= "889999")
    And the app parses /condition leftover (form = "      ")
    And the app parses /outfile /etlsource/pika_form_2016-09-23.txt overwrite stream crlf
    And the app parses /include rec
    And the app parses /outfile /etlsource/chu_10_2016-09-23.txt overwrite stream crlf
    And the app parses /include hmda
    And the app parses /outfile /etlsource/rychu_2016-09-23.txt overwrite stream crlf
    And the app parses /include leftover
    Then the ddl should match app_spec_2 
    And the preprocess should match app_spec_2
    And the hql should match app_spec_2
    And the postprocess should match app_spec_2
  
  Scenario: Defining an app with derived fields and references
  	Given an existing app that is reinitialized 
    And the app parses /infile /etlsource/text_zubuat_2016-09-23.txt STREAM CRLF "\t" 1500 
    And the app parses /collatingsequence DEFAULT ASCII
    And the app parses /fields num 1:10 - 1:18 integer
    And the app parses /fields form 2:19 - 2:27
    And the app parses /fields desc 7:1 - 7:8
    And the app parses /fields formz 6:1 - 6:6
    And the app parses /derivedfield df1 num + 1
    And the app parses /derivedfield df2 df1 + 2
    And the app parses /derivedfield df3 df2 * 3
    And the app parses /derivedfield df4 df3 / 4
    And the app parses /derivedfield df5 df4 - 5
    And the app parses /condition rec (desc != "blue cheese")
    And the app parses /condition hmda    (formz >= "889900" and formz <= "889999")
    And the app parses /condition leftover (form = "      ")
    And the app parses /outfile /etlsource/pika_form_2016-09-23.txt overwrite stream crlf
    And the app parses /include rec
    And the app parses /outfile /etlsource/chu_10_2016-09-23.txt overwrite stream crlf
    And the app parses /include hmda
    And the app parses /outfile /etlsource/rychu_2016-09-23.txt overwrite stream crlf
    And the app parses /include leftover
    Then the ddl should match app_spec_3 
    And the preprocess should match app_spec_3
    And the hql should match app_spec_3
    And the postprocess should match app_spec_3
  
  Scenario: Defining an app with derived fields and references
  	Given an existing app that is reinitialized with zions domain
    And the app parses /infile /etlsource/text_zubuat_2016-09-23.txt STREAM CRLF "\t" 1500 
    And the app parses /collatingsequence DEFAULT ASCII
    And the app parses /fields num 1:10 - 1:18 integer
    And the app parses /fields form 2:19 - 2:27
    And the app parses /fields desc 7:1 - 7:8
    And the app parses /fields formz 6:1 - 6:6
    And the app parses /derivedfield df1 num + 1
    And the app parses /derivedfield df2 df1 + 2
    And the app parses /derivedfield df3 df2 * 3
    And the app parses /derivedfield df4 df3 / 4
    And the app parses /derivedfield df5 df4 - 5
    And the app parses /condition rec (desc != "blue cheese")
    And the app parses /condition hmda    (formz >= "889900" and formz <= "889999")
    And the app parses /condition leftover (form = "      ")
    And the app parses /outfile /etlsource/out/pika_form_2016-09-23.txt overwrite stream crlf
    And the app parses /reformat num, form, df1, df5
    And the app parses /include rec
    And the app parses /outfile /etlsource/out/chu_10_2016-09-23.txt overwrite stream crlf
    And the app parses /reformat num, form, df1, df5
    And the app parses /include hmda
    And the app parses /outfile /etlsource/out/rychu_2016-09-23.txt overwrite stream crlf
    And the app parses /reformat num, form, df4
    And the app parses /include leftover
    Then the ddl should match app_spec_4 
    And the preprocess should match app_spec_4
    And the hql should match app_spec_4
    And the postprocess should match app_spec_4
  
  Scenario: Parse a definition to obtain the processing commands 
  	Given an existing app that is reinitialized 
    And the app parses /domain zions /infile /etl/dev/source/text_253/ref/data__2016-11-03.txt STREAM CRLF "\t" /copy
    And the app parses /collatingsequence DEFAULT ASCII
    And the app parses /fields cus 3:1 - 3:7
    And the app parses /condition header  (cus = "0000019")
    And the app parses /condition billing (cus != "0000019")
    And the app parses /condition remaining (cus = "       ")
    And the app parses /outfile /etl/dev/source/text_253/ref/data_head__2016-11-03.txt overwrite stream crlf
    And the app parses /include header
    And the app parses /outfile /etl/dev/source/text_253/ref/data_bill__2016-11-03.txt overwrite stream crlf
    And the app parses /include billing
    And the app parses /outfile /etl/dev/source/text_253/ref/data_remain__2016-11-03.txt overwrite stream crlf
    And the app parses /include remaining
    Then the ddl should match app_spec_5 
    And the preprocess should match app_spec_5
    And the hql should match app_spec_5
    And the postprocess should match app_spec_5
		

  Scenario: Parse a definition to obtain the processing commands 
		Given that Narp is invoked with program_definition from app_spec_0
    Then the stdout should match app_spec_0 

	@current
  Scenario: Parse a definition to obtain the processing commands 
		Given that Narp is invoked with program_definition from app_spec_5
    Then the stdout should match app_spec_5 

