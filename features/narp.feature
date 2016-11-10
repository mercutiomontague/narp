@narp
Feature: Parse the definition of a an ETL program using the Narp Executable (narp.rb) 
  In order to allow users to specify an ETL program
  As a developer
  I should be able to run this scenario to prove that the defintion is correctly interpretted

  Scenario: Parse a definition to obtain the processing commands 
		Given that Narp is invoked with program_definition from app_spec_0
    # Then the stdout should match app_spec_0 

	@current
  Scenario: Parse a definition to obtain the processing commands 
		Given that Narp is invoked with program_definition from app_spec_5
    # Then the stdout should match app_spec_5 
    Then show stdout




