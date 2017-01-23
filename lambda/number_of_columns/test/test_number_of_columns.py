import boto3
import StringIO
import json
import re

from nose.tools import assert_equals

class TestNumberOfColumns:
    def __init__(self):
        self.lam = None

    def setup(self):
        self.lam = boto3.client('lambda')


    def json_file(self, line_delimiter='\n', field_delimiter='\t', target_file="out_file_1.txt.gz"):
        payload = {
                   "LineDelimiter": line_delimiter,
                   "FieldDelimiter": field_delimiter,
                   "Bucket": 'narp-archive',
                   "Key": target_file
                  }
        return StringIO.StringIO( json.dumps(payload))

    def payload(self, resp):
        return json.loads( resp['Payload'].read() )

    def test_when_tab_field_delimiter(self):
        resp = self.lam.invoke( FunctionName='NumberOfColumns', Payload=self.json_file() )
        assert_equals( resp['StatusCode'], 200 )
        assert_equals( self.payload(resp), 7)

    def test_when_tab_field_and_cr_row_delimiter(self):
        resp = self.lam.invoke( FunctionName='NumberOfColumns', Payload=self.json_file("\r", "\t", "out_file_2_cr.txt.gz") )
        assert_equals( resp['StatusCode'], 200 )
        assert_equals( self.payload(resp), 4)

    def test_when_referencing_non_existent_file(self):
        resp = self.lam.invoke( FunctionName='NumberOfColumns', Payload=self.json_file("\r", "\t", "non_existent_file.txt.gz") )
        assert_equals( resp['StatusCode'], 200 )
        assert_equals( self.payload(resp)['errorMessage'], 'An error occurred (AccessDenied) when calling the GetObject operation: Access Denied')

    def test_when_using_delimiters_that_dont_exist_in_file(self):
        resp = self.lam.invoke( FunctionName='NumberOfColumns', Payload=self.json_file("\r\n", "\r\n", "out_file_1.txt.gz"))
        assert_equals( resp['StatusCode'], 200 )
        mess = self.payload(resp)['errorMessage']
        assert( re.search( 'Task timed out after 10.00 seconds', mess ) is not None )

