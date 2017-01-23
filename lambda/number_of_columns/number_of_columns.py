import boto3
import zlib

def get_file_chunk(dict):
  s3 = boto3.client('s3')
  chunk = s3.get_object( Bucket=dict['Bucket'], Key=dict['Key'], Range="bytes=0-" + '{}'.format(dict['RowSize']) )['Body'].read()
  dec = zlib.decompressobj(32 + zlib.MAX_WBITS)  # offset 32 to skip the header
  return dec.decompress( chunk )

# Make sure that the line delimiter is found within the chunk
def get_line(dict):
  chunk = get_file_chunk(dict)
  if len( chunk.split(dict['LineDelimiter']) ) == 1:
    return None
  else:
    return chunk.split(dict['LineDelimiter'])[0]


def number_of_columns(event, context):
  if 'RowSize' not in event: event['RowSize'] = 5000
  while True:
    event['RowSize'] *= 2
    if get_line(event) is not None:
      return len( get_line(event).split(event['FieldDelimiter']) )



event = {'LineDelimiter': "\n", 'FieldDelimiter': "\t", 'Bucket': 'narp-out-dev', 'Key': "Zions_11/./out_file_1/txt/out_file_1.txt.gz"}
print "number of columns is " + '{}'.format( number_of_columns(event, None) )
