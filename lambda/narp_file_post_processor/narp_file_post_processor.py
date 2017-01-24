#! /usr/bin/env python
import boto3
import botocore
import zlib
import csv
import cStringIO

class S3MultipartUploader:

    minPartSize = 6000000
    def __init__(self, dict):
        self.s3 = boto3.client('s3')
        self.bucket = dict['Bucket']
        self.key =  dict['UploadKey']
        self.count = 0
        self.parts = []
        self.accum = b''
        self.upload_id = self.s3.create_multipart_upload( Bucket=self.bucket, Key=self.key)['UploadId']

    def  __enter__(self):
        return self

    def __del__(self):
        if len(self.accum) > 0: self.do_upload()
        part_info = {'Parts': self.parts}
        self.s3.complete_multipart_upload( Bucket=self.bucket, Key=self.key, UploadId=self.upload_id, MultipartUpload=part_info)

    def do_upload(self):
        self.count += 1
        resp = self.s3.upload_part( Bucket=self.bucket, Key=self.key, PartNumber=self.count, UploadId=self.upload_id, Body=self.accum )
        self.parts.append( {'PartNumber': self.count, 'ETag': resp['ETag']} )
        self.accum = b''


    def upload(self, txt):
        self.accum = b''.join([self.accum, txt])
        if len(self.accum) < S3MultipartUploader.minPartSize: return
        self.do_upload()

class S3ObjectUploader:
    def __init__(self, dict):
        self.s3 = boto3.client('s3')
        self.bucket = dict['Bucket']
        self.key =  dict['UploadKey']
        self.payload = b''

    def __del__(self):
        self.s3.put_object( Body=self.payload, Bucket=self.bucket, Key=self.key )

    # We need to accumulate the payload since Zlib produces a final piece with the call to zlib.flush()
    def upload(self, txt):
        self.payload = b''.join([self.payload, txt])


class FileSystemUploader:
    def __init__(self, dict):
        self.key = dict['UploadKey']
        self.out = open( self.key, 'wb')

    def __enter__(self):
        return self

    def __del__(self):
        self.out.close()

    def upload(self, txt):
        self.out.write(txt)


class NarpFilePostProcessor:
    """
    This lambda function impliments all of the post processinng to massaage a query output to the final desired format.
    """

    def __init__(self, event):
        self.s3 = boto3.client('s3')
        self.dec = zlib.decompressobj(32 + zlib.MAX_WBITS)  # offset 32 to skip the header
        self.comp = zlib.compressobj(zlib.Z_DEFAULT_COMPRESSION, zlib.DEFLATED, 28)
        self.bucket = event['Bucket']
        self.key = event['Key']
        self.source_field_delimiter = event['SourceFieldDelimiter'] if 'SourceFieldDelimiter' in event else None
        self.line_delimiter = event['LineDelimiter'] if 'LineDelimiter' in event else None
        self.field_delimiter = event['FieldDelimiter'] if 'FieldDelimiter' in event else None
        self.row_size = S3MultipartUploader.minPartSize * 2
        self.starting_byte = 0
        self.ending_byte = 0

        upload_key = self.key
        if self.object_size() >= self.row_size:
            self.loader = S3MultipartUploader( {'Bucket': self.bucket, 'UploadKey': upload_key} )
        else:
            self.loader = S3ObjectUploader( {'Bucket': self.bucket, 'UploadKey': upload_key} )

        self.process()

    def upload(self, txt):
        self.loader.upload(txt)

    def object_size(self):
        resp = self.s3.list_objects_v2( Bucket=self.bucket, Prefix=self.key )
        if resp['KeyCount'] == 0: raise Exception("The target {}/{} does not exist!".format( self.bucket, self.key ) ) 
        return resp['Contents'][0]['Size']


    def byte_range(self):
        return 'bytes={}-{}'.format(self.starting_byte, self.ending_byte)

    def get_file_chunk(self):
        print "byte_range is " + '{}'.format( self.byte_range() )
        chunk = self.s3.get_object( Bucket=self.bucket, Key=self.key, Range=self.byte_range() )['Body'].read()
        return self.dec.decompress( chunk )

    """
    Replace line and field delimiters
    """
    def do_replacements(self, text):
        return self.replace_field_delimiters( self.replace_line_delimiters(text) )

    def replace_line_delimiters(self, text):
        return text.replace("\n", self.line_delimiter) if self.line_delimiter else text

    def replace_field_delimiters(self, text):
        if self.field_delimiter is None or self.source_field_delimiter == self.field_delimiter: return text

        if self.source_field_delimiter == 'csv':
            csv_file = StringIO(text)
            reader = csv.reader(csv_file)
            return self.line_delimiter.join( [self.field_delimiter.join(row) for row in reader] )
        else:
            return text.replace(self.source_field_delimiter, self.field_delimiter) 


    def process(self):
        try:
            while True:
                self.ending_byte = self.ending_byte + self.row_size
                self.upload( self.comp.compress( self.do_replacements( self.get_file_chunk() )))
                self.starting_byte = self.ending_byte + 1
        except botocore.exceptions.ClientError as err:
            # This just means we are done
            pass
        finally:
            self.upload( self.comp.flush() )


def process(event, context):
    return NarpFilePostProcessor(event)



# event = {'LineDelimiter': "\r\n", 'FieldDelimiter': "\t", 'Bucket': 'narp-out-dev', 'Key': "Zions_11/big.txt.gz"}
# event = {'SourceFieldDelimiter': "\t", 'LineDelimiter': "\r", 'FieldDelimiter': "\Z", 'Bucket': 'narp-archive', 'Key': "out_file_2_cr.txt.gz"}
event = {'SourceFieldDelimiter': "\t", 'LineDelimiter': "\r", 'FieldDelimiter': "\Z", 'Bucket': 'narp-archive', 'Key': "test/out_file_1.txt.gz"}

NarpFilePostProcessor(event)
