import boto3
import StringIO
import json
import re

from nose.tools import assert_equals

class TestNarpFilePostProcessor:
    def __init__(self):
        self.lam = None

    def setup(self):
        self.lam = boto3.client('lambda')

    def json_file(self, line_delimiter='\n', field_delimiter='\t', target_file="out_file_1.txt.gz", source_field_delimiter):
        payload = {
                   "SourceFieldDelimiter": source_field_delimiter,
                   "LineDelimiter": line_delimiter,
                   "FieldDelimiter": field_delimiter,
                   "Bucket": 'narp-archive',
                   "Key": target_file
                  }
        return StringIO.StringIO( json.dumps(payload))

    def payload(self, resp):
        return json.loads( resp['Payload'].read() )


    def test_replace_tab_with_Z_field_delimiter(self):
        resp = self.lam.invoke( FunctionName='NarpFilePostProcessor', Payload=self.json_file() )
        assert_equals( resp['StatusCode'], 200 )
        assert_equals( self.payload(resp), 7)
