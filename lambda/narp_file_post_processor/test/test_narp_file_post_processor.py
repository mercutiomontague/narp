import boto3
import StringIO
import json
import re
import os
import subprocess
from subprocess import Popen
import re

from nose.tools import assert_equals

class TestNarpFilePostProcessor:
    def __init__(self):
        self.lam = None

    def setup(self):
        self.lam = boto3.client('lambda')

    def request(self, key, source_field_delimiter=None, line_delimiter='\n', field_delimiter='\t'):
        return {
         "SourceFieldDelimiter": source_field_delimiter or field_delimiter,
         "LineDelimiter": line_delimiter,
         "FieldDelimiter": field_delimiter,
         "Bucket": 'narp-archive',
         "Key": key
        }

    def payload(self, resp):
        return json.loads( resp['Payload'].read() )

    def json_file(self, request ):
        return StringIO.StringIO( json.dumps(request))

    def setup_data(self, req):
        s3 = boto3.client('s3')
        dest = 'test/{}'.format( req['Key'] )
        s3.copy_object( CopySource={'Bucket': req['Bucket'], 'Key':req['Key']}, Bucket=req['Bucket'], Key=dest)
        return dest

    def move_to_local(self, req):
        s3 = boto3.client('s3')
        dest = os.path.expanduser('~/tmp/{}'.format( os.path.basename( req['Key'] )))
        with open(dest, 'w' ) as outfile:
            outfile.write( s3.get_object( Bucket=req['Bucket'], Key=req['Key'] )['Body'].read() )
        s3.delete_object( Bucket=req['Bucket'], Key=req['Key'] )
        os.system('gunzip -f {}'.format( dest ) )
        return re.sub(".gz$", '',  dest)

    def run(self, req):
        dest = self.setup_data(req)
        req[ 'Key' ] = dest
        resp = self.lam.invoke( FunctionName='NarpFilePostProcessor', Payload=self.json_file( req ))
        resp[ 'dest' ] = self.move_to_local(req)
        return resp


	# grep -o -P '\t' out_file_1.txt | wc -l
    def number_of_tokens(self, resp, token):
        cmd = "grep -o -P '{}' {} | wc -l".format(token, resp['dest'])
        return int( Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE).communicate()[0].rstrip() )


    def test_replace_tab_with_Z_field_delimiter(self):
        resp = self.run( self.request( source_field_delimiter="\t", field_delimiter="Z", key='out_file_1.txt.gz' ) )
        assert_equals( resp['StatusCode'], 200 )
        assert( 'FunctionError' not in resp  )
        assert_equals( self.number_of_tokens( resp, 'Z'), 45198)

    def test_replace_newline_with_cr(self):
        resp = self.run( self.request( line_delimiter='\r', key='out_file_1.txt.gz' ) )
        assert_equals( resp['StatusCode'], 200 )
        assert( 'FunctionError' not in resp  )
        assert_equals( self.number_of_tokens( resp, '\t'), 45198)
        assert_equals( self.number_of_tokens( resp, 'Z'), 0)
        assert_equals( self.number_of_tokens( resp, '\r'), 7533)

    def test_replace_newline_with_cr_and_tab_with_Z_field_delimiter(self):
        resp = self.run( self.request( source_field_delimiter='\t', field_delimiter='Z', line_delimiter='\r', key='out_file_1.txt.gz' ) )
        assert_equals( resp['StatusCode'], 200 )
        assert( 'FunctionError' not in resp  )
        assert_equals( self.number_of_tokens( resp, '\t'), 0)
        assert_equals( self.number_of_tokens( resp, 'Z'), 45198)
        assert_equals( self.number_of_tokens( resp, '\r'), 7533)

    def test_non_existent_file(self):
        req = self.request( line_delimiter='\r', key='non_existent_file.txt.gz' )
        resp = self.lam.invoke( FunctionName='NarpFilePostProcessor', Payload=self.json_file( req ))
        assert_equals( resp['StatusCode'], 200 )
        assert( 'FunctionError' in resp  )
        assert_equals( self.payload(resp)['errorMessage'], "The target narp-archive/non_existent_file.txt.gz does not exist!")

